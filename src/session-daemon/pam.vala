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
    public errordomain PamError
    {
        START,
        AUTHENTICATE,
        AUTHORIZE,
        CREDENTIALS,
        OPEN_SESSION
    }

    private static int
    on_pam_conversation(int inNumMsg, [CCode (array_length = false)]ref Pam.Message[] inMessages, [CCode (array_length = false)]out Pam.Response* outResp, void* inAppdataPtr)
    {
        unowned PamSession pam = (PamSession)inAppdataPtr;
        outResp = new Pam.Response[inNumMsg];

        for (int i = 0; i < inNumMsg; i++)
        {
            unowned Pam.Message msg = inMessages[i];
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
                        outResp[i].resp = Memory.dup(pass, (uint)pass.length);
                        outResp[i].resp_retcode = Pam.SUCCESS;
                    }
                    else
                    {
                        outResp[i].resp = null;
                        outResp[i].resp_retcode = Pam.AUTH_ERR;
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
        // properties
        private string          m_User;
        private bool            m_Accredited = false;
        private bool            m_Openned = false;
        private Pam.Handle      m_PamHandle = null;
        private Pam.Conv        m_Conv;

        public  GLib.HashTable <string, string> m_Envs;

        // signals
        public signal string passwd ();
        public signal void face_authentication ();
        public signal void authenticated();
        public signal void info(string text);
        public signal void error_msg(string text);

        // methods
        public PamSession(string inService, string inUsername, int inDisplay, string inXauthFile, string inDevice) throws PamError
        {
            GLib.debug ("Create pam session for %s", inUsername);
            m_User = inUsername;

            m_Conv = Pam.Conv();
            m_Conv.conv = on_pam_conversation;
            m_Conv.appdata_ptr = this;

            if (Pam.start(inService, inUsername, m_Conv, out m_PamHandle) != Pam.SUCCESS)
            {
                throw new PamError.START("Error on pam start");
            }

            if (m_PamHandle.set_item(Pam.TTY, inDevice) != Pam.SUCCESS)
            {
                throw new PamError.START("Error on set tty");
            }

            if (m_PamHandle.set_item(Pam.RHOST, "localhost") != Pam.SUCCESS)
            {
                throw new PamError.START("Error on set rhost");
            }

            if (m_PamHandle.set_item(Pam.XDISPLAY, ":" + inDisplay.to_string()) != Pam.SUCCESS)
            {
                throw new PamError.START("Error on set display");
            }

            FileStream f = FileStream.open(inXauthFile, "r");
            weak X.Auth? auth = X.Auth.read(f);
            if (auth != null)
            {
                var pam_xauth = Pam.XauthData();

                if (auth.name != null && auth.name.length > 0)
                {
                    pam_xauth.name = new char [auth.name.length + 1];
                    GLib.Memory.copy (pam_xauth.name, auth.name, auth.name.length);
                    pam_xauth.name[auth.name.length] = '\0';
                    pam_xauth.name.length--;
                }
                else
                {
                    pam_xauth.name = null;
                    pam_xauth.name.length = 0;
                }

                if (auth.data != null && auth.data.length > 0)
                {
                    pam_xauth.data = new char [auth.data.length + 1];
                    GLib.Memory.copy (pam_xauth.data, auth.data, auth.data.length);
                    pam_xauth.data[auth.data.length] = '\0';
                    pam_xauth.data.length--;
                }
                else
                {
                    pam_xauth.data = null;
                    pam_xauth.data.length = 0;
                }

                auth.dispose();

                if (m_PamHandle.set_item(Pam.XAUTHDATA, &pam_xauth) != Pam.SUCCESS)
                {
                    throw new PamError.START("Error on set xauth");
                }
            }

            unowned Os.Passwd passwd = Os.getpwnam(m_User);
            m_Envs = new GLib.HashTable <string, string> (GLib.str_hash, GLib.str_equal);

            m_Envs.insert ("USER", passwd.pw_name);
            m_Envs.insert ("USERNAME", passwd.pw_name);
            m_Envs.insert ("LOGNAME", passwd.pw_name);
            m_Envs.insert ("HOME", passwd.pw_dir);
            m_Envs.insert ("SHELL", passwd.pw_shell);
        }

        public void
        authenticate ()
        {
            unowned Os.Passwd passwd = Os.getpwnam(m_User);
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

            if (m_PamHandle.authenticate(0) != Pam.SUCCESS)
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
            unowned Os.Passwd passwd = Os.getpwnam(m_User);
            if (passwd == null)
            {
                throw new PamError.AUTHORIZE("User is not authorized to log in");
            }

            if (m_PamHandle.acct_mgmt(0) != Pam.SUCCESS)
            {
                throw new PamError.AUTHORIZE("User is not authorized to log in");
            }

            if (m_PamHandle.open_session(0) != Pam.SUCCESS)
            {
                throw new PamError.OPEN_SESSION("Error on pam open session");
            }
            m_Openned = true;

            if (m_PamHandle.setcred(Pam.ESTABLISH_CRED) != Pam.SUCCESS)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }
            m_Accredited = true;

            if (Os.initgroups (m_User, passwd.pw_gid) < 0)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            if (Os.setgid(passwd.pw_gid) < 0)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            if (Os.setuid(passwd.pw_uid) < 0)
            {
                throw new PamError.CREDENTIALS("User is not authorized to log in");
            }

            Os.setenv("USER", passwd.pw_name, 1);
            Os.setenv("USERNAME", passwd.pw_name, 1);
            Os.setenv("LOGNAME", passwd.pw_name, 1);
            Os.setenv("HOME", passwd.pw_dir, 1);
            Os.setenv("SHELL", passwd.pw_shell, 1);

            foreach (string env in m_PamHandle.getenvlist())
            {
                string[] e = env.split("=");
                m_Envs.insert (e[0], e[1]);
            }
        }

        ~PamSession()
        {
            if (m_Openned)
            {
                m_PamHandle.close_session(0);
            }
            if (m_Accredited)
            {
                m_PamHandle.setcred(Pam.DELETE_CRED);
            }

            m_PamHandle.end(Pam.SUCCESS);
            GLib.debug ("close pam session");
        }

        public void
        add_env (string inKey, string inValue)
        {
            m_Envs.insert (inKey, inValue);
        }

        public void
        set_env()
        {
            foreach (string key in m_Envs.get_keys())
            {
                Os.setenv(key, m_Envs.lookup (key), 1);
                GLib.debug ("pam env %s=%s", key, m_Envs.lookup (key));
            }
        }
    }
}
