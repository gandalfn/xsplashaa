/* session-daemon.vala
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

namespace XSAA
{
    static MainLoop sLoop;

    /**
     * Session manager class
     */
    [DBus (name = "fr.supersonicimagine.XSAA.Manager")]
    public class SessionManager : GLib.Object
    {
        // properties
        private DBus.Connection                m_Connection;
        private FreeDesktop.ConsoleKit.Manager m_Manager;
        private Users                          m_Users;

        public GLib.HashTable <string, Session> m_Sessions;

        // methods
        /**
         * Create a new session manager
         *
         * @param inConn dbus connection
         * @param inBus dbus bus
         */
        public SessionManager(DBus.Connection inConn, FreeDesktop.DBusObject inBus)
        {
            m_Connection = inConn;

            m_Manager = (FreeDesktop.ConsoleKit.Manager)m_Connection.get_object ("org.freedesktop.ConsoleKit",
                                                                                 "/org/freedesktop/ConsoleKit/Manager",
                                                                                 "/org/freedesktop/ConsoleKit/Manager");

            m_Sessions = new GLib.HashTable <string, Session> (GLib.str_hash, GLib.str_equal);
            inBus.name_owner_changed.connect (on_client_lost);

            m_Users = new Users (m_Connection);
        }

        private void
        on_client_lost (FreeDesktop.DBusObject inSender, string iName, string inPrev, string inNewp)
        {
            m_Sessions.remove (inPrev);
        }

        /**
         * Open a session for a user
         *
         * @param inUser login of user
         * @param inDisplay display number where to open session
         * @param inFaceAuthentication use face authentification for ask password
         * @param inAutologin use autologin
         * @param outPath the dbus object path of session object
         *
         * @return ``true`` on success
         */
        public bool
        open_session(string inUser, int inDisplay, string inDevice, bool inFaceAuthentication, bool inAutologin, out DBus.ObjectPath? outPath)
        {
            // Create user session dbus object path
            outPath = new DBus.ObjectPath ("/fr/supersonicimagine/XSAA/Manager/Session/" + inUser + "/" + inDisplay.to_string());
            try
            {
                // Create session for user
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

        /**
         * Close session
         *
         * @param inPath dbus object path of session
         */
        public void
        close_session(DBus.ObjectPath? inPath)
        {
            GLib.debug ("close session %s", inPath);
            m_Sessions.remove(inPath);
        }

        /**
         * Launch reboot of system
         */
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

        /**
         * Launch system halt
         */
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

        /**
         * Get the number of users than can be create for them
         */
        public int
        get_nb_users ()
        {
            return m_Users.nb_users;
        }

        /**
         * Show shutdown splash
         */
        public void
        show_splash_shutdown ()
        {
            try
            {
                XSAA.Client client = new XSAA.Client (Config.PACKAGE_CHROOT_DIR);
                client.send (new Message.close_session ());
            }
            catch (GLib.Error err)
            {
                Log.error ("Error on send shutdow to splash");
            }
        }

        /**
         * Show login splash
         */
        public void
        show_splash_login ()
        {
            try
            {
                XSAA.Client client = new XSAA.Client (Config.PACKAGE_CHROOT_DIR);
                client.send (new Message.dbus ());
            }
            catch (GLib.Error err)
            {
                Log.error ("Error on send dbus to splash");
            }
        }

        /**
         * Hide splash
         */
        public void
        hide_splash ()
        {
            try
            {
                XSAA.Client client = new XSAA.Client (Config.PACKAGE_CHROOT_DIR);
                client.send (new Message.session ());
            }
            catch (GLib.Error err)
            {
                Log.error ("Error on send session to splash");
            }
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
        XSAA.Log.set_default_logger (new XSAA.Log.Syslog (XSAA.Log.Level.DEBUG, "xsaa-session-daemon"));

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

            FreeDesktop.DBusObject bus = (FreeDesktop.DBusObject)conn.get_object ("org.freedesktop.DBus",
                                                                                  "/org/freedesktop/DBus",
                                                                                  "org.freedesktop.DBus");

            uint r = bus.request_name ("fr.supersonicimagine.XSAA.Manager", (uint) 0);

            if (r == DBus.RequestNameReply.PRIMARY_OWNER)
            {
                var service = new SessionManager (conn, bus);

                conn.register_object ("/fr/supersonicimagine/XSAA/Manager", service);

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
