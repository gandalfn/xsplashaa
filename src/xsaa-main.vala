/* xsaa-main.vala
 *
 * Copyright (C) 2009-2010  Nicolas Bruguier
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

[DBus (name = "fr.supersonicimagine.XSAA.Manager")] 
public interface XSAA.Manager : DBus.Object 
{
    public abstract bool open_session (string user, int display, string device, bool autologin, out DBus.ObjectPath? path) throws DBus.Error; 
    public abstract void close_session(DBus.ObjectPath path) throws DBus.Error;
    public abstract void reboot() throws DBus.Error;
    public abstract void halt() throws DBus.Error;
}

[DBus (name = "fr.supersonicimagine.XSAA.Manager.Session")] 
public interface XSAA.Session : DBus.Object 
{ 
    public signal void died();
    public signal void exited();

    public signal void authenticated ();
    public signal void info (string msg);
    public signal void error_msg (string msg);

    public abstract void set_passwd(string pass) throws DBus.Error;
    public abstract void authenticate() throws DBus.Error;
    public abstract void launch(string cmd) throws DBus.Error;
}

namespace XSAA
{
    const string SOCKET_NAME = "/tmp/xsplashaa-socket";
    const string SHUTDOWN_FILENAME = "/tmp/xsplashaa-shutdown";
    static Daemon? daemon = null;
    static bool shutdown = false;

    errordomain DaemonError
    {
        DISABLED
    }

    public class Daemon : GLib.Object
    {
        bool enable = true;
        bool first_start = true;
        bool test_only = false;

        public string[] args;

        Server socket;
        Splash splash;
        Display display;
        DBus.Connection conn = null;
        XSAA.Manager manager = null;

        string server = "/usr/bin/Xorg";
        int number = 0;
        string device = "/dev/tty1";
        string options = "";
        string user = null;
        string pass = null;
        string exec = null;

        DBus.ObjectPath path = null;
        XSAA.Session session = null;

        public Posix.jmp_buf env;

        public Daemon(string socket_name, bool test_only = false) throws GLib.Error
        {
            load_config();

            this.test_only = test_only;

            if (!enable)
                throw new DaemonError.DISABLED("Use gdm instead xsplashaa");

            string cmd = server + " :" + number.to_string() + " " + options;
            try
            {
                if (!test_only)
                {
                    display = new Display(cmd, number);
                    display.ready.connect(on_display_ready);
                    display.died.connect(on_display_exit);
                    display.exited.connect(on_display_exit);
                }

                socket = new Server(socket_name);
                socket.dbus.connect(on_dbus_ready);
                socket.session.connect(on_session_ready);
                socket.close_session.connect(on_init_shutdown);
                socket.quit.connect(on_quit);
            }
            catch (GLib.Error err)
            {
                this.unref();
                throw err;
            }
        }

        private void
        load_config()
        {
            if (FileUtils.test(Config.PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile();
                    config.load_from_file(Config.PACKAGE_CONFIG_FILE, KeyFileFlags.NONE);
                    enable = config.get_boolean("general", "enable");
                    server = config.get_string("display", "server");
                    number = config.get_integer("display", "number");
                    options = config.get_string("display", "options");
                    exec = config.get_string("session", "exec");
                    user = config.get_string("session", "user");
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on read %s: %s", Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
        }

        ~Daemon()
        {
            if (manager != null && path != null)
            {
                manager.close_session(path);
                session = null;
            }
            if (display != null)
            {
                display.kill ();
            }
            manager = null;
            display = null;
            GLib.stderr.printf ("Destroy xsplashaa daemon\n");
        }

        private void
        change_to_display_vt()
        {
            int vt;
            
            device.scanf("/dev/tty%i", out vt);
            change_vt(vt);
        }

        private void
        on_display_ready()
        {
            if (!test_only) 
            {
                Posix.putenv("DISPLAY=:" + number.to_string());

                Gtk.init_check(ref args);
                var display = Gdk.Display.open(":" + number.to_string());
                var manager = Gdk.DisplayManager.get();
                manager.set_default_display(display);
                X.set_io_error_handler(on_display_io_error);
            }
            else
            {
                Gtk.init(ref args);
            }

            splash = new Splash(socket);
            splash.login.connect(on_login_response);
            splash.restart.connect(on_restart_request);
            splash.shutdown.connect(on_shutdown_request);
            splash.show();
            shutdown |= GLib.FileUtils.test(SHUTDOWN_FILENAME, GLib.FileTest.EXISTS);
            if (shutdown) 
                on_init_shutdown();
            else if (!first_start) 
                on_dbus_ready();
        }

        private void
        on_session_ready()
        {
            if (session != null) splash.hide();
        }

        private bool
        open_session(string username, bool autologin)
        {
            bool ret = false;

            try
            {
                if (conn == null)
                {
                    conn = DBus.Bus.get (DBus.BusType.SYSTEM);
                }

                if (manager == null)
                {
                    manager = (XSAA.Manager)conn.get_object ("fr.supersonicimagine.XSAA.Manager", 
                                                             "/fr/supersonicimagine/XSAA/Manager",
                                                             "/fr/supersonicimagine/XSAA/Manager");
                }
                if (session == null)
                {
                    GLib.stderr.printf("Open session\n");
                    if (manager.open_session (username, number, device, autologin, out path))
                    {
                        session = (XSAA.Session) conn.get_object ("fr.supersonicimagine.XSAA.Manager.Session",
                                                                  path,
                                                                  "fr.supersonicimagine.XSAA.Manager.Session");
                        session.died.connect(on_session_ended);
                        session.exited.connect(on_session_ended);
                        session.info.connect(on_session_info);
                        session.error_msg.connect(on_error_msg);
                        ret = true;
                    }
                    else
                        GLib.stderr.printf("Error on open session");
                }
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on launch session: %s\n", err.message);
            }

            return ret;
        }

        private void
        start_session ()
        {
            if (user == null || user.length == 0)
            {
                GLib.stderr.printf ("Ask for login\n");
                splash.ask_for_login();
            }
            else
            {
                GLib.stderr.printf ("Open session for use %s\n", user);
                open_session(user, true);

                try
                {
                    session.authenticate();
                    session.authenticated.connect(on_authenticated);
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on session authenticate: %s\n", err.message);
                }
            }
        }

        private void
        on_dbus_ready()
        {
            int fd = Posix.open("/var/log/xsplashaa.log", Posix.O_TRUNC | Posix.O_CREAT | Posix.O_WRONLY, 0644);

            Posix.dup2 (fd, 1);
            Posix.dup2 (fd, 2);
            Posix.close (fd);
            GLib.stderr.printf ("Open display device\n");
            device = display.get_device();
            GLib.stderr.printf ("Start session\n");

            start_session();
        }

        private void
        on_session_ended()
        {
            GLib.stderr.printf("Session end\n");
            if (manager != null && path != null)
            {
                try
                {
                    manager.close_session(path);
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on close session: %s\n", err.message);
                }
            }
            session = null;
            splash.show();
            splash.ask_for_login();
        }

        private void
        on_init_shutdown()
        {
            GLib.stderr.printf("Init shutdown\n");
            change_to_display_vt();
            if (manager != null && path != null && session != null)
            {
                try
                {
                    manager.close_session(path);
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on close session: %s\n", err.message);
                }
                session = null;
            }
            manager = null;
            conn = null;
            if (!shutdown && Posix.setjmp(env) == 0)
            {
                try
                {
                    IOChannel file = new IOChannel.file(SHUTDOWN_FILENAME, "w");
                    file.set_close_on_unref(true);
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on create: %s\n", SHUTDOWN_FILENAME);
                }  
                shutdown = true;
            }
            splash.show();
            splash.show_shutdown();
        }

        private void
        on_restart_request()
        {
            try
            {
                manager.reboot();
                manager = null;
                conn = null;
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on launch shutdown: %s\n", err.message);
            }
            splash.show_shutdown();
        }

        private void
        on_shutdown_request()
        {
            try
            {
                manager.halt();
                manager = null;
                conn = null;
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on launch shutdown: %s\n", err.message);
            }
            splash.show_shutdown();
        }

        private void
        on_display_exit()
        {
            Gtk.main_quit();
            Posix.exit(-1);
        }

        private void
        on_quit()
        {
            Gtk.main_quit();
            GLib.stderr.printf ("Quit requested\n");
        }

        private void
        on_session_info(string msg)
        {
            GLib.stderr.printf("Info %s\n", msg);
            if (session != null)
            {
                try
                {
                    manager.close_session(path);
                }
                catch (DBus.Error err)
                {
                    GLib.stderr.printf("%s\n", err.message);
                }
                session = null;
            }
            user = null;
            pass = null;
            splash.login_message(msg);
            splash.ask_for_login();
        }

        private void
        on_error_msg(string msg)
        {
            GLib.stderr.printf("Error msg %s\n", msg);
            if (session != null)
            {
                try
                {
                    manager.close_session(path);
                }
                catch (DBus.Error err)
                {
                    GLib.stderr.printf("%s\n", err.message);
                }
                session = null;
            }
            user = null;
            pass = null;
            try
            {
                manager.close_session(path);
            }
            catch (DBus.Error err)
            {
                GLib.stderr.printf("%s\n", err.message);
            }
            session = null;
            splash.login_message(msg);
            splash.ask_for_login();
        }

        private void
        on_authenticated()
        {
            try
            {
                session.launch(exec);
                splash.show_launch();
            }
            catch (DBus.Error err)
            {
                GLib.stderr.printf("%s\n", err.message);
            }
        }

        private void
        on_login_response(string username, string passwd)
        {
            GLib.stderr.printf("Open session for %s\n", username);
            if (open_session(username, false))
            {
                GLib.stderr.printf("Open session for %s\n", username);
                user = username;
                pass = passwd;
                try
                {            
                    session.set_passwd(pass);
                    session.authenticate();
                    session.authenticated.connect(on_authenticated);
                }
                catch (DBus.Error err)
                {
                    GLib.stderr.printf("%s\n", err.message);
                }
            }
            else
            {
                user = null;
                pass = null;
                splash.ask_for_login();
            }
        }

        public void
        run(bool first_start)
        {
            if (test_only) on_display_ready();
            this.first_start = first_start;
            Gtk.main ();
        }
    }

    static void
    change_vt(int vt)
    {
        int fd, rc;
        
        fd = Posix.open ("/dev/tty" + vt.to_string(), Posix.O_WRONLY | Posix.O_NOCTTY, 0);
        if (fd > 0)
        {
            rc = Posix.ioctl (fd, Posix.VT_ACTIVATE, vt);
            rc = Posix.ioctl (fd, Posix.VT_WAITACTIVE, vt);

            Posix.close(fd);
        }
    }

    static int
    on_display_io_error(X.Display display)
    {
        GLib.stderr.printf("DISPLAY Error\n");
        daemon = null;
        return -1;
    } 

    static void
    on_sig_term(int signum)
    {
        if (shutdown && daemon != null)
            Posix.longjmp(daemon.env, 1);
        else
            Posix.exit (-1);
    }

    const OptionEntry[] option_entries = 
    {
        { "test-only", 't', 0, OptionArg.NONE, ref test_only, "Test only", null },
        { "no-daemonize", 'd', 0, OptionArg.NONE, ref no_daemon, "Do not run xsplashaa as a daemonn", null },
        { null }
    };

    static bool test_only = false;
    static bool no_daemon = false;

    static int 
    main (string[] args) 
    {
        try 
        {
            OptionContext opt_context = new OptionContext("- Xsplashaa");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(option_entries, "xsplashaa");
            opt_context.parse(ref args);
        } 
        catch (OptionError err) 
        {
            GLib.stderr.printf("Option parsing failed: %s\n", err.message);
            return -1;
        }

        if (test_only)
        {
            try
            {
                daemon = new Daemon (SOCKET_NAME, test_only);
                daemon.args = args;
                daemon.run(true);
                daemon = null;
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("%s\n", err.message);
                daemon = null;
                return -1;
            }
        }
        else
        {
            if (!no_daemon)
            {
                if (Posix.daemon (0, 0) < 0)
                {
                    GLib.stderr.printf("Error on launch has daemon\n");
                    return -1;
                }
            }

            int fd = Posix.open("/tmp/xsplashaa.log", Posix.O_TRUNC | Posix.O_CREAT | Posix.O_WRONLY, 0644);

            Posix.dup2 (fd, 1);
            Posix.dup2 (fd, 2);
            Posix.close (fd);

            Posix.pid_t pid;
            Posix.pid_t ppgid;

            pid = Posix.getpid();
            ppgid = Posix.getpgid(pid);
            Posix.setsid();
            Posix.setpgid(0, ppgid);

            Posix.signal(Posix.SIGTERM, Posix.SIG_IGN);
            Posix.signal(Posix.SIGKILL, Posix.SIG_IGN);
            int status = -1;
            bool first_start = true;
            int nb_start = 0;
            while (status != 0 && nb_start < 5)
            {
                int ret_fork = Posix.fork();

                if (ret_fork == 0)
                {
                    try
                    {
                        Posix.signal(Posix.SIGSEGV, on_sig_term);
                        Posix.signal(Posix.SIGTERM, on_sig_term);
                        Posix.signal(Posix.SIGKILL, on_sig_term);
                        daemon = new Daemon (SOCKET_NAME);
                        daemon.args = args;
                        daemon.run(first_start);
                        daemon = null;
                    }
                    catch (GLib.Error err)
                    {
                        GLib.stderr.printf("%s\n", err.message);
                        daemon = null;
                        return -1;
                    }

                    return 0;
                }
                else if (ret_fork == -1)
                {
                    return -1;
                }
                else
                {
                    int ret;
                    first_start = false;
                    nb_start++;
                    Posix.wait(out ret);
                    status = Process.exit_status(ret);
                    GLib.stderr.printf ("Child daemon exited with status %i\n", status);
                }
            }
        }

        return 0;
     }
}
