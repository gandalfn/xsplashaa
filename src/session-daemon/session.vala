/* session.vala
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

namespace XSAA
{
    [DBus (name = "fr.supersonicimagine.XSAA.Manager.SessionError")]
    public errordomain SessionError
    {
        COMMAND,
        LAUNCH,
        USER,
        XAUTH
    }

    [DBus (name = "fr.supersonicimagine.XSAA.Manager.Session")]
    public class Session : GLib.Object
    {
        // types
        private enum MessageType
        {
            ASK_PASSWD,
            ASK_PASSWD_RESPONSE,
            ASK_FACE_AUTHENTICATION,
            AUTHENTIFICATED,
            ERROR,
            INFO,
            FINISHED
        }

        private struct Message
        {
            // properties
            public MessageType type;
            public string message;

            // methods
            public Message (MessageType type, string message)
            {
                this.type = type;
                this.message = message;
            }
        }

        // properties
        private FreeDesktop.ConsoleKit.Manager m_CkManager;
        private string                         m_Cookie;
        private string                         m_DisplayNum;
        private string                         m_DeviceNum;

        private GLib.Pid           m_Pid = (GLib.Pid)0;
        unowned Os.Passwd          m_Passwd;
        private PamSession         m_Pam;
        private string             m_XauthFile;

        private GLib.AsyncQueue<Message?> m_MessageQueue;
        private GLib.AsyncQueue<Message?> m_ResponseQueue;

        // signals
        public signal void died();
        public signal void exited();

        public signal void ask_passwd ();
        public signal void ask_face_authentication ();
        public signal void authenticated();
        public signal void info (string msg);
        public signal void error_msg (string msg);

        // methods
        public Session(DBus.Connection inConn, FreeDesktop.ConsoleKit.Manager inManager,
                       string inService, string inUser, int inDisplay, string inDevice) throws SessionError
        {
            Log.debug ("create ck session");

            m_CkManager = inManager;

            m_Passwd = Os.getpwnam(inUser);
            if (m_Passwd == null)
            {
                throw new SessionError.USER("%s doesn't exist!", inUser);
            }

            generate_xauth(inUser, inDisplay);

            try
            {
                m_Pam = new PamSession(inService, inUser, inDisplay, m_XauthFile, inDevice);
                m_Pam.info.connect(on_info);
                m_Pam.error_msg.connect(on_error_msg);
            }
            catch (PamError err)
            {
                throw new SessionError.USER("Error on create pam session");
            }

            m_DisplayNum = ":" + inDisplay.to_string();
            m_DeviceNum = inDevice;

            m_MessageQueue = new GLib.AsyncQueue<Message?> ();
            m_ResponseQueue = new GLib.AsyncQueue<Message?> ();
        }

        ~Session()
        {
            Log.debug ("destroy ck session");

            if (FileUtils.test(m_XauthFile, FileTest.EXISTS))
            {
                FileUtils.remove(m_XauthFile);
            }
            if (m_Cookie != null)
                m_CkManager.close_session(m_Cookie);
            if (m_Pid != (Pid)0)
                Os.kill((Os.pid_t)m_Pid, Os.SIGKILL);
            m_Pid = (Pid)0;
        }

        private void
        generate_xauth(string inUser, int inDisplay) throws SessionError
        {
            Log.debug ("generate xauth for user %s and display %i", inUser, inDisplay);

            if (!FileUtils.test(PACKAGE_XAUTH_DIR, FileTest.EXISTS | FileTest.IS_DIR))
            {
                DirUtils.create(PACKAGE_XAUTH_DIR, 0777);
                FileUtils.chmod(PACKAGE_XAUTH_DIR, 0777);
            }

            m_XauthFile = PACKAGE_XAUTH_DIR + "/xauth-" + inUser + "-" + inDisplay.to_string();
            if (FileUtils.test(m_XauthFile, FileTest.EXISTS))
            {
                FileUtils.remove(m_XauthFile);
            }

            FileStream f = FileStream.open(m_XauthFile, "w");

            X.Auth auth = X.Auth();

            auth.family = X.FamilyLocal;
            auth.address = "localhost".to_utf8 ();
            auth.number = inDisplay.to_string().to_utf8 ();
            auth.name = "MIT-MAGIC-COOKIE-1".to_utf8 ();

            auth.data = "".to_utf8 ();

            char[] data = new char[16];
            for (int i = 0; i < 16; i++)
                data[i] = (char)Random.int_range(0, 256);

            auth.data = data;

            auth.write(f);
            f.flush();

            if (Os.chown(m_XauthFile, m_Passwd.pw_uid, m_Passwd.pw_gid) < 0)
            {
                throw new SessionError.XAUTH("Error on generate " + m_XauthFile);
            }
        }

        private void
        register()
        {
            Log.debug ("register");

            Value user_val = Value (typeof(int));
            user_val.set_int((int)m_Passwd.pw_uid);
            FreeDesktop.ConsoleKit.SessionParameter unixuser = FreeDesktop.ConsoleKit.SessionParameter ("unix-user", user_val);

            Value display_val = Value (typeof(string));
            display_val.set_string(m_DisplayNum);
            FreeDesktop.ConsoleKit.SessionParameter x11display = FreeDesktop.ConsoleKit.SessionParameter("x11-display", display_val);

            Value display_dev_val = Value (typeof(string));
            display_dev_val.set_string(m_DeviceNum);
            FreeDesktop.ConsoleKit.SessionParameter x11displaydev = FreeDesktop.ConsoleKit.SessionParameter("x11-display-device", display_dev_val);

            Value is_local_val = Value (typeof(bool));
            is_local_val.set_boolean(true);
            FreeDesktop.ConsoleKit.SessionParameter islocal = FreeDesktop.ConsoleKit.SessionParameter("is-local", is_local_val);

            Value session_type_val = Value (typeof(string));
            session_type_val.set_string("xsplashaa");
            FreeDesktop.ConsoleKit.SessionParameter session_type = FreeDesktop.ConsoleKit.SessionParameter("session-type", session_type_val);

            FreeDesktop.ConsoleKit.SessionParameter[] parameters = {unixuser,
                                                                    x11display,
                                                                    x11displaydev,
                                                                    session_type,
                                                                    islocal};

            try
            {
                m_Cookie = m_CkManager.open_session_with_parameters (parameters);
            }
            catch (GLib.Error err)
            {
                Log.critical ("error on generate ck session");
            }
        }

        private void
        on_child_setup()
        {
            Log.debug ("child setup");

            try
            {
                m_Pam.open_session();
            }
            catch (GLib.Error err)
            {
                error_msg("Invalid user or wrong password");
                Log.critical ("error on open pam session");
                Os.exit(1);
            }

            m_Pam.add_env ("PATH", "/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin:/usr/games");
            m_Pam.add_env ("XAUTHORITY", m_XauthFile);
            m_Pam.add_env ("XDG_SESSION_COOKIE", m_Cookie);
            m_Pam.add_env ("DISPLAY", m_DisplayNum);
            m_Pam.set_env();

            Os.unsetenv ("DBUS_STARTER_BUS_TYPE");
            Os.unsetenv ("DBUS_STARTER_ADDRESS");

            int fd = Os.open ("/dev/null", Os.O_RDONLY);
            Os.dup2 (fd, 0);
            Os.close (fd);

            GLib.FileUtils.unlink (m_Passwd.pw_dir + "/.xsession-errors.old");
            Os.link (m_Passwd.pw_dir + "/.xsession-errors", m_Passwd.pw_dir + "/.xsession-errors.old");
            fd = Os.open(m_Passwd.pw_dir + "/.xsession-errors",
                         Os.O_TRUNC | Os.O_CREAT | Os.O_WRONLY, 0644);
            Os.dup2 (fd, 1);
            Os.dup2 (fd, 2);
            Os.close (fd);
        }

        private void
        on_child_watch(GLib.Pid inPid, int inStatus)
        {
            Log.debug ("child watch %lu: %i", inPid, inStatus);

            try
            {
                Log.info ("launch killall dbus-launch cairo-compmgr");

                Process.spawn_command_line_async("killall dbus-launch");
                Process.spawn_command_line_async("killall cairo-compmgr");
            }
            catch (GLib.Error err)
            {
               Log.debug ("error on launch killall dbus-launch: %s",
                           err.message);
            }

            Process.close_pid(inPid);
            m_Pid = (Pid)0;

            if (Process.if_exited(inStatus))
                exited();
            else if (Process.if_signaled(inStatus))
                died();
        }

        private bool
        on_message ()
        {
            Message msg = m_MessageQueue.pop ();

            switch (msg.type)
            {
                case MessageType.ASK_PASSWD:
                    Log.debug ("Received ask passwd message");
                    ask_passwd ();
                    break;
                case MessageType.ASK_FACE_AUTHENTICATION:
                    Log.debug ("Received ask face authentication message");
                    ask_face_authentication ();
                    break;
                case MessageType.AUTHENTIFICATED:
                    Log.debug ("Received authenticated message");
                    authenticated ();
                    break;
                case MessageType.INFO:
                    Log.debug ("Received info message");
                    info (msg.message);
                    break;
                case MessageType.ERROR:
                    Log.debug ("Received error message");
                    error_msg (msg.message);
                    break;
                case MessageType.FINISHED:
                    Log.debug ("Received finished message");
                    m_Pam.info.connect (on_info);
                    m_Pam.error_msg.connect (on_error_msg);
                    break;
                default:
                    break;
            }

            return false;
        }

        private string
        on_ask_passwd()
        {
            Log.debug ("send ask passwd message");
            Message msg = Message (MessageType.ASK_PASSWD, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
            Message response = m_ResponseQueue.pop ();
            return response.type == MessageType.ASK_PASSWD_RESPONSE ? response.message : null;
        }

        private void
        on_ask_face_authentication ()
        {
            Log.debug ("send ask face authentication message");
            Message msg = Message (MessageType.ASK_FACE_AUTHENTICATION, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_authentificated ()
        {
            Log.debug ("send authenticated message");
            Message msg = Message (MessageType.AUTHENTIFICATED, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_authenticate_info(string inText)
        {
            Log.debug ("authenticate info message: %s", inText);
            Message msg = Message (MessageType.INFO, inText);
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_authenticate_error_msg(string inText)
        {
            Log.debug ("authenticate error message: %s", inText);
            Message msg = Message (MessageType.ERROR, inText);
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_info(string inText)
        {
            Log.debug ("info message: %s", inText);
            info (inText);
        }

        private void
        on_error_msg(string inText)
        {
            Log.debug ("error message: %s", inText);
            error_msg (inText);
        }

        private void*
        start_authenticate ()
        {
            Log.debug ("start authenticate");

            m_Pam.authenticated.connect (on_authentificated);
            m_Pam.passwd.connect (on_ask_passwd);
            m_Pam.face_authentication.connect (on_ask_face_authentication);
            m_Pam.info.connect (on_authenticate_info);
            m_Pam.error_msg.connect (on_authenticate_error_msg);

            m_Pam.authenticate ();

            m_Pam.info.disconnect (on_authenticate_info);
            m_Pam.error_msg.disconnect (on_authenticate_error_msg);

            Message msg = Message (MessageType.FINISHED, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);

            return null;
        }

        public void
        authenticate()
        {
            Log.debug ("authenticate");

            try
            {
                m_Pam.info.disconnect (on_info);
                m_Pam.error_msg.disconnect (on_error_msg);
                GLib.Thread.create<void*> (start_authenticate, false);
            }
            catch (GLib.ThreadError err)
            {
                m_Pam.info.connect (on_info);
                m_Pam.error_msg.connect (on_error_msg);
                Log.warning ("Error on launch authentification: %s", err.message);
                error_msg ("Error on launch authentification");
            }
        }

        public void
        set_passwd (string inPasswd)
        {
            Message msg = Message (MessageType.ASK_PASSWD_RESPONSE, inPasswd);
            m_ResponseQueue.push (msg);
        }

        public void
        launch(string inCmd) throws SessionError
        {
            Log.info ("launch: %s", inCmd);

            string[] argvp;

            register ();

            try
            {
                Shell.parse_argv(inCmd, out argvp);
            }
            catch (GLib.Error err)
            {
                throw new SessionError.COMMAND("Invalid %s command !!",
                                               inCmd);
            }

            try
            {
                Process.spawn_async(null, argvp, null,
                                    SpawnFlags.SEARCH_PATH |
                                    SpawnFlags.DO_NOT_REAP_CHILD,
                                    on_child_setup, out m_Pid);
                ChildWatch.add((Pid)m_Pid, on_child_watch);
            }
            catch (GLib.Error err)
            {
                throw new SessionError.LAUNCH(err.message);
            }
        }
    }
}

