/* display.vala
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
    public errordomain DisplayError
    {
        COMMAND,
        LAUNCH
    }

    public class Display : GLib.Object
    {
        // static properties
        private static bool s_IsReady = false;

        // properties
        private uint m_SigHandled = 0;
        private uint m_ChildWatch = 0;
        private GLib.Pid m_Pid = (GLib.Pid)0;
        private int m_Number;
        private X.Display m_XDisplay = null;

        // signals
        public signal void ready();
        public signal void exited();
        public signal void died();

        // static methods
        private static void
        on_sig_usr1(int inSigNum)
        {
            if (inSigNum == Os.SIGUSR1)
            {
                Log.debug ("received display is ready");
                s_IsReady = true;
            }
        }

        // methods
        public Display(string inCmd, int inNumber) throws DisplayError
        {
            Log.debug ("create display %i: %s", inNumber, inCmd);
            m_Number = inNumber;

            if (m_SigHandled == 0)
            {
                if (!get_running_pid())
                {
                    string[] argvp;

                    try
                    {
                        Shell.parse_argv(inCmd, out argvp);
                    }
                    catch (ShellError err)
                    {
                        throw new DisplayError.COMMAND("Invalid %s command !!",
                                                       inCmd);
                    }

                    m_SigHandled = Idle.add(on_wait_is_ready);
                    Os.signal(Os.SIGUSR1, on_sig_usr1);

                    try
                    {
                        Log.info ("launch display command: %s", inCmd);
                        Process.spawn_async(null, argvp, null,
                                            SpawnFlags.SEARCH_PATH |
                                            SpawnFlags.DO_NOT_REAP_CHILD,
                                            on_child_setup, out m_Pid);
                        m_ChildWatch = ChildWatch.add((GLib.Pid)m_Pid, on_m_ChildWatch);
                    }
                    catch (SpawnError err)
                    {
                        GLib.Source.remove(m_SigHandled);
                        m_SigHandled = -1;
                        Os.signal(Os.SIGUSR1, Os.SIG_IGN);
                        throw new DisplayError.LAUNCH(err.message);
                    }
                }
                else
                {
                    m_SigHandled = Idle.add(on_wait_is_ready);
                    s_IsReady = true;
                }
            }
        }

        ~Display ()
        {
            Log.debug ("destroy display");

            kill ();
        }

        private void
        on_child_setup()
        {
            Log.debug ("display child setup");
            Os.signal(Os.SIGUSR1, Os.SIG_IGN);
            Os.signal(Os.SIGINT, Os.SIG_IGN);
            Os.signal(Os.SIGTTIN, Os.SIG_IGN);
            Os.signal(Os.SIGTTOU, Os.SIG_IGN);
        }

        private void
        on_m_ChildWatch(GLib.Pid inPid, int inStatus)
        {
            Log.debug ("display child watch %lu: %i", inPid, inStatus);

            if (m_ChildWatch != 0)
            {
                if (Process.if_exited(inStatus))
                {
                    Log.info ("display exited : %i", inStatus);
                    exited();
                }
                else if (Process.if_signaled(inStatus))
                {
                    Log.info ("display signaled : %i", inStatus);
                    died();
                }

                Process.close_pid(inPid);
                m_Pid = (Pid)0;
                m_XDisplay = null;
                m_ChildWatch = 0;
            }
        }

        private bool
        on_wait_is_ready()
        {
            if (s_IsReady) ready();
            m_SigHandled = 0;
            return !s_IsReady;
        }

        private bool
        get_running_pid()
        {
            if (m_XDisplay == null)
                m_XDisplay = new X.Display (":" + m_Number.to_string ());

            if (m_XDisplay == null)
            {
                m_Pid = 0;
                return false;
            }

            Os.UCred ucr;
            size_t ucr_len = sizeof (Os.UCred);

            if (Os.getsockopt (m_XDisplay.connection_number (), Os.SOL_SOCKET,
                               Os.SO_PEERCRED, out ucr, out ucr_len) == 0 &&
                ucr_len == sizeof (Os.UCred))
            {
                m_Pid = ucr.pid;
                Log.info ("found running display : %lu", m_Pid);
            }

            return m_Pid > 0;
        }

        public string?
        get_device()
        {
            string device = null;

            if (m_XDisplay == null)
                m_XDisplay = new X.Display (":" + m_Number.to_string ());

            if (m_XDisplay != null)
            {
                X.Window root = m_XDisplay.default_root_window ();
                if (root == X.None)
                    return null;

                X.Atom xfree86_vt_atom = m_XDisplay.intern_atom ("XFree86_VT", true);
                if (xfree86_vt_atom == X.None)
                    return null;

                X.Atom return_type_atom;
                int return_format;
                ulong return_count, bytes_left;
                uchar* return_value;

                if (m_XDisplay.get_window_property (root, xfree86_vt_atom, 0L, 1L, false,
                                                    X.XA_INTEGER, out return_type_atom, out return_format,
                                                    out return_count, out bytes_left, out return_value) != X.Success)
                    return null;

                long vt = *(long*)return_value;

                device = "/dev/tty" + vt.to_string();

                Log.info ("open display device %s", device);
                int fd = Os.open(device, Os.O_RDWR);
                if (fd > 0)
                {
                    if (Os.ioctl(fd, Os.KDSETMODE, Os.KD_GRAPHICS) < 0)
                        Log.critical ("KDSETMODE KD_GRAPHICS failed !");
                    if (Os.ioctl(fd, Os.KDSKBMODE, Os.K_RAW) < 0)
                        Log.critical ("KDSETMODE KD_RAW failed !");

                    Os.termios? tty_attr = Os.termios ();
                    Os.ioctl(fd, Os.KDGKBMODE, tty_attr);
                    tty_attr.c_iflag = (Os.IGNPAR | Os.IGNBRK) & (~Os.PARMRK) & (~Os.ISTRIP);
                    tty_attr.c_oflag = 0;
                    tty_attr.c_cflag = Os.CREAD | Os.CS8;
                    tty_attr.c_lflag = 0;
                    tty_attr.c_cc[Os.VTIME]=0;
                    tty_attr.c_cc[Os.VMIN]=1;
                    Os.cfsetispeed(tty_attr, 9600);
                    Os.cfsetospeed(tty_attr, 9600);
                    Os.tcsetattr(fd, Os.TCSANOW, tty_attr);

                    Os.close(fd);
                }
            }
            else
            {
                Log.critical ("cannot open display :%i", m_Number);
            }

            return device;
        }

        public void
        kill ()
        {
            if (m_ChildWatch != 0)
                GLib.Source.remove (m_ChildWatch);
            if ((int)m_Pid > 0)
            {
                Log.debug ("killing display server %lu", m_Pid);
                Os.kill((Os.pid_t)m_Pid, Os.SIGTERM);
            }
        }

        public void
        reload_input_device ()
        {
            if ((int)m_Pid > 0)
            {
                Log.debug ("Reload input devices");
                Os.kill((Os.pid_t)m_Pid, Os.SIGUSR2);
            }
        }
    }
}

