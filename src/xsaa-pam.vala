/* xsaa-pam.vala
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
    errordomain PamError
    {
        START,
        AUTHENTICATE,
        AUTHORIZE,
        CREDENTIALS,
        OPEN_SESSION
    }

    static int
    on_pam_conversation(int num_msg, [CCode (array_length = false)]Pam.Message[] messages, out Pam.Response* resp, void* appdata_ptr)
    {
        unowned PamSession pam = (PamSession)appdata_ptr;
        resp = new Pam.Response[num_msg];

        for (int i = 0; i < num_msg; i++)
        {
            unowned Pam.Message msg = messages[i];
            switch (msg.msg_style)
            {
                case Pam.PROMPT_ECHO_ON:
                    GLib.message ("echo on message : %s", msg.msg);
                    break;
                case Pam.PROMPT_ECHO_OFF:
                    GLib.message ("echo off message : %s", msg.msg);
                    string pass = pam.passwd ();
                    if (pass != null)
                    {
                        resp[i].resp = Memory.dup(pass, (uint)pass.length);
                        resp[i].resp_retcode = Pam.SUCCESS;
                    }
                    else
                    {
                        resp[i].resp = null;
                        resp[i].resp_retcode = Pam.AUTH_ERR;
                    }
                    break;
                case Pam.TEXT_INFO:
                    GLib.message ("text info message : %s", msg.msg);
                    pam.info(msg.msg);
                    break;
                case Pam.ERROR_MSG:
                    GLib.message ("error message : %s", msg.msg);
                    pam.error_msg(msg.msg);
                    break;
                default:
                    GLib.message ("unkown message");
                    break;
            }
        }

        return Pam.SUCCESS;
    }

    public class PamSession : GLib.Object
    {
        string user;
        string pass;
        bool accredited = false;
        bool openned = false;
        Pam.Handle pam_handle = null;
        Pam.Conv conv;
        internal GLib.MainLoop wait_passwd_loop;
        public Vala.Map <string, string> envs;

        public signal string passwd ();
        public signal void face_authentication ();
        public signal void authenticated();
        public signal void info(string text);
        public signal void error_msg(string text);

        public PamSession(string service, string username, int display, string xauth_file, string device) throws PamError
        {
            GLib.debug ("Create pam session for %s", username);
            wait_passwd_loop = new GLib.MainLoop ();
            user = username;
            pass = null;

            conv = Pam.Conv();
            conv.conv = (void*)on_pam_conversation;
            conv.appdata_ptr = this;

            if (Pam.start(service, username, conv, out pam_handle) != Pam.SUCCESS)
            {
                throw new PamError.START("Error on pam start");
            }

            if (pam_handle.set_item(Pam.TTY, device) != Pam.SUCCESS)
            {
                throw new PamError.START("Error on set tty");
            }

            if (pam_handle.set_item(Pam.RHOST, "localhost") != Pam.SUCCESS)
            {
                throw new PamError.START("Error on set rhost");
            }

            if (pam_handle.set_item(Pam.XDISPLAY, ":"+display.to_string()) != Pam.SUCCESS)
            {
                throw new PamError.START("Error on set display");
            }

            FileStream f = FileStream.open(xauth_file, "r");
            weak X.Auth? auth = X.Auth.read(f);
            if (auth != null)
            {
                var pam_xauth = Pam.XauthData();
                pam_xauth.namelen = auth.name_length;
                pam_xauth.name = auth.name;
                pam_xauth.datalen = auth.data_length;
                pam_xauth.data = auth.data;
                auth.dispose();
                if (pam_handle.set_item(Pam.XAUTHDATA, &pam_xauth) != Pam.SUCCESS)
                {
                    throw new PamError.START("Error on set xauth");
                }
            }

            unowned Posix.Passwd passwd = Posix.getpwnam(user);
            envs = new Vala.HashMap <string, string> (GLib.str_hash, GLib.str_equal);

            envs.set("USER", passwd.pw_name);
            envs.set("USERNAME", passwd.pw_name);
            envs.set("LOGNAME", passwd.pw_name);
            envs.set("HOME", passwd.pw_dir);
            envs.set("SHELL", passwd.pw_shell);
        }

        public void
        authenticate ()
        {
            unowned Posix.Passwd passwd = Posix.getpwnam(user);
            string face_authentication_dir = passwd.pw_dir + "/.pam-face-authentication/faces";
            GLib.debug ("check if %s exist", face_authentication_dir);
            if (GLib.FileUtils.test (face_authentication_dir, GLib.FileTest.EXISTS))
            {
                bool found = false;

                GLib.debug ("found %s check if face exist", face_authentication_dir);
                try
                {
                    GLib.Dir dir = GLib.Dir.open (face_authentication_dir, 0);
                    unowned string item = dir.read_name ();
                    while (!found && item != null)
                    {
                        found = item != "." && item != "..";
                        item = dir.read_name ();
                    }
                }
                catch (GLib.FileError err)
                {
                    GLib.warning ("error on open %s: %s", face_authentication_dir,
                                  err.message);
                }

                if (found) face_authentication ();
            }

            if (pam_handle.authenticate(0) != Pam.SUCCESS)
            {
                error_msg ("Authentification failure");
            }
            else
            {
                authenticated ();
            }
        }

        public void
        open_session() throws PamError
        {
            unowned Posix.Passwd passwd = Posix.getpwnam(user);
            if (passwd == null)
            {
                throw new PamError.AUTHORIZE("User is not authorized to log in");
            }

            if (pam_handle.acct_mgmt(0) != Pam.SUCCESS)
            {
                throw new PamError.AUTHORIZE("User is not authorized to log in");
            }

            if (pam_handle.open_session(0) != Pam.SUCCESS)
            {
                throw new PamError.OPEN_SESSION("Error on pam open session");
            }
            openned = true;

            if (pam_handle.setcred(Pam.ESTABLISH_CRED) != Pam.SUCCESS)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }
            accredited = true;

            if (Posix.initgroups (user, passwd.pw_gid) < 0) 
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            if (Posix.setgid(passwd.pw_gid) < 0)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            if (Posix.setuid(passwd.pw_uid) < 0)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            Posix.setenv("USER", passwd.pw_name, 1);
            Posix.setenv("USERNAME", passwd.pw_name, 1);
            Posix.setenv("LOGNAME", passwd.pw_name, 1);
            Posix.setenv("HOME", passwd.pw_dir, 1);
            Posix.setenv("SHELL", passwd.pw_shell, 1);

            foreach (string env in pam_handle.getenvlist())
            {
                string[] e = env.split("=");
                envs.set(e[0], e[1]);
            }
        }

        ~PamSession()
        {
            if (openned)
            {
                pam_handle.close_session(0);
            }
            if (accredited)
            {
                pam_handle.setcred(Pam.DELETE_CRED);
            }

            pam_handle.end(Pam.SUCCESS);
            GLib.debug ("close pam session");
        }

        public void
        add_env (string inKey, string inValue)
        {
            envs.set(inKey, inValue);
        }

        public void
        set_env()
        {
            foreach (string key in envs.get_keys())
            {
                Posix.setenv(key, envs.get(key), 1);
                GLib.debug ("pam env %s=%s", key, envs.get(key));
            }
        }
    }
}
