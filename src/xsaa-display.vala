/* xsaa-display.vala
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
    errordomain DisplayError
    {
        COMMAND,
        LAUNCH
    }

    class Display : GLib.Object
    {
        uint sig_handled = 0;
        uint child_watch = 0;
        static bool is_ready = false;
        Pid pid = (Pid)0;
        int number;
        X.Display xdisplay = null;

        public signal void ready();
        public signal void exited();
        public signal void died();

        public Display(string cmd, int number) throws DisplayError
        {
            this.number = number;

            if (sig_handled == 0)
            {
                if (!get_running_pid())
                {
                    string[] argvp;

                    try
                    {
                        Shell.parse_argv(cmd, out argvp);
                    }
                    catch (ShellError err)
                    {
                        throw new DisplayError.COMMAND("Invalid %s command !!", 
                                                       cmd);
                    }

                    sig_handled = Idle.add(on_wait_is_ready);
                    Posix.signal(Posix.SIGUSR1, on_sig_usr1);

                    try
                    {
                        Process.spawn_async(null, argvp, null, 
                                            SpawnFlags.SEARCH_PATH |
                                            SpawnFlags.DO_NOT_REAP_CHILD, 
                                            on_child_setup, out pid);
                        child_watch = ChildWatch.add((Pid)pid, on_child_watch);
                    }
                    catch (SpawnError err)
                    {
                        GLib.Source.remove(sig_handled);
                        sig_handled = -1;
                        Posix.signal(Posix.SIGUSR1, Posix.SIG_IGN);
                        throw new DisplayError.LAUNCH(err.message);
                    }
                }
                else
                {
                    sig_handled = Idle.add(on_wait_is_ready);
                    is_ready = true;
                }
            }
        }
        
        ~Display ()
        {
            kill ();
        }

        private void
        on_child_setup()
        {
            Posix.signal(Posix.SIGUSR1, Posix.SIG_IGN);
            Posix.signal(Posix.SIGINT, Posix.SIG_IGN);
            Posix.signal(Posix.SIGTTIN, Posix.SIG_IGN);
            Posix.signal(Posix.SIGTTOU, Posix.SIG_IGN);
        }

        private void
        on_child_watch(Pid pid, int status)
        {
            if (child_watch != 0)
            {
                if (Process.if_exited(status))
                {
                    GLib.stderr.printf("Display exited : %i\n", status);
                    exited();
                }
                else if (Process.if_signaled(status))
                {
                    GLib.stderr.printf("Display signaled : %i\n", status);
                    died();
                }

                Process.close_pid(pid);
                this.pid = (Pid)0;
                this.xdisplay = null;
                child_watch = 0;
            }
        }

        private bool
        on_wait_is_ready()
        {
            if (is_ready) ready();
            sig_handled = 0;
            return !is_ready;
        }

        static void
        on_sig_usr1(int signum)
        {
            if (signum == Posix.SIGUSR1)
                is_ready = true;
        }

        private bool
        get_running_pid()
        {
            if (xdisplay == null)
                xdisplay = new X.Display (":" + number.to_string ());

            if (xdisplay == null)
            {
                pid = 0;
                return false;
            }

            Posix.UCred ucr;
            size_t ucr_len = sizeof (Posix.UCred);

            if (Posix.getsockopt (xdisplay.connection_number (),
                                  Posix.SOL_SOCKET, Posix.SO_PEERCRED,
                                  out ucr, out ucr_len) == 0 &&
                ucr_len == sizeof (Posix.UCred))
            {
                pid = ucr.pid;
                GLib.stderr.printf("Found running display : %i\n", pid);
            }

            return pid > 0;
        }

        public string?
        get_device()
        {
            string device = null;

            if (xdisplay == null)
                xdisplay = new X.Display (":" + number.to_string ());

            if (xdisplay != null)
            {
                X.Window root = xdisplay.default_root_window ();
                if (root == X.None)
                    return null;

                X.Atom xfree86_vt_atom = xdisplay.intern_atom ("XFree86_VT", true);
                if (xfree86_vt_atom == X.None)
                    return null;

                X.Atom return_type_atom;
                int return_format;
                ulong return_count, bytes_left;
                uchar* return_value;

                if (xdisplay.get_window_property (root, xfree86_vt_atom, 0L, 1L, false,
                                                  X.XA_INTEGER, out return_type_atom, out return_format,
                                                  out return_count, out bytes_left, out return_value) != X.Success)
                    return null;

                long vt = *(long*)return_value;

                device = "/dev/tty" + vt.to_string();

                GLib.stderr.printf ("Open device %s\n", device);
                int fd = Posix.open(device, Posix.O_RDWR);
                if (fd > 0)
                {
                    if (Posix.ioctl(fd, Posix.KDSETMODE, Posix.KD_GRAPHICS) < 0)
                        GLib.stderr.printf("KDSETMODE KD_GRAPHICS failed !");  
                    if (Posix.ioctl(fd, Posix.KDSKBMODE, Posix.K_RAW) < 0)
                        GLib.stderr.printf("KDSETMODE KD_RAW failed !"); 

                    Posix.termios? tty_attr = Posix.termios ();
                    Posix.ioctl(fd, Posix.KDGKBMODE, tty_attr);
                    tty_attr.c_iflag = (Posix.IGNPAR | Posix.IGNBRK) & (~Posix.PARMRK) & (~Posix.ISTRIP);
                    tty_attr.c_oflag = 0;
                    tty_attr.c_cflag = Posix.CREAD | Posix.CS8;
                    tty_attr.c_lflag = 0;
                    tty_attr.c_cc[Posix.VTIME]=0;
                    tty_attr.c_cc[Posix.VMIN]=1;
                    Posix.cfsetispeed(tty_attr, 9600);
                    Posix.cfsetospeed(tty_attr, 9600);
                    Posix.tcsetattr(fd, Posix.TCSANOW, tty_attr);

                    Posix.close(fd);
                }
            }

            return device;
        }

        public void
        kill ()
        {
            if (child_watch != 0)
                GLib.Source.remove (child_watch);
            if ((int)pid > 0)
            {
                GLib.stderr.printf ("Killing Xorg %i\n", (int)pid);
                Posix.kill((Posix.pid_t)pid, Posix.SIGTERM);
            }
        }
    }
}

