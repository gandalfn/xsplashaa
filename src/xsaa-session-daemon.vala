/* xsaa-session-daemon.vala
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
    open_session_with_parameters (ConsoleKit.SessionParameter[] inParameters) throws DBus.Error; 

    public abstract bool
    close_session(string inCookie) throws DBus.Error;

    public abstract DBus.ObjectPath?
    get_session_for_cookie(string inCookie) throws DBus.Error;

    public abstract void
    restart() throws DBus.Error;

    public abstract void
    stop() throws DBus.Error;
}

namespace XSAA
{
    static MainLoop sLoop;

    [DBus (name = "fr.supersonicimagine.XSAA.Manager")]
    public class SessionManager : GLib.Object
    {
        // properties
        private DBus.Connection    m_Connection;
        private ConsoleKit.Manager m_Manager;
        private Users              m_Users;

        public GLib.HashTable <string, Session> m_Sessions;

        // methods
        public SessionManager(DBus.Connection inConn, dynamic DBus.Object inBus)
        {
            m_Connection = inConn;

            m_Manager = (ConsoleKit.Manager)m_Connection.get_object ("org.freedesktop.ConsoleKit", 
                                                                     "/org/freedesktop/ConsoleKit/Manager",
                                                                     "/org/freedesktop/ConsoleKit/Manager");

            m_Sessions = new GLib.HashTable <string, Session> (GLib.str_hash, GLib.str_equal);
            inBus.NameOwnerChanged.connect (on_client_lost);

            m_Users = new Users (m_Connection);
        }

        private void 
        on_client_lost (DBus.Object inSender, string iName, string inPrev, string inNewp) 
        {
            m_Sessions.remove (inPrev);
        }

        public bool
        open_session(string inUser, int inDisplay, string inDevice, bool inFaceAuthentication, bool inAutologin, out DBus.ObjectPath? outPath)
        {
            outPath = new DBus.ObjectPath ("/fr/supersonicimagine/XSAA/Manager/Session/" +
                                           inUser + "/" + inDisplay.to_string());
            try
            {
                string service = "xsplashaa";
                if (inFaceAuthentication) service = "xsplashaa-face-authentication";
                if (inAutologin) service = "xsplashaa-autologin";

                var session = new Session(m_Connection, m_Manager, service, inUser, inDisplay, inDevice);
                GLib.message ("open session %s", outPath);
                m_Connection.register_object(outPath, session);
                m_Sessions.insert (outPath, session);
            }
            catch (GLib.Error err)
            {
                GLib.critical ("error on create session : %s", err.message);
                return false;
            }

            return true;
        }

        public void
        close_session(DBus.ObjectPath? inPath)
        {
            GLib.debug ("close session %s", inPath);
            m_Sessions.remove(inPath);
        }

        public void
        reboot()
        {
            GLib.debug ("reboot");
            try
            {
                m_Manager.restart();
            }
            catch (DBus.Error err)
            {
                GLib.critical ("error on ask reboot %s", err.message);
            }
        }

        public void
        halt()
        {
            GLib.debug ("halt");
            try
            {
                m_Manager.stop();
            }
            catch (DBus.Error err)
            {
                GLib.critical ("error on ask halt %s", err.message);
            }
        }

        public int
        get_nb_users ()
        {
            return m_Users.nb_users;
        }
    }

    const GLib.OptionEntry[] c_OptionEntries = 
    {
        { "no-daemonize", 'd', 0, GLib.OptionArg.NONE, ref s_NoDaemon, "Do not run xsplashaa-session-daemon as a daemonn", null },
        { null }
    };

    static bool s_NoDaemon = false;

    static int
    main (string[] inArgs) 
    {
        GLib.Log.set_default_handler (Log.syslog_log_handler);

        GLib.debug ("start");

        try
        {
            var opt_context = new OptionContext("- Xsplashaa session daemon");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(c_OptionEntries, "xsplasaa-session-daemon");
            opt_context.parse(ref inArgs);
        }
        catch (GLib.OptionError err) 
        {
            GLib.critical ("option parsing failed: %s", err.message);
            return -1;
        }

        if (!s_NoDaemon)
        {
            if (Os.daemon (0, 0) < 0)
            {
                GLib.critical ("error on launch has daemon");
                return -1;
            }
        }

        try
        {
            sLoop = new GLib.MainLoop(null, false);

            var conn = DBus.Bus.get (DBus.BusType.SYSTEM);

            dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                                       "/org/freedesktop/DBus",
                                                       "org.freedesktop.DBus");

            uint r1 = bus.request_name ("fr.supersonicimagine.XSAA.Manager.Session", (uint) 0);
            uint r2 = bus.request_name ("fr.supersonicimagine.XSAA.Manager.User", (uint) 0);
            uint r3 = bus.request_name ("fr.supersonicimagine.XSAA.Manager", (uint) 0);

            if (r1 == DBus.RequestNameReply.PRIMARY_OWNER &&
                r2 == DBus.RequestNameReply.PRIMARY_OWNER &&
                r3 == DBus.RequestNameReply.PRIMARY_OWNER) 
            {
                var service = new SessionManager (conn, bus);

                conn.register_object ("/fr/supersonicimagine/XSAA/Manager", 
                                      service);

                sLoop.run();
            }
        }
        catch (GLib.Error err)
        {
            GLib.critical ("%s", err.message);
            return -1;
        }

        GLib.debug ("end");

        return 0;
    }
}
