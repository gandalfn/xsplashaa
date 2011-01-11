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
    public abstract bool open_session (string user, int display, string device,
                                       bool face_authentication, bool autologin, out DBus.ObjectPath? path) throws DBus.Error; 
    public abstract void close_session(DBus.ObjectPath path) throws DBus.Error;
    public abstract void reboot() throws DBus.Error;
    public abstract void halt() throws DBus.Error;
    public abstract int get_nb_users () throws DBus.Error;
}

[DBus (name = "fr.supersonicimagine.XSAA.Manager.Session")] 
public interface XSAA.Session : DBus.Object 
{ 
    public signal void died();
    public signal void exited();

    public signal void ask_passwd ();
    public signal void ask_face_authentication ();
    public signal void authenticated ();
    public signal void info (string msg);
    public signal void error_msg (string msg);

    public abstract void set_passwd(string pass) throws DBus.Error;
    public abstract void authenticate() throws DBus.Error;
    public abstract void launch(string cmd) throws DBus.Error;
}

[DBus (name = "fr.supersonicimagine.XSAA.Manager.User")] 
public interface XSAA.User : DBus.Object 
{
    public abstract string login          { owned get; }
    public abstract string real_name      { owned get; }
    public abstract uint frequency        { get; }
    public abstract int face_icon_shm_id  { get; }
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
            GLib.debug ("Start daemon on %s in test only %s", socket_name, test_only.to_string ());
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

        public Daemon.xnest (string socket_name) throws GLib.Error
        {
            GLib.debug ("Start daemon xnest on %s in test only %s", socket_name, test_only.to_string ());

            load_config();

            if (!enable)
                throw new DaemonError.DISABLED("Use gdm instead xsplashaa");

            server = "/usr/bin/Xnest";
            number = 11;
            options = "";

            string cmd = server + " :" + number.to_string() + " " + options;
            try
            {
                display = new Display(cmd, number);
                display.ready.connect(on_display_ready);
                display.died.connect(on_display_exit);
                display.exited.connect(on_display_exit);

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
            GLib.debug ("load config %s", Config.PACKAGE_CONFIG_FILE);

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
                    GLib.warning ("error on read %s: %s", Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
            else
            {
                GLib.warning ("unable to found %s config file", Config.PACKAGE_CONFIG_FILE);
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
            GLib.debug ("destroy xsplashaa daemon");
        }

        private void
        change_to_display_vt()
        {
            GLib.debug ("change to display vt: %s", device);

            int vt;

            device.scanf("/dev/tty%i", out vt);
            change_vt(vt);
        }

        private void
        on_display_ready()
        {
            GLib.debug ("display ready");

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
            splash.passwd.connect(on_passwd_response);
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
            GLib.debug ("session ready");

            if (session != null) splash.hide();
        }

        private bool
        open_session(string username, bool face_authentication, bool autologin)
        {
            GLib.debug ("open session for %s", username);

            bool ret = false;

            try
            {
                if (session == null)
                {
                    GLib.message ("open session for %s: number=%i device=%s autologin=%s",
                                  username, number, device, autologin.to_string ());
                    if (manager.open_session (username, number, device, face_authentication, autologin, out path))
                    {
                        session = (XSAA.Session) conn.get_object ("fr.supersonicimagine.XSAA.Manager.Session",
                                                                  path,
                                                                  "fr.supersonicimagine.XSAA.Manager.Session");
                        if (session != null)
                        {
                            session.died.connect(on_session_ended);
                            session.exited.connect(on_session_ended);
                            session.info.connect(on_session_info);
                            session.error_msg.connect(on_error_msg);
                            ret = true;
                        }
                        else
                            GLib.warning ("error on open session");
                    }
                    else
                        GLib.warning ("error on open session");
                }
            }
            catch (GLib.Error err)
            {
                GLib.critical ("error on launch session: %s", err.message);
            }

            return ret;
        }

        private void
        start_session ()
        {
            if (user == null || user.length == 0)
            {
                GLib.debug ("ask for login");
                int nb_user = -1;
                try
                {
                    nb_user = manager.get_nb_users ();
                }
                catch (DBus.Error err)
                {
                    GLib.warning ("error on get nb users: %s", err.message);
                }

                splash.ask_for_login(nb_user);
            }
            else
            {
                GLib.message ("start session for user %s", user);
                if (open_session(user, false, true))
                {
                    try
                    {
                        session.authenticate();
                        session.authenticated.connect(on_authenticated);
                    }
                    catch (GLib.Error err)
                    {
                        GLib.warning ("error on session authenticate: %s", err.message);
                    }
                }
                else
                    GLib.warning ("Error on open session");
            }
        }

        private void
        on_dbus_ready()
        {
            GLib.debug ("dbus ready");

            device = display.get_device();
            if (device == null)
                device = "/dev/tty1";

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
                if (manager == null)
                {
                    GLib.warning ("Error on get manager object");
                }
            }
            catch (GLib.Error err)
            {
                GLib.warning ("Error on connect to dbus system: %s", err.message);
            }

            start_session();
        }

        private void
        on_session_ended()
        {
            GLib.debug ("session ended");
            if (manager != null && path != null)
            {
                try
                {
                    manager.close_session(path);
                }
                catch (GLib.Error err)
                {
                    warning ("error on close session: %s", err.message);
                }
            }
            session = null;
            splash.show();
            splash.map ();
            splash.window.focus (Gdk.CURRENT_TIME);
            Gdk.Display.get_default ().flush ();
            splash.ask_for_login();
        }

        private void
        on_init_shutdown()
        {
            GLib.debug ("init shutdown");
            change_to_display_vt();
            if (manager != null && path != null && session != null)
            {
                try
                {
                    manager.close_session(path);
                }
                catch (GLib.Error err)
                {
                    GLib.warning ("error on close session: %s", err.message);
                }
                session = null;
            }
            manager = null;
            conn = null;
            if (!shutdown && Posix.setjmp(env) == 0)
            {
                try
                {
                    GLib.debug ("create shutdown file: %s", SHUTDOWN_FILENAME);
                    IOChannel file = new IOChannel.file(SHUTDOWN_FILENAME, "w");
                    file.set_close_on_unref(true);
                }
                catch (GLib.Error err)
                {
                    GLib.warning ("error on create: %s", SHUTDOWN_FILENAME);
                }  
                shutdown = true;
            }
            splash.show();
            splash.map ();
            splash.window.focus (Gdk.CURRENT_TIME);
            Gdk.Display.get_default ().flush ();
            splash.show_shutdown();
        }

        private void
        on_restart_request()
        {
            GLib.debug ("restart request");

            try
            {
                manager.reboot();
                manager = null;
                conn = null;
            }
            catch (GLib.Error err)
            {
                GLib.critical ("error on launch restart: %s", err.message);
            }
            splash.show_shutdown();
        }

        private void
        on_shutdown_request()
        {
            GLib.debug ("shutdown request");

            try
            {
                manager.halt();
                manager = null;
                conn = null;
            }
            catch (GLib.Error err)
            {
                GLib.critical ("error on launch shutdown: %s", err.message);
            }
            splash.show_shutdown();
        }

        private void
        on_display_exit()
        {
            GLib.debug ("display exit");

            Gtk.main_quit();
            Posix.exit(-1);
        }

        private void
        on_quit()
        {
            GLib.debug ("quit requested");

            Gtk.main_quit();
        }

        private void
        on_session_info(string msg)
        {
            GLib.debug ("session info: %s", msg);
            splash.login_message(msg);
        }

        private void
        on_error_msg(string msg)
        {
            GLib.debug ("session error: %s", msg);

            user = null;
            pass = null;

            if (session != null)
            {
                try
                {
                    GLib.message ("close session: %s", path);

                    manager.close_session(path);
                }
                catch (DBus.Error err)
                {
                    GLib.critical ("error on close session: %s", err.message);
                }
                session = null;
            }

            splash.login_message(msg);
            splash.ask_for_login();
        }

        private void
        on_authenticated()
        {
            GLib.debug ("user authenticated");

            try
            {
                GLib.message ("launch %s", exec);
                session.launch(exec);
                splash.show_launch();
            }
            catch (DBus.Error err)
            {
                GLib.critical ("error on launch session: %s", err.message);
            }
        }

        private void
        on_ask_passwd ()
        {
            GLib.debug ("Ask password");
            splash.ask_for_passwd ();
        }

        private void
        on_ask_face_authentication ()
        {
            GLib.debug ("Ask face authentication");
            splash.ask_for_face_authentication ();
        }

        private void
        on_login_response(string username, bool face_authentication)
        {
            GLib.debug ("login response for %s", username);

            if (open_session(username, face_authentication, false))
            {
                GLib.message ("open session for %s", username);

                user = username;
                try
                {
                    session.authenticate();
                    session.authenticated.connect(on_authenticated);
                    session.ask_passwd.connect(on_ask_passwd);
                    session.ask_face_authentication.connect (on_ask_face_authentication);
                }
                catch (DBus.Error err)
                {
                    GLib.critical ("error on open session: %s", err.message);
                }
            }
            else
            {
                user = null;
                pass = null;
                splash.ask_for_login();
            }
        }

        private void
        on_passwd_response(string passwd)
        {
            GLib.debug ("passwd response");
            try
            {
                session.set_passwd(passwd);
            }
            catch (DBus.Error err)
            {
                GLib.warning ("Error on set passwd: %s", err.message);
            }
        }

        public void
        run(bool first_start)
        {
            GLib.debug ("run first_start = %s", first_start.to_string ());

            if (test_only) on_display_ready();
            this.first_start = first_start;
            Gtk.main ();
        }
    }

    static void
    change_vt(int vt)
    {
        GLib.debug ("change vt to %i", vt);
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
        GLib.critical ("DISPLAY error !!");
        daemon = null;
        return -1;
    } 

    static void
    on_sig_term(int signum)
    {
        GLib.message ("received signal %i", signum);

        if (shutdown && daemon != null)
            Posix.longjmp(daemon.env, 1);
        else
            Posix.exit (-1);
    }

    const OptionEntry[] option_entries = 
    {
        { "test-only", 't', 0, OptionArg.NONE, ref test_only, "Test only", null },
        { "xnest", 'x', 0, OptionArg.NONE, ref xnest, "Xnest", null },
        { "no-daemonize", 'd', 0, OptionArg.NONE, ref no_daemon, "Do not run xsplashaa as a daemonn", null },
        { null }
    };

    static bool test_only = false;
    static bool no_daemon = false;
    static bool xnest     = false;

    static int 
    main (string[] args) 
    {
        GLib.Log.set_default_handler (Log.kmsg_log_handler);

        GLib.debug ("starting");

        try 
        {
            OptionContext opt_context = new OptionContext("- Xsplashaa");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(option_entries, "xsplashaa");
            opt_context.parse(ref args);
        } 
        catch (OptionError err) 
        {
            GLib.critical ("option parsing failed: %s", err.message);
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
                GLib.critical ("%s", err.message);
                daemon = null;
                return -1;
            }
        }
        else if (xnest)
        {
            try
            {
                Posix.signal(Posix.SIGSEGV, on_sig_term);
                daemon = new Daemon.xnest (SOCKET_NAME);
                daemon.args = args;
                daemon.run(true);
                daemon = null;
            }
            catch (GLib.Error err)
            {
                GLib.critical ("%s", err.message);
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
                    GLib.critical ("error on launch has daemon");
                    return -1;
                }
            }

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
                    Posix.nice (-10);
                    try
                    {
                        GLib.message ("starting child deamon");
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
                        GLib.critical ("error on starting child daemon: %s", err.message);
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
                    GLib.message ("child daemon exited with status %i", status);
                }
            }
        }

        GLib.debug ("end");

        return 0;
     }
}
