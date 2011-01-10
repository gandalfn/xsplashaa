/* xsaa-session.vala
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

public struct ConsoleKit.SessionParameter
{
    public string key;
    public Value? value ;

    public SessionParameter (string a, Value? b)
    {
        key = a;
        value = b;
    }
}

namespace XSAA
{
    [DBus (name = "fr.supersonicimagine.XSAA.Manager.SessionError")]
    errordomain SessionError
    {
        COMMAND,
        LAUNCH,
        USER,
        XAUTH
    }

    [DBus (name = "fr.supersonicimagine.XSAA.Manager.Session")]
    public class Session : GLib.Object
    {
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
            public MessageType type;
            public string message;

            public Message (MessageType type, string message)
            {
                this.type = type;
                this.message = message;
            }
        }

        private ConsoleKit.Manager ck_manager;
        private string cookie;
        private string display_num;
        private string device_num;

        private GLib.Pid pid = (Pid)0;
        unowned Posix.Passwd passwd;
        private PamSession pam;
        private string xauth_file;

        private GLib.AsyncQueue<Message?> m_MessageQueue;
        private GLib.AsyncQueue<Message?> m_ResponseQueue;

        public signal void died();
        public signal void exited();

        public signal void ask_passwd ();
        public signal void ask_face_authentication ();
        public signal void authenticated();
        public signal void info (string msg);
        public signal void error_msg (string msg);

        public Session(DBus.Connection conn, ConsoleKit.Manager manager, 
                       string service, string user, int display, string device) throws SessionError
        {
            GLib.debug ("create ck session");

            ck_manager = manager;

            passwd = Posix.getpwnam(user);
            if (passwd == null)
            {
                throw new SessionError.USER("%s doesn't exist!", user);
            }

            generate_xauth(user, display);

            try
            {
                pam = new PamSession(service, user, display, xauth_file, device);
                pam.info.connect(on_info);
                pam.error_msg.connect(on_error_msg);
            }
            catch (PamError err)
            {
                throw new SessionError.USER("Error on create pam session");
            }

            display_num = ":" + display.to_string();
            device_num = device;

            m_MessageQueue = new GLib.AsyncQueue<Message?> ();
            m_ResponseQueue = new GLib.AsyncQueue<Message?> ();
        }

        ~Session()
        {
            GLib.debug ("destroy ck session");

            if (FileUtils.test(xauth_file, FileTest.EXISTS))
            {
                FileUtils.remove(xauth_file);
            }
            if (cookie != null)
                ck_manager.close_session(cookie);
            if (pid != (Pid)0)
                Posix.kill((Posix.pid_t)pid, Posix.SIGKILL);
            pid = (Pid)0;
        }

        private void
        generate_xauth(string user, int display) throws SessionError
        {
            GLib.debug ("generate xauth for user %s and display %i", user, display);

            if (!FileUtils.test(PACKAGE_XAUTH_DIR, FileTest.EXISTS | FileTest.IS_DIR))
            {
                DirUtils.create(PACKAGE_XAUTH_DIR, 0777);
                FileUtils.chmod(PACKAGE_XAUTH_DIR, 0777);
            }

            xauth_file = PACKAGE_XAUTH_DIR + "/xauth-" + user + "-" + display.to_string();
            if (FileUtils.test(xauth_file, FileTest.EXISTS))
            {
                FileUtils.remove(xauth_file);
            }

            FileStream f = FileStream.open(xauth_file, "w");
                        
            X.Auth auth = X.Auth();

            auth.family = X.FamilyLocal;
            auth.address = "localhost";
            auth.address_length = (ushort)"localhost".length;
            auth.number = display.to_string();
            auth.number_length = (ushort)display.to_string().length;
            auth.name = "MIT-MAGIC-COOKIE-1";
            auth.name_length = (ushort)"MIT-MAGIC-COOKIE-1".length;

            auth.data = "";

            char[] data = new char[16];
            for (int i = 0; i < 16; i++)
                data[i] = (char)Random.int_range(0, 256);

            auth.data = string.nfill(16, ' ');
            Memory.copy(auth.data, data, 16);
            auth.data_length = 16;
            
            auth.write(f);
            f.flush();
            
            if (Posix.chown(xauth_file, passwd.pw_uid, passwd.pw_gid) < 0)
            {
                throw new SessionError.XAUTH("Error on generate " + xauth_file);
            }
        }

        private void
        register()
        {
            GLib.debug ("register");

            Value user_val = Value (typeof(int));
            user_val.set_int((int)passwd.pw_uid);
            ConsoleKit.SessionParameter unixuser = 
                ConsoleKit.SessionParameter ("unix-user", user_val);

            Value display_val = Value (typeof(string));
            display_val.set_string(display_num);
            ConsoleKit.SessionParameter x11display = 
                ConsoleKit.SessionParameter("x11-display", display_val);

            Value display_dev_val = Value (typeof(string));
            display_dev_val.set_string(device_num);
            ConsoleKit.SessionParameter x11displaydev = 
                ConsoleKit.SessionParameter("x11-display-device", display_dev_val);

            Value is_local_val = Value (typeof(bool));
            is_local_val.set_boolean(true);
            ConsoleKit.SessionParameter islocal = 
                ConsoleKit.SessionParameter("is-local", is_local_val);

            Value session_type_val = Value (typeof(string));
            session_type_val.set_string("xsplashaa");
            ConsoleKit.SessionParameter session_type = 
                ConsoleKit.SessionParameter("session-type", session_type_val);

            ConsoleKit.SessionParameter[] parameters = {unixuser,
                                                        x11display,
                                                        x11displaydev,
                                                        session_type,
                                                        islocal};

            try
            {
                cookie = ck_manager.open_session_with_parameters (parameters); 
            }
            catch (GLib.Error err)
            {
                GLib.critical ("error on generate ck session");
            }
        }

        private void
        on_child_setup()
        {
            GLib.debug ("child setup");

            try
            {
                pam.open_session();
            }
            catch (GLib.Error err)
            {
                error_msg("Invalid user or wrong password");
                GLib.critical ("error on open pam session");
                Posix.exit(1);
            }

            pam.add_env ("PATH", "/usr/sbin:/usr/bin:/sbin:/bin");
            pam.add_env ("XAUTHORITY", xauth_file);
            pam.add_env ("XDG_SESSION_COOKIE", cookie);
            pam.add_env ("DISPLAY", display_num);
            pam.set_env();

            Posix.unsetenv ("DBUS_STARTER_BUS_TYPE");
            Posix.unsetenv ("DBUS_STARTER_ADDRESS");

            int fd = Posix.open ("/dev/null", Posix.O_RDONLY);
            Posix.dup2 (fd, 0);
            Posix.close (fd);

            Posix.unlink (passwd.pw_dir + "/.xsession-errors.old");
            Posix.link (passwd.pw_dir + "/.xsession-errors", passwd.pw_dir + "/.xsession-errors.old");
            fd = Posix.open(passwd.pw_dir + "/.xsession-errors", 
                            Posix.O_TRUNC | Posix.O_CREAT | Posix.O_WRONLY, 0644);
            Posix.dup2 (fd, 1);
            Posix.dup2 (fd, 2);
            Posix.close (fd);
        }

        private void
        on_child_watch(Pid pid, int status)
        {
            GLib.debug ("child watch %lu: %i", pid, status);

            if (Process.if_exited(status))
                exited();
            else if (Process.if_signaled(status))
                died();

            Process.close_pid(pid);
            this.pid = (Pid)0;

            try
            {
                GLib.message ("launch killall dbus-launch");

                Process.spawn_command_line_async("killall dbus-launch");
            }
            catch (GLib.Error err)
            {
               GLib.debug ("error on launch killall dbus-launch: %s",
                           err.message);
            }
        }

        private bool
        on_message ()
        {
            Message msg = m_MessageQueue.pop ();

            switch (msg.type)
            {
                case MessageType.ASK_PASSWD:
                    GLib.debug ("Received ask passwd message");
                    ask_passwd ();
                    break;
                case MessageType.ASK_FACE_AUTHENTICATION:
                    GLib.debug ("Received ask face authentication message");
                    ask_face_authentication ();
                    break;
                case MessageType.AUTHENTIFICATED:
                    GLib.debug ("Received authenticated message");
                    authenticated ();
                    break;
                case MessageType.INFO:
                    GLib.debug ("Received info message");
                    info (msg.message);
                    break;
                case MessageType.ERROR:
                    GLib.debug ("Received error message");
                    error_msg (msg.message);
                    break;
                case MessageType.FINISHED:
                    GLib.debug ("Received finished message");
                    pam.info.connect (on_info);
                    pam.error_msg.connect (on_error_msg);
                    break;
                default:
                    break;
            }

            return false;
        }

        private string
        on_ask_passwd()
        {
            GLib.debug ("send ask passwd message");
            Message msg = Message (MessageType.ASK_PASSWD, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
            Message response = m_ResponseQueue.pop ();
            return response.type == MessageType.ASK_PASSWD_RESPONSE ? response.message : null;
        }

        private void
        on_ask_face_authentication ()
        {
            GLib.debug ("send ask face authentication message");
            Message msg = Message (MessageType.ASK_FACE_AUTHENTICATION, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_authentificated ()
        {
            GLib.debug ("send authenticated message");
            Message msg = Message (MessageType.AUTHENTIFICATED, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_authenticate_info(string text)
        {
            GLib.debug ("authenticate info message: %s", text);
            Message msg = Message (MessageType.INFO, text);
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_authenticate_error_msg(string text)
        {
            GLib.debug ("authenticate error message: %s", text);
            Message msg = Message (MessageType.ERROR, text);
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);
        }

        private void
        on_info(string text)
        {
            GLib.debug ("info message: %s", text);
            info (text);
        }

        private void
        on_error_msg(string text)
        {
            GLib.debug ("error message: %s", text);
            error_msg (text);
        }

        private void*
        start_authenticate ()
        {
            GLib.debug ("start authenticate");

            pam.authenticated.connect (on_authentificated);
            pam.passwd.connect (on_ask_passwd);
            pam.face_authentication.connect (on_ask_face_authentication);
            pam.info.connect (on_authenticate_info);
            pam.error_msg.connect (on_authenticate_error_msg);

            pam.authenticate ();

            pam.info.disconnect (on_authenticate_info);
            pam.error_msg.disconnect (on_authenticate_error_msg);

            Message msg = Message (MessageType.FINISHED, "");
            m_MessageQueue.push (msg);
            GLib.Idle.add (on_message);

            return null;
        }

        public void
        authenticate()
        {
            GLib.debug ("authenticate");

            try
            {
                pam.info.disconnect (on_info);
                pam.error_msg.disconnect (on_error_msg);
                GLib.Thread.create (start_authenticate, false);
            }
            catch (GLib.ThreadError err)
            {
                pam.info.connect (on_info);
                pam.error_msg.connect (on_error_msg);
                GLib.warning ("Error on launch authentification: %s", err.message);
                error_msg ("Error on launch authentification");
            }
        }

        public void
        set_passwd (string passwd)
        {
            Message msg = Message (MessageType.ASK_PASSWD_RESPONSE, passwd);
            m_ResponseQueue.push (msg);
        }

        public void
        launch(string cmd) throws SessionError
        {
            GLib.debug ("launch: %s", cmd);

            string[] argvp;

            register ();

            try
            {
                Shell.parse_argv(cmd, out argvp);
            }
            catch (GLib.Error err)
            {
                throw new SessionError.COMMAND("Invalid %s command !!", 
                                               cmd);
            }

            try
            {
                Process.spawn_async(null, argvp, null, 
                                    SpawnFlags.SEARCH_PATH |
                                    SpawnFlags.DO_NOT_REAP_CHILD, 
                                    on_child_setup, out pid);
                ChildWatch.add((Pid)pid, on_child_watch);
            }
            catch (GLib.Error err)
            {
                throw new SessionError.LAUNCH(err.message);
            }
        }
    }
}
