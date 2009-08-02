/* xsaa-pam.vala
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
using Posix;
using Pam;
using Gee;
using X;

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
    on_pam_conversation(int num_msg, [CCode (array_length = false)]Message[] messages, out Response* resp, void* appdata_ptr)
    {
        unowned PamSession pam = (PamSession)appdata_ptr;
        resp = new Response[num_msg];
        
        for (int i = 0; i < num_msg; i++)
        {
            unowned Message msg = messages[i];
            switch (msg.msg_style)
            {
                case Pam.PROMPT_ECHO_ON:
                    stderr.printf("Echo on message : %s\n", msg.msg);
                    break;
                case Pam.PROMPT_ECHO_OFF:
                    stderr.printf("Echo off message : %s\n", msg.msg);
                    string passwd = pam.passwd();
                    stderr.printf("Passwd : %s\n", passwd);
                    resp[i].resp = Memory.dup(passwd, (uint)passwd.len());
                    resp[i].resp_retcode = Pam.SUCCESS;
                    break;
                case Pam.TEXT_INFO:
                    stderr.printf("Text info message : %s", msg.msg);
                    pam.info(msg.msg);
                    break;
                case Pam.ERROR_MSG:
                    stderr.printf("Error message : %s", msg.msg);
                    pam.error_msg(msg.msg);
                    break;
                default:
                    stderr.printf("unkown message");
                    break;
            }
        }
        
        return Pam.SUCCESS;
    }

    public class PamSession : GLib.Object
    {
        string user;
        bool accredited = false;
        bool openned = false;
        Pam.Handle pam_handle = null;
        Pam.Conv conv;
        public Map <string, string> envs;

        public signal string passwd();
        public signal void info(string text);
        public signal void error_msg(string text);
        
        public PamSession(string service, string username, int display, string xauth_file, string device) throws PamError
        {
            user = username;
            
            conv = new Pam.Conv();
            conv.conv = (void*)on_pam_conversation;
            conv.appdata_ptr = this;

            if (Pam.start(service, username, conv, out pam_handle) != Pam.SUCCESS)
            {
                this.unref();
                throw new PamError.START("Error on pam start");
            }

            if (pam_handle.set_item(TTY, device) != Pam.SUCCESS)
            {
                this.unref();
                throw new PamError.START("Error on set tty");
            }

            if (pam_handle.set_item(RHOST, "localhost") != Pam.SUCCESS)
            {
                this.unref();
                throw new PamError.START("Error on set rhost");
            }

            if (pam_handle.set_item(XDISPLAY, ":"+display.to_string()) != Pam.SUCCESS)
            {
                this.unref();
                throw new PamError.START("Error on set display");
            }

            FileStream f = FileStream.open(xauth_file, "r");
            X.Auth auth = X.Auth.ReadAuth(f);
            if (auth != null)
            {
                Pam.XauthData pam_xauth = new Pam.XauthData();
                pam_xauth.namelen = auth.name_length;
                pam_xauth.name = auth.name;
                pam_xauth.datalen = auth.data_length;
                pam_xauth.data = auth.data;
                if (pam_handle.set_item(XAUTHDATA, pam_xauth) != Pam.SUCCESS)
                {
                    this.unref();
                    throw new PamError.START("Error on set xauth");
                }
            }

            unowned Passwd passwd = getpwnam(user);
            envs = new HashMap <string, string> (GLib.str_hash, GLib.str_equal);

            envs.set("USER", passwd.pw_name);
            envs.set("USERNAME", passwd.pw_name);
            envs.set("LOGNAME", passwd.pw_name);
            envs.set("HOME", passwd.pw_dir);
            envs.set("SHELL", passwd.pw_shell);
        }

        public void
        open_session() throws PamError
        {
            if (pam_handle.authenticate(0) != Pam.SUCCESS)
            {
                throw new PamError.AUTHENTICATE("Error on authenticate");
            }

            unowned Passwd passwd = getpwnam(user);
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

            if (pam_handle.setcred(ESTABLISH_CRED) != Pam.SUCCESS)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }
            accredited = true;

            if (setgid(passwd.pw_gid) < 0)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            if (initgroups (user, passwd.pw_gid) < 0) 
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            setenv("USER", passwd.pw_name, 1);
            setenv("USERNAME", passwd.pw_name, 1);
            setenv("LOGNAME", passwd.pw_name, 1);
            setenv("HOME", passwd.pw_dir, 1);
            setenv("SHELL", passwd.pw_shell, 1);

            foreach (string env in pam_handle.getenvlist())
            {
                string[] e = env.split("=");
                envs.set(e[0], e[1]);
                stderr.printf("Pam env %s=%s\n", e[0], e[1]);
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
                pam_handle.setcred(DELETE_CRED);
            }

            pam_handle.end(Pam.SUCCESS);
            stderr.printf("Close pam session\n");
        }
        
        public void
        set_env()
        {
            foreach (string key in envs.get_keys())
            {
                setenv(key, envs.get(key), 1);
                stderr.printf("Pam env %s=%s\n", key, envs.get(key));
            }
        }
    }
}
