/* main.vala
 *
 * Copyright (C) 2009-2011  Nicolas Bruguier
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

namespace XSAA
{
    // constants
    const string SOCKET_NAME = "/tmp/xsplashaa-socket";
    const string SHUTDOWN_FILENAME = "/tmp/xsplashaa-shutdown";

    // static properties
    static Daemon? s_Daemon = null;
    static bool s_Shutdown = false;

    public errordomain DaemonError
    {
        DISABLED
    }

    public enum CheckFlags
    {
        NONE        = 0,
        PERIPHERALS = 1 << 0,
        TOUCHSCREEN = 1 << 1,
        PANEL       = 1 << 2,
        SSIDAB      = 1 << 3,

        ALL         = (1 << 4) - 1
    }

    public class Daemon : GLib.Object
    {
        // properties
        private bool m_Enable       = true;
        private bool m_FirstStart   = true;
        private bool m_TestOnly     = false;

        private Server          m_Socket;
        private Splash          m_Splash;
        private Display         m_Display;
        private DBus.Connection m_Connection = null;
        private Manager         m_Manager = null;
        private Input.Event     m_Event = null;

        private uint                  m_RebootRequestId = 0;
        private uint                  m_ShutdownRequestId = 0;

        private bool                  m_PendingError = false;
        private GLib.IOChannel        m_Client = null;

        private CheckFlags            m_Check = CheckFlags.ALL;
        private StateCheckPeripherals m_CheckPeripherals = null;
        private int                   m_NumStep = 0;
        private EventBoot.Status      m_CheckPeripheralsStatus = EventBoot.Status.FINISHED;

        private string  m_Server = "/usr/bin/Xorg";
        private int     m_Number = 0;
        private string  m_Device = "/dev/tty1";
        private string  m_Options = "";
        private string  m_User = null;
        private string  m_Pass = null;
        private string  m_Exec = null;

        private DBus.ObjectPath m_Path = null;
        private XSAA.Session    m_Session = null;

        public unowned string[] m_Args;

        public Os.jmp_buf       m_Env;

        // methods
        public Daemon(string inSocketName, bool inTestOnly = false) throws GLib.Error
        {
            Log.debug ("Start daemon on %s in test only %s", inSocketName, inTestOnly.to_string ());
            load_config ();

            m_TestOnly = inTestOnly;

            if (!m_Enable)
                throw new DaemonError.DISABLED ("Use gdm instead xsplashaa");

            string cmd = m_Server + " :" + m_Number.to_string () + " " + m_Options;
            try
            {
                if (!m_TestOnly)
                {
                    m_Display = new Display (cmd, m_Number);
                    m_Display.ready.connect (on_display_ready);
                    m_Display.died.connect (on_display_exit);
                    m_Display.exited.connect (on_display_exit);
                }

                m_Socket = new Server (inSocketName);
                m_Socket.dbus.connect (on_dbus_ready);
                m_Socket.session.connect (on_session_ready);
                m_Socket.close_session.connect (on_init_shutdown);
                m_Socket.quit.connect (on_quit);
                m_Socket.fatal_error.connect (on_fatal_error);
                m_Socket.question.connect (on_question);

                Input.EventWatch watchs[2];
                watchs[0] = Input.EventWatch.POWER_BUTTON;
                watchs[1] = Input.EventWatch.F12_BUTTON;
                m_Event = new Input.Event (watchs);
                m_Event.event.connect (on_input_event);
            }
            catch (GLib.Error err)
            {
                this.unref ();
                throw err;
            }
        }

        public Daemon.xnest (string inSocketName, bool inTestOnly = false) throws GLib.Error
        {
            Log.debug ("Start daemon xnest on %s in test only %s", inSocketName, inTestOnly.to_string ());

            load_config();

            m_TestOnly = inTestOnly;

            if (!m_Enable)
                throw new DaemonError.DISABLED ("Use gdm instead xsplashaa");

            m_Server = "/usr/bin/Xnest";
            m_Number = 11;
            m_Options = "";

            string cmd = m_Server + " :" + m_Number.to_string () + " " + m_Options;
            try
            {
                m_Display = new Display (cmd, m_Number);
                m_Display.ready.connect (on_display_ready);
                m_Display.died.connect (on_display_exit);
                m_Display.exited.connect (on_display_exit);

                m_Socket = new Server (inSocketName);
                m_Socket.dbus.connect (on_dbus_ready);
                m_Socket.session.connect (on_session_ready);
                m_Socket.close_session.connect (on_init_shutdown);
                m_Socket.quit.connect (on_quit);
                m_Socket.fatal_error.connect (on_fatal_error);
                m_Socket.question.connect (on_question);

                Input.EventWatch watchs[2];
                watchs[0] = Input.EventWatch.POWER_BUTTON;
                watchs[1] = Input.EventWatch.F12_BUTTON;
                m_Event = new Input.Event (watchs);
                m_Event.event.connect (on_input_event);
            }
            catch (GLib.Error err)
            {
                this.unref();
                throw err;
            }
        }

        ~Daemon ()
        {
            if (m_Manager != null && m_Path != null)
            {
                m_Manager.close_session (m_Path);
                m_Session = null;
            }
            if (m_Display != null)
            {
                m_Display.kill ();
            }
            m_Manager = null;
            m_Display = null;
            Log.debug ("destroy xsplashaa daemon");
        }

        private void
        load_config ()
        {
            Log.debug ("load config %s", Config.PACKAGE_CONFIG_FILE);

            if (FileUtils.test (Config.PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile ();
                    config.load_from_file (Config.PACKAGE_CONFIG_FILE, KeyFileFlags.NONE);
                    m_Enable = config.get_boolean ("general", "enable");
                    m_Check = (CheckFlags)config.get_integer ("general", "check");
                    m_Server = config.get_string ("display", "server");
                    m_Number = config.get_integer ("display", "number");
                    m_Options = config.get_string ("display", "options");
                    m_Exec = config.get_string ("session", "exec");
                    m_User = config.get_string ("session", "user");
                }
                catch (GLib.Error err)
                {
                    Log.warning ("error on read %s: %s", Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
            else
            {
                Log.warning ("unable to find %s config file", Config.PACKAGE_CONFIG_FILE);
            }
        }

        private void
        on_input_event (Input.EventWatch inWatch, uint inValue)
        {
            switch (inWatch)
            {
                case Input.EventWatch.POWER_BUTTON:
                    if (inValue == 1)
                    {
                        if (m_Client != null)
                        {
                            Message message = new Message.response (false);
                            if (Os.write(m_Client.unix_get_fd(), message.raw, message.raw.length + 1) == 0)
                                Log.critical ("error on send pong");
                            m_Splash.error ("");
                            m_Client = null;
                        }

                        if (m_Session == null)
                        {
                            on_shutdown_request ();
                        }
                    }
                    break;

                case Input.EventWatch.F12_BUTTON:
                    if (inValue == 1)
                    {
                        if (m_PendingError)
                        {
                            m_PendingError = false;
                            m_CheckPeripherals.resume_after_error ();
                        }
                        else if (m_Client != null)
                        {
                            Message message = new Message.response (true);
                            if (Os.write(m_Client.unix_get_fd(), message.raw, message.raw.length + 1) == 0)
                                Log.critical ("error on send pong");
                            m_Splash.error ("");
                            m_Client = null;
                        }
                    }
                    break;
            }
        }

        private void
        on_check_peripherals_message (string inMessage)
        {
            m_Splash.message (inMessage);
        }

        private void
        on_check_peripherals_progress (int inVal)
        {
            m_Splash.progress (inVal);
        }

        private void
        on_check_peripherals_step ()
        {
            if (m_CheckPeripherals.current == typeof (StateServiceCheck))
            {
                m_Splash.message ("Checking service devices...");
            }
            else if (m_CheckPeripherals.current == typeof (StateCheckTouchscreen))
            {
                m_Splash.message ("Checking touchscreen...");
            }
            else if (m_CheckPeripherals.current == typeof (StateConfigureTouchscreen))
            {
                m_Splash.message ("Configure touchscreen...");
            }
            else if (m_CheckPeripherals.current == typeof (StateCalibrateTouchscreen))
            {
                m_Splash.message ("Touchscreen calibration...");
            }
            else if (m_CheckPeripherals.current == typeof (StateCheckPanel))
            {
                m_Splash.message ("Checking panel...");
            }
            else if (m_CheckPeripherals.current == typeof (StateCheckPanelFirmware))
            {
                m_Splash.message ("Checking panel firmware...");
            }
            else if (m_CheckPeripherals.current == typeof (StateConfigurePanel))
            {
                m_Splash.message ("Configure panel...");
            }
            else if (m_CheckPeripherals.current == typeof (StateCheckSSIDab))
            {
                m_Splash.message ("Checking DABs...");
            }
            m_NumStep++;

            m_Splash.progress ((int)(((double)m_NumStep / (double)m_CheckPeripherals.length) * 100.0));
        }

        private void
        on_check_peripherals_finished ()
        {
            m_Splash.set_phase_status (Splash.Phase.CHECK_DEVICE, m_CheckPeripheralsStatus);
            m_Splash.message ("");
            start_session ();
        }

        private bool
        on_check_peripherals_error (string inMessage)
        {
            bool ret = false;

            if (!m_PendingError)
            {
                m_CheckPeripheralsStatus = EventBoot.Status.ERROR;

                string msg = "%s\nPress power button to shutdown or\npress Freeze or F12 button to continue".printf (inMessage);
                m_Splash.error (msg);
                m_PendingError = true;
                ret = true;
            }

            return ret;
        }

        private void
        on_fatal_error (string inMessage)
        {
            string msg = "%s\nPress power button to shutdown".printf (inMessage);
            m_Splash.error (msg);
            m_Splash.set_phase_status (m_Splash.current_phase, EventBoot.Status.ERROR);
        }

        private void
        on_question (string inMessage, GLib.IOChannel inClient)
        {
            string msg = "%s\nPress power button to shutdown or\npress Freeze or F12 button to continue".printf (inMessage);
            m_Splash.error (msg);
            m_Client = inClient;
        }

        private bool
        on_check_peripherals_question (string inMessage)
        {
            m_Splash.question (inMessage);
            return true;
        }

        private void
        change_to_display_vt ()
        {
            Log.debug ("change to display vt: %s", m_Device);

            int vt;

            m_Device.scanf ("/dev/tty%i", out vt);
            change_vt (vt);
        }

        private void
        on_display_ready ()
        {
            Log.debug ("display ready");

            if (!m_TestOnly)
            {
                Os.putenv("DISPLAY=:" + m_Number.to_string ());

                Gtk.init_check (ref m_Args);
                var display = Gdk.Display.open (":" + m_Number.to_string());
                var manager = Gdk.DisplayManager.get ();
                manager.set_default_display (display);
                X.set_io_error_handler (on_display_io_error);
            }
            else
            {
                Gtk.init(ref m_Args);
            }

            m_Splash = new Splash (m_Socket);
            m_Splash.login.connect (on_login_response);
            m_Splash.passwd.connect (on_passwd_response);
            m_Splash.restart.connect (on_restart_request);
            m_Splash.shutdown.connect (on_shutdown_request);
            m_Splash.question_response.connect (on_question_response);
            m_Splash.show ();
            m_Splash.window.focus (Gdk.CURRENT_TIME);
            s_Shutdown |= GLib.FileUtils.test (SHUTDOWN_FILENAME, GLib.FileTest.EXISTS);
            if (s_Shutdown)
                on_init_shutdown ();
            else if (!m_FirstStart)
                on_dbus_ready ();
        }

        private void
        on_session_ready ()
        {
            Log.debug ("session ready");

            if (m_Session != null) m_Splash.hide ();
        }

        private bool
        open_session (string inUserName, bool inFaceAuthentication, bool inAutologin)
        {
            Log.debug ("open session for %s", inUserName);

            bool ret = false;

            try
            {
                if (m_Session == null)
                {
                    Log.info ("open session for %s: number=%i device=%s autologin=%s",
                                  inUserName, m_Number, m_Device, inAutologin.to_string ());
                    if (m_Manager.open_session (inUserName, m_Number, m_Device, inFaceAuthentication, inAutologin, out m_Path))
                    {
                        m_Session = (XSAA.Session)m_Connection.get_object ("fr.supersonicimagine.XSAA.Manager",
                                                                           m_Path,
                                                                           "fr.supersonicimagine.XSAA.Manager.Session");
                        if (m_Session != null)
                        {
                            m_Session.died.connect (on_session_ended);
                            m_Session.exited.connect (on_session_ended);
                            m_Session.info.connect (on_session_info);
                            m_Session.error_msg.connect (on_error_msg);
                            ret = true;
                        }
                        else
                            Log.warning ("error on open session");
                    }
                    else
                        Log.warning ("error on open session");
                }
            }
            catch (GLib.Error err)
            {
                Log.critical ("error on launch session: %s", err.message);
            }

            return ret;
        }

        private void
        start_session ()
        {
            if (m_User == null || m_User.length == 0)
            {
                Log.debug ("ask for login");
                int nb_user = -1;
                try
                {
                    nb_user = m_Manager.get_nb_users ();
                }
                catch (DBus.Error err)
                {
                    Log.warning ("error on get nb users: %s", err.message);
                }

                m_Splash.ask_for_login (nb_user);
            }
            else
            {
                Log.info ("start session for user %s", m_User);
                if (open_session(m_User, false, true))
                {
                    try
                    {
                        m_Session.authenticate ();
                        m_Session.authenticated.connect (on_authenticated);
                    }
                    catch (GLib.Error err)
                    {
                        Log.warning ("error on session authenticate: %s", err.message);
                    }
                }
                else
                    Log.warning ("Error on open session");
            }
        }

        private void
        on_dbus_ready()
        {
            Log.debug ("dbus ready");

#if HAVE_LOGON
            if (!(Log.get_default_logger () is XSAA.Log.Logon))
            {
                Log.set_default_logger (new XSAA.Log.Logon (XSAA.Log.Level.DEBUG, "xsplashaa", "splash", "main"));
            }
#endif

            m_Device = m_Display.get_device ();
            if (m_Device == null)
                m_Device = "/dev/tty1";

            m_Display.reload_input_device ();

            try
            {
                if (m_Connection == null)
                {
                    m_Connection = DBus.Bus.get (DBus.BusType.SYSTEM);
                }

                // Switch to check devices phase
                m_Splash.set_phase_status (m_Splash.current_phase, EventBoot.Status.FINISHED);
                m_Splash.set_phase_status (Splash.Phase.CHECK_DEVICE, EventBoot.Status.PENDING);

                if (m_Manager == null)
                {
                    m_Manager = (XSAA.Manager)m_Connection.get_object ("fr.supersonicimagine.XSAA.Manager",
                                                                       "/fr/supersonicimagine/XSAA/Manager",
                                                                       "/fr/supersonicimagine/XSAA/Manager");
                }
                if (m_Manager == null)
                {
                    Log.warning ("Error on get manager object");
                }

                if ((m_Check & CheckFlags.PERIPHERALS) == CheckFlags.PERIPHERALS && m_CheckPeripherals == null)
                {
                    m_NumStep = 0;
                    m_CheckPeripherals = new StateCheckPeripherals (m_Connection, m_Check, m_Number);
                    m_CheckPeripherals.step.connect (on_check_peripherals_step);
                    m_CheckPeripherals.finished.connect (on_check_peripherals_finished);
                    m_CheckPeripherals.message.connect (on_check_peripherals_message);
                    m_CheckPeripherals.error.connect (on_check_peripherals_error);
                    m_CheckPeripherals.progress.connect (on_check_peripherals_progress);
                    m_CheckPeripherals.question.connect (on_check_peripherals_question);
                    m_CheckPeripherals.run ();
                }
                else
                {
                    start_session ();
                }
            }
            catch (GLib.Error err)
            {
                Log.warning ("Error on connect to dbus system: %s", err.message);
            }
        }

        private void
        on_session_ended ()
        {
            Log.debug ("session ended");
            if (m_Manager != null && m_Path != null)
            {
                try
                {
                    m_Manager.close_session (m_Path);
                }
                catch (GLib.Error err)
                {
                    Log.warning ("error on close session: %s", err.message);
                }
            }
            m_Session = null;

            m_Splash.ask_for_login ();
            m_Splash.show ();
            m_Splash.window.focus (Gdk.CURRENT_TIME);
        }

        private void
        on_init_shutdown()
        {
            Log.debug ("init shutdown");

            change_to_display_vt ();
            if (m_Manager != null && m_Path != null && m_Session != null)
            {
                try
                {
                    m_Manager.close_session (m_Path);
                }
                catch (GLib.Error err)
                {
                    Log.warning ("error on close session: %s", err.message);
                }
                m_Session = null;
            }
            m_Manager = null;
            m_Connection = null;
            if (!s_Shutdown && Os.setjmp (m_Env) == 0)
            {
                try
                {
                    Log.debug ("create shutdown file: %s", SHUTDOWN_FILENAME);
                    GLib.IOChannel file = new GLib.IOChannel.file(SHUTDOWN_FILENAME, "w");
                    file.set_close_on_unref(true);
                }
                catch (GLib.Error err)
                {
                    Log.warning ("error on create: %s", SHUTDOWN_FILENAME);
                }
                s_Shutdown = true;
            }

            m_Splash.show_shutdown();
            m_Splash.show ();
            m_Splash.window.focus (Gdk.CURRENT_TIME);

            Gdk.Display display = Gdk.Display.get_default ();
            for (int cpt = 0; cpt < display.get_n_screens (); ++cpt)
            {
                Gdk.Screen screen = display.get_screen(cpt);
                Gdk.Window root = screen.get_root_window ();
                Gdk.property_delete (root, Gdk.Atom.intern ("_XROOTPMAP_ID", true));
                Gdk.property_delete (root, Gdk.Atom.intern ("ESETROOT_PMAP_ID", true));
            }
        }

        private void
        on_restart_request ()
        {
            Log.info ("restart request");

            if (m_Manager != null)
            {
                try
                {
                    m_Manager.reboot();
                    m_Manager = null;
                    m_Connection = null;
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on launch restart: %s", err.message);
                }
            }
            else if (m_RebootRequestId == 0)
            {
                if (m_ShutdownRequestId != 0)
                {
                    GLib.Source.remove (m_ShutdownRequestId);
                    m_ShutdownRequestId = 0;
                }
                // stop init process
                Os.kill (Os.SIGSTOP, 1);
                // sync disks
                Os.sync ();
                m_RebootRequestId = GLib.Timeout.add_seconds (3, () => {
                    if (m_RebootRequestId != 0)
                    {
                        Os.reboot (Os.RebootCommands.AUTOBOOT);
                        m_RebootRequestId = 0;
                    }
                    return false;
                });
            }
            m_Splash.show_shutdown();
        }

        private void
        on_shutdown_request ()
        {
            Log.info ("shutdown request");

            if (m_Manager != null)
            {
                try
                {
                    m_Manager.halt();
                    m_Manager = null;
                    m_Connection = null;
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on launch shutdown: %s", err.message);
                }
            }
            else if (m_ShutdownRequestId == 0)
            {
                if (m_RebootRequestId != 0)
                {
                    GLib.Source.remove (m_RebootRequestId);
                    m_RebootRequestId = 0;
                }
                // stop init process
                Os.kill (Os.SIGSTOP, 1);
                // sync disks
                Os.sync ();
                m_ShutdownRequestId = GLib.Timeout.add_seconds (3, () => {
                    if (m_ShutdownRequestId != 0)
                    {
                        Os.reboot (Os.RebootCommands.POWER_OFF);
                        m_ShutdownRequestId = 0;
                    }
                    return false;
                });
            }
            m_Splash.show_shutdown();
        }

        private void
        on_display_exit ()
        {
            Log.info ("display exit");

            Gtk.main_quit();
            Os.exit(-1);
        }

        private void
        on_quit ()
        {
            Log.debug ("quit requested");

            Gtk.main_quit();
        }

        private void
        on_session_info (string inMsg)
        {
            Log.debug ("session info: %s", inMsg);
            m_Splash.login_message (inMsg);
        }

        private void
        on_error_msg (string inMsg)
        {
            Log.debug ("session error: %s", inMsg);

            m_User = null;
            m_Pass = null;

            if (m_Session != null)
            {
                try
                {
                    Log.info ("close session: %s", m_Path);

                    m_Manager.close_session (m_Path);
                }
                catch (DBus.Error err)
                {
                    Log.critical ("error on close session: %s", err.message);
                }
                m_Session = null;
            }

            m_Splash.login_message (inMsg);
            m_Splash.ask_for_login ();
        }

        private void
        on_authenticated ()
        {
            Log.debug ("user authenticated");

            try
            {
                Log.info ("launch %s", m_Exec);
                m_Session.launch (m_Exec);
                m_Splash.set_phase_status (Splash.Phase.SESSION, EventBoot.Status.PENDING);
            }
            catch (DBus.Error err)
            {
                Log.critical ("error on launch session: %s", err.message);
            }
        }

        private void
        on_ask_passwd ()
        {
            Log.debug ("Ask password");
            m_Splash.ask_for_passwd ();
        }

        private void
        on_ask_face_authentication ()
        {
            Log.debug ("Ask face authentication");
            m_Splash.ask_for_face_authentication ();
        }

        private void
        on_login_response (string inUserName, bool inFaceAuthentication)
        {
            Log.debug ("login response for %s", inUserName);

            if (open_session (inUserName, inFaceAuthentication, false))
            {
                Log.info ("open session for %s", inUserName);

                m_User = inUserName;
                try
                {
                    m_Session.authenticate ();
                    m_Session.authenticated.connect (on_authenticated);
                    if (inFaceAuthentication)
                    {
                        m_Session.ask_face_authentication.connect (on_ask_face_authentication);
                    }
                    else
                    {
                        m_Session.ask_passwd.connect (on_ask_passwd);
                    }
                }
                catch (DBus.Error err)
                {
                    Log.critical ("error on open session: %s", err.message);
                }
            }
            else
            {
                m_User = null;
                m_Pass = null;
                m_Splash.ask_for_login ();
            }
        }

        private void
        on_passwd_response (string inPasswd)
        {
            Log.debug ("passwd response");
            try
            {
                m_Session.set_passwd(inPasswd);
            }
            catch (DBus.Error err)
            {
                Log.warning ("Error on set passwd: %s", err.message);
            }
        }

        private void
        on_question_response (EventMessage.Response inResult)
        {
            if (m_CheckPeripherals.current != GLib.Type.INVALID)
            {
                m_CheckPeripherals.question_response (inResult == EventMessage.Response.YES);
            }
        }

        public void
        run (bool inFirstStart)
        {
            Log.debug ("run first_start = %s", inFirstStart.to_string ());

            if (m_TestOnly) on_display_ready ();
            m_FirstStart = inFirstStart;
            Gtk.main ();
        }
    }

    static void
    change_vt (int inVt)
    {
        Log.debug ("change vt to %i", inVt);
        int fd, rc;

        fd = Os.open ("/dev/tty" + inVt.to_string(), Os.O_WRONLY | Os.O_NOCTTY, 0);
        if (fd > 0)
        {
            rc = Os.ioctl (fd, Os.VT_ACTIVATE, inVt);
            rc = Os.ioctl (fd, Os.VT_WAITACTIVE, inVt);

            Os.close(fd);
        }
    }

    // constants
    private const OptionEntry[] cOptionEntries =
    {
        { "test-only", 't', 0, OptionArg.NONE, ref sTestOnly, "Test only", null },
        { "xnest", 'x', 0, OptionArg.NONE, ref sXnest, "Xnest", null },
        { "no-daemonize", 'd', 0, OptionArg.NONE, ref sNoDaemon, "Do not run xsplashaa as a daemonn", null },
        { null }
    };

    // static properties
    private static bool sTestOnly = false;
    private static bool sNoDaemon = false;
    private static bool sXnest     = false;

    // static methods
    private static int
    on_display_io_error(X.Display inDisplay)
    {
        Log.critical ("DISPLAY error !!");
        s_Daemon = null;
        return -1;
    }

    private static void
    on_sig_term(int inSigNum)
    {
        Log.info ("received signal %i", inSigNum);

        if (s_Shutdown && s_Daemon != null)
            Os.longjmp(s_Daemon.m_Env, 1);
        else
            Os.exit (-1);
    }

    static int
    main (string[] args)
    {
        Log.set_default_logger (new XSAA.Log.KMsg (XSAA.Log.Level.INFO, "xsplashaa"));

        Log.debug ("starting");

        try
        {
            OptionContext opt_context = new OptionContext("- Xsplashaa");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(cOptionEntries, "xsplashaa");
            opt_context.parse(ref args);
        }
        catch (OptionError err)
        {
            Log.critical ("option parsing failed: %s", err.message);
            return -1;
        }

        if (sTestOnly)
        {
            try
            {
                s_Daemon = new Daemon (SOCKET_NAME, sTestOnly);
                s_Daemon.m_Args = args;
                s_Daemon.run(true);
                s_Daemon = null;
            }
            catch (GLib.Error err)
            {
                Log.critical ("%s", err.message);
                s_Daemon = null;
                return -1;
            }
        }
        else if (sXnest)
        {
            try
            {
                Os.signal(Os.SIGSEGV, on_sig_term);
                s_Daemon = new Daemon.xnest (SOCKET_NAME, sTestOnly);
                s_Daemon.m_Args = args;
                s_Daemon.run(true);
                s_Daemon = null;
            }
            catch (GLib.Error err)
            {
                Log.critical ("%s", err.message);
                s_Daemon = null;
                return -1;
            }
        }
        else
        {
            if (!sNoDaemon)
            {
                if (Os.daemon (0, 0) < 0)
                {
                    Log.critical ("error on launch has daemon");
                    return -1;
                }
            }

            Os.pid_t pid;
            Os.pid_t ppgid;

            pid = Os.getpid();
            ppgid = Os.getpgid(pid);
            Os.setsid();
            Os.setpgid(0, ppgid);

            Os.signal(Os.SIGTERM, Os.SIG_IGN);
            Os.signal(Os.SIGKILL, Os.SIG_IGN);
            int status = -1;
            bool first_start = true;
            int nb_start = 0;
            while (status != 0 && nb_start < 5)
            {
                int ret_fork = Os.fork();

                if (ret_fork == 0)
                {
                    try
                    {
                        Log.info ("starting child deamon");
                        Os.signal(Os.SIGSEGV, on_sig_term);
                        Os.signal(Os.SIGTERM, on_sig_term);
                        s_Daemon = new Daemon (SOCKET_NAME);
                        s_Daemon.m_Args = args;
                        s_Daemon.run(first_start);
                        s_Daemon = null;
                    }
                    catch (GLib.Error err)
                    {
                        Log.critical ("error on starting child daemon: %s", err.message);
                        s_Daemon = null;
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
                    Os.wait(out ret);
                    status = Process.exit_status(ret);
                    Log.info ("child daemon exited with status %i", status);
                }
            }
        }

        Log.debug ("end");

        return 0;
     }
}

