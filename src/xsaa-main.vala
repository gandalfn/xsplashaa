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

[DBus (name = "fr.supersonicimagine.XSAA.Manager")] 
public interface XSAA.Manager : DBus.Object 
{ 
    public abstract bool open_session (string user, int display, string device, bool autologin, out DBus.ObjectPath? path); 
    public abstract void close_session(DBus.ObjectPath path);
    public abstract void reboot();
    public abstract void halt();
}
    
[DBus (name = "fr.supersonicimagine.XSAA.Manager.Session")] 
public interface XSAA.Session : DBus.Object 
{ 
    public signal void died();
    public signal void exited();

    public signal void authenticated ();
    public signal void info (string msg);
    public signal void error_msg (string msg);

    public abstract void set_passwd(string pass);
    public abstract void authenticate();
    public abstract void launch(string cmd);
}

namespace XSAA
{
    const string SOCKET_NAME = "/tmp/xsplashaa-socket";

    errordomain DaemonError
    {
        DISABLED
    }
    
    public class Daemon : GLib.Object
    {
        bool enable = true;
	    bool first_start = true;
        
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
        
        public Daemon(string socket_name) throws GLib.Error
        {
            load_config();

            if (!enable)
                throw new DaemonError.DISABLED("Use gdm instead xsplashaa");
            
            string cmd = server + " :" + number.to_string() + " " + options;
            try
            {
                display = new Display(cmd, number);
                display.ready += on_display_ready;
                display.died += on_display_exit;
                display.exited += on_display_exit;
                
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
                    stderr.printf("Error on read %s: %s", 
                                  PACKAGE_CONFIG_FILE, err.message);
                }
            }
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
            putenv("DISPLAY=:" + number.to_string());

            Gtk.init_check(ref args);			
            var display = Gdk.Display.open(":" + number.to_string());
            var manager = Gdk.DisplayManager.get();
            manager.set_default_display(display);
            splash = new Splash(socket);
            splash.login += on_login_response;
            splash.restart += on_restart_request;
            splash.shutdown += on_shutdown_request;
            splash.show();
	        if (!first_start) on_dbus_ready();
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
                    stderr.printf("Open session\n");
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
                        stderr.printf("Error on open session");
                }
            }
            catch (GLib.Error err)
            {
                stderr.printf("Error on launch session: %s\n", err.message);
            }       

            return ret;
        }
                       
        private void
        on_dbus_ready()
        {
            device = display.get_device();
            
            if (user == null || user.len() == 0)
            {
                splash.ask_for_login();
            }
            else
            {
                open_session(user, true);
                
                session.authenticate();
                session.authenticated += on_authenticated;
            }
        }

        private void
        on_session_ended()
        {
            stderr.printf("Session end\n");
            manager.close_session(path);
            session = null;
            splash.show();
            splash.ask_for_login();
        }

        private void
        on_init_shutdown()
        {
            stderr.printf("Init shutdown\n");
            change_to_display_vt();
            if (session != null)
            {
                manager.close_session(path);
                session = null;
            }
            manager = null;
            conn = null;
            splash.show();   
            splash.show_shutdown();
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
                stderr.printf("Error on launch shutdown: %s\n", err.message);
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
                stderr.printf("Error on launch shutdown: %s\n", err.message);
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
            stderr.printf("Info %s\n", msg);
            if (session != null)
            {
                manager.close_session(path);
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
            stderr.printf("Error msg %s\n", msg);
            if (session != null)
            {
                manager.close_session(path);
                session = null;
            }
            user = null;
            pass = null;
            manager.close_session(path);
            session = null;
            splash.login_message(msg);
            splash.ask_for_login();
        }

        private void
        on_authenticated()
        {
            session.launch(exec);
            splash.show_launch();
        }
        
        private void
        on_login_response(string username, string passwd)
        {
            stderr.printf("Open session for %s\n", username);
            if (open_session(username, false))
            {
                stderr.printf("Open session for %s\n", username);
                user = username;
                pass = passwd;
                session.set_passwd(pass);
                session.authenticate();
                session.authenticated += on_authenticated;
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
        
    static void
    on_sig_kill(int signum)
    {
        change_vt(8);
    }
    
    static int 
    main (string[] args) 
    {
        pid_t pid;
	    pid_t ppgid;
	    
	    pid = getpid();
	    ppgid = getpgid(pid);
	    setsid();
    	setpgid(0, ppgid);

        signal(SIGTERM,on_sig_kill);
        signal(SIGKILL,on_sig_kill);
        int status = -1;
        bool first_start = true;
        while (status != 0)
        {
            switch (fork())
            {
                case 0:
                    try 
                    {
                        signal(SIGTERM,on_sig_kill);
                        signal(SIGKILL,on_sig_kill);
	                    Daemon daemon = new Daemon (SOCKET_NAME);
	                    daemon.args = args;                    
                        daemon.run(first_start);
	                    daemon.unref();
                    }
                    catch (GLib.Error err)
                    {
                        stderr.printf("%s\n", err.message);
                        return -1;
                    }
                
	                return 0;
                 case -1:
                    return -1;
                 default:
                    int ret;
                    first_start = false;
                    wait(out ret);
		    if (Process.if_signaled(ret))
		    {
			if (Process.core_dump(ret))
		            status = -1;
			else
			    status = 0;
		    }
		    else
                    	status = Process.exit_status(ret);
                    break;
            }
        }
        
        return 0;
     }
}
