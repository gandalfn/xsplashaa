/* xsaa-main.vala
 *
 * Copyright (C) 2009  Nicolas Bruguier
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

using GLib;
using Gtk;
using Posix;
using Config;
using Hal;

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
        bool have_keyboard = false;

        uint id_idle = 0;
        
	    public string[] args;
        
        Server socket;
        Splash splash;
        Display display;
        DBus.Connection conn = null;
        dynamic DBus.Object bus = null;
        Hal.Context hal = null;
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

        public jmp_buf env;
        
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
                    display.ready += on_display_ready;
                    display.died += on_display_exit;
                    display.exited += on_display_exit;
                }
                
                socket = new Server(socket_name);
                socket.dbus += on_dbus_ready;
                socket.session += on_session_ready;
                socket.close_session += on_init_shutdown;
                socket.quit += on_quit;
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
            if (FileUtils.test(PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile();
                    config.load_from_file(PACKAGE_CONFIG_FILE, 
                                          KeyFileFlags.NONE);
                    enable = config.get_boolean("general", "enable");
                    server = config.get_string("display", "server");
                    number = config.get_integer("display", "number");
                    options = config.get_string("display", "options");
                    exec = config.get_string("session", "exec");
                    user = config.get_string("session", "user");
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on read %s: %s", 
                                       PACKAGE_CONFIG_FILE, err.message);
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

            manager = null;
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
                putenv("DISPLAY=:" + number.to_string());

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
            splash.login += on_login_response;
            splash.restart += on_restart_request;
            splash.shutdown += on_shutdown_request;
            splash.show();
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
                        session.died += on_session_ended;
                        session.exited += on_session_ended;
                        session.info += on_session_info;
                        session.error_msg += on_error_msg;
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

        private static void
        on_device_added(Hal.Context ctx, string udi)
        {
            DBus.RawError err = DBus.RawError();
            
            string driver = ctx.device_get_property_string(udi, "input.x11_driver", ref err);

            if (driver != null)
            {
                var self = (Daemon)ctx.get_user_data();
                string layout = ctx.device_get_property_string(udi, "input.xkb.layout", ref err);
                if (layout != null && !self.have_keyboard) 
                {
                    self.have_keyboard = true;
                    self.start_session();
                }  
            }
        }

        private void
        start_session ()
        {
            if (user == null || user.len() == 0)
            {
                splash.ask_for_login();
            }
            else
            {
                open_session(user, true);

                try
                {
                    session.authenticate();
                    session.authenticated += on_authenticated;
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on session authenticate: %s\n", err.message);
                }
            }
        }

        private void
        activate_hal()
        {
            if (hal == null)
            {
                if (id_idle > 0) 
                {
                    Source.remove(id_idle);
                    id_idle = 0;
                }

                GLib.stderr.printf("Found hal daemon\n");
                
                hal = new Hal.Context();
                if (!hal.set_dbus_connection(conn.get_connection()))
                {
                    GLib.stderr.printf("Error on init hal\n");
                }                
                hal.set_user_data(this);
                hal.set_device_added(on_device_added);

                DBus.RawError err = DBus.RawError();
                string[] devices = hal.find_device_by_capability("input", ref err);
                if (!err.is_set())
                {
                    foreach (string dev in devices)
                    {
                        on_device_added(hal, dev);
                    }
                }
                else
                {
                    GLib.stderr.printf("Error on get devices list %s\n", err.message);
                }
            }
        }

        private void 
        on_list_names_reply (string[] names, GLib.Error error) 
        {
            foreach (string name in names) 
            {
                if (name == "org.freedesktop.Hal") 
                {
                    activate_hal();
                    break;
                }
            }
        }
        
        private bool 
        on_idle_ready () 
        {
            if (id_idle == 0) return true;

            try 
            {
                bus.list_names (on_list_names_reply);
            } 
            catch (GLib.Error e) 
            {
                GLib.stderr.printf ("Can't list: %s\n", e.message);
            }

            return false;
        }

        private void 
        on_name_owner_changed (DBus.Object sender, string name, string old_owner, string new_owner) 
        {
            if (name == "org.freedesktop.Hal" && new_owner != "" && old_owner == "")
            {
                activate_hal ();
            }
        }
        
        private void
        on_dbus_ready()
        {
            device = display.get_device();

            try
            {
                if (conn == null)
                {
                    conn = DBus.Bus.get (DBus.BusType.SYSTEM);
                    bus = conn.get_object ("org.freedesktop.DBus",
                                           "/org/freedesktop/DBus",
                                           "org.freedesktop.DBus");
                    bus.NameOwnerChanged += on_name_owner_changed;
                    id_idle = Idle.add(on_idle_ready);
                }
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on get dbus connection\n");
            }          
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
            splash.show();   
            splash.show_shutdown();
            if (!shutdown && setjmp(env) == 0)
               shutdown = true; 
        }

        private void
        on_restart_request()
        {
            try
            {
                Process.spawn_command_line_async("shutdown -r now");
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
                Process.spawn_command_line_async("shutdown -h now");
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
            exit(-1);
        }

        private void
        on_quit()
        {
            Gtk.main_quit();
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
                    session.authenticated += on_authenticated;
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
        
        fd = open ("/dev/tty" + vt.to_string(), O_WRONLY | O_NOCTTY, 0);
        if (fd > 0)
        {
            rc = ioctl (fd, VT_ACTIVATE, vt);
            rc = ioctl (fd, VT_WAITACTIVE, vt);

            close(fd);
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
            longjmp(daemon.env, 1);
        else
            exit (-1);
    }
    
    const OptionEntry[] option_entries = 
    {
        { "test-only", 't', 0, OptionArg.NONE, ref test_only, "Test only", null },
        { null }
    };

    static bool test_only = false;
    
    static int 
    main (string[] args) 
    {
        try 
        {
            var opt_context = new OptionContext("- Xsplashaa");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(option_entries, "xsplasaa");
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
            pid_t pid;
            pid_t ppgid;

            pid = getpid();
            ppgid = getpgid(pid);
            setsid();
            setpgid(0, ppgid);

            signal(SIGTERM, SIG_IGN);
            signal(SIGKILL, SIG_IGN);
            int status = -1;
            bool first_start = true;
            while (status != 0)
            {
                int ret_fork = fork();

                if (ret_fork == 0)
                {
                    try 
                    {
                        signal(SIGSEGV, on_sig_term);
                        signal(SIGTERM, on_sig_term);
                        signal(SIGKILL, on_sig_term);
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
                    wait(out ret);
                    status = Process.exit_status(ret);
                }
            }
        }
        
        return 0;
     }
}
