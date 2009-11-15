/* xsaa-session-daemon.vala
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
using Vala;
using Posix;

public const string PACKAGE_XAUTH_DIR = "/tmp/xsplashaa-xauth";

[DBus (name = "org.freedesktop.ConsoleKit.Session")] 
public interface ConsoleKit.Session : DBus.Object 
{
    public abstract void activate() throws DBus.Error;
}

[DBus (name = "org.freedesktop.ConsoleKit.Manager")] 
public interface ConsoleKit.Manager : DBus.Object 
{ 
    public abstract string 
    open_session_with_parameters (ConsoleKit.SessionParameter[] parameters) throws DBus.Error; 

    public abstract int
    close_session(string cookie) throws DBus.Error;

    public abstract DBus.ObjectPath?
    get_session_for_cookie(string cookie) throws DBus.Error;
    
    public abstract void
    restart() throws DBus.Error;

    public abstract void
    stop() throws DBus.Error;
}

[DBus (name = "org.gnome.SettingsDaemon")] 
public interface SettingsDaemon.Manager : DBus.Object 
{
}

namespace XSAA
{
    static MainLoop loop;

    [DBus (name = "fr.supersonicimagine.XSAA.Manager")]
    public class SessionManager : GLib.Object
    {
        private DBus.Connection connection;
        public Map <string, Session> sessions;
        private ConsoleKit.Manager manager;
        
        public SessionManager(DBus.Connection conn, dynamic DBus.Object bus)
        {
            connection = conn;

            manager = (ConsoleKit.Manager)conn.get_object ("org.freedesktop.ConsoleKit", 
                                                           "/org/freedesktop/ConsoleKit/Manager",
                                                           "/org/freedesktop/ConsoleKit/Manager");

            sessions = new HashMap <string, Session> (GLib.str_hash, GLib.str_equal);
            bus.NameOwnerChanged += on_client_lost;
        }

        private void 
        on_client_lost (DBus.Object sender, string name, string prev, string newp) 
        {
            GLib.stderr.printf("Lost session %s\n", name);
            sessions.remove (prev);
        }
        
        public bool
        open_session(string user, int display, string device, bool autologin, out DBus.ObjectPath? path)
        {
            path =  new DBus.ObjectPath ("/fr/supersonicimagine/XSAA/Manager/Session/" +
                                         user + "/" + display.to_string());
            try
            {
                string service = "xsplashaa";
                if (autologin) service = "xsplashaa-autologin";
                    
                var session = new Session(connection, manager, service, user, display, device);
                GLib.stderr.printf("Open session %s\n", path);
                connection.register_object(path, session);
                sessions.set(path, session);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on create session : %s", err.message);
                return false;
            }

            return true;
        }

        public void
        close_session(DBus.ObjectPath? path)
        {
            GLib.stderr.printf("Close session %s\n", path);
            sessions.remove(path);
        }

        public void
        reboot()
        {
            try
            {
                manager.restart();
            }
            catch (DBus.Error err)
            {
                GLib.stderr.printf("Error on ask reboot %s\n", err.message);
            }
        }

        public void
        halt()
        {
            try
            {
                manager.stop();
            }
            catch (DBus.Error err)
            {
                GLib.stderr.printf("Error on ask halt %s\n", err.message);
            }
        }
    }

    const OptionEntry[] option_entries = 
    {
        { "no-daemonize", 'd', 0, OptionArg.NONE, ref no_daemon, "Do not run xsplashaa-session-daemon as a daemonn", null },
        { null }
    };

    static bool no_daemon = false;
    
    static int 
    main (string[] args) 
    {
        try 
        {
            var opt_context = new OptionContext("- Xsplashaa session daemon");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(option_entries, "xsplasaa-session-daemon");
            opt_context.parse(ref args);
        } 
        catch (OptionError err) 
        {
            GLib.stderr.printf("Option parsing failed: %s\n", err.message);
            return -1;
        }

        if (!no_daemon) 
        {
            if (Posix.daemon (0, 0) < 0)
            {
                GLib.stderr.printf("Error on launch has daemon\n");
                return -1;
            }
        }
        
		try 
        {
            loop = new MainLoop(null, false);
            
            var conn = DBus.Bus.get (DBus.BusType.SYSTEM);
            
		    dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                                       "/org/freedesktop/DBus",
                                                       "org.freedesktop.DBus");

            uint r1 = bus.request_name ("fr.supersonicimagine.XSAA.Manager.Session", (uint) 0);
            uint r2 = bus.request_name ("fr.supersonicimagine.XSAA.Manager", (uint) 0);

            if (r1 == DBus.RequestNameReply.PRIMARY_OWNER &&
                r2 == DBus.RequestNameReply.PRIMARY_OWNER) 
            {
                var service = new SessionManager (conn, bus);

                conn.register_object ("/fr/supersonicimagine/XSAA/Manager", 
                                      service);

                loop.run();
            }
        }
        catch (GLib.Error err)
        {
            message("%s\n", err.message);
            return -1;
        }
        
		return 0;
	}
}
