/* xsaa-session.vala
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
using DBus;

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
        private ConsoleKit.Manager ck_manager;
        private string cookie;
        private string display_num;
        private string device_num;

        private Pid pid = 0;
        unowned Passwd passwd;
        private string pass = null;
        private PamSession pam;
        private string xauth_file;

        public signal void died();
        public signal void exited();

        public signal void authenticated();
        public signal void info (string msg);
        public signal void error_msg (string msg);
        
        public Session(DBus.Connection conn, ConsoleKit.Manager manager, 
                       string service, string user, int display, string device) throws SessionError
        {
            ck_manager = manager;
            
            passwd = getpwnam(user);
            if (passwd == null)
            {
                this.unref();
                throw new SessionError.USER("%s doesn't exist!", user);
            }
            
            generate_xauth(user, display);
            
            try
            {
                pam = new PamSession(service, user, display, xauth_file, device);
                pam.passwd += on_ask_passwd;
                pam.info += on_info;
                pam.error_msg += on_error_msg;
            }
            catch (PamError err)
            {
                this.unref();
                throw new SessionError.USER("Error on create pam session");
            }

            display_num = ":" + display.to_string();
            device_num = device;
        }

        ~Session()
        {
            stderr.printf("Close ck session\n");
            if (FileUtils.test(xauth_file, FileTest.EXISTS))
            {
                FileUtils.remove(xauth_file);
            }
            if (cookie != null)
                ck_manager.close_session(cookie);
            if (pid != (Pid)0)
                kill((pid_t)pid, SIGKILL);
            pid = (Pid)0;
        }
        
        private void
        generate_xauth(string user, int display) throws SessionError
        {
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
            
            X.Auth auth = new X.Auth();
            auth.family = X.FamilyLocal;
            auth.address = "localhost";
            auth.address_length = (ushort)"localhost".len();
            auth.number = display.to_string();
            auth.number_length = (ushort)display.to_string().len();
            auth.name = "MIT-MAGIC-COOKIE-1";
            auth.name_length = (ushort)"MIT-MAGIC-COOKIE-1".len();

            auth.data = "";

            char[] data = new char[16];
            for (int i = 0; i < 16; i++)
                data[i] = (char)Random.int_range(0, 256);

            auth.data = string.nfill(16, ' ');
            Memory.copy(auth.data, data, 16);
            auth.data_length = 16;
            
            X.Auth.WriteAuth(f, auth);
            f.flush();
           
            if (chown(xauth_file, passwd.pw_uid, passwd.pw_gid) < 0)
            {
                throw new SessionError.XAUTH("Error on generate " + xauth_file);
            }
        }
        
        private void
        register()
        {
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

            ConsoleKit.SessionParameter[] parameters = {unixuser,
                                                        x11display,
							                            x11displaydev,
							                            islocal};

            cookie = ck_manager.open_session_with_parameters (parameters); 
        }
        
        private void
        on_child_setup()
        {
            try
            {
                pam.open_session();
            }
            catch (GLib.Error err)
            {
                error_msg("Invalid user or wrong password");
                stderr.printf("Error on open pam session\n");
                exit(1);
            }

	        if (setsid() < 0)
	        {
                error_msg("Error on user authentification");
                stderr.printf("Error on change user\n");
                exit(1);
	        }

            if (setuid(passwd.pw_uid) < 0)
            {
                error_msg("Error on user authentification");
                stderr.printf("Error on change user\n");
                exit(1);
            }

            pam.set_env();

            setenv("XAUTHORITY", xauth_file, 1);
            setenv("XDG_SESSION_COOKIE", cookie, 1);
            setenv("DISPLAY", display_num, 1);
            
            int fd = open ("/dev/null", O_RDONLY);
            dup2 (fd, 0);
            close (fd);
	
            fd = open(passwd.pw_dir + "/.xsession-errors", 
                      O_TRUNC | O_CREAT | O_WRONLY, 0644);
            dup2 (fd, 1);
            dup2 (fd, 2);
            close (fd);
        }

        private void
        on_child_watch(Pid pid, int status)
        {
            if (Process.if_exited(status))
                exited();
            else if (Process.if_signaled(status))
                died();

            Process.close_pid(pid);
            this.pid = (Pid)0;

            try
            {
                Process.spawn_command_line_async("killall dbus-launch");
            }
            catch (GLib.Error err)
            {
                stderr.printf("Error on launch killall dbus-launch: %s\n",
                              err.message);
            }
        }

        private string
        on_ask_passwd()
        {
            return pass;
        }
        
        private void
        on_info(string text)
        {
            info(text);
        }

        private void
        on_error_msg(string text)
        {
            error_msg(text);
        }

        public void
        set_passwd(string pass)
        {
            this.pass = pass;
        }

        public void
        authenticate()
        {
            stderr.printf("Authenticate \n");
            authenticated();
        }
        
        public void
        launch(string cmd) throws SessionError
        {
            string[] argvp;

            register();
            
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
                ChildWatch.add(pid, on_child_watch);        
            }
            catch (GLib.Error err)
            {
                throw new SessionError.LAUNCH(err.message);
            }
        }
    }
}
