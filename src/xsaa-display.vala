/* xsaa-display.vala
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
        static bool is_ready = false;
        Pid pid = (Pid)0;
        int number;
        
        signal void ready();
        signal void exited();
        signal void died();
        
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
                    signal(SIGUSR1, on_sig_usr1);    

                    try
                    {
                        Process.spawn_async(null, argvp, null, 
                                            SpawnFlags.SEARCH_PATH |
                                            SpawnFlags.DO_NOT_REAP_CHILD, 
                                            on_child_setup, out pid);
                        ChildWatch.add((Pid)pid, on_child_watch);        
                    }
                    catch (SpawnError err)
                    {
                        Source.remove(sig_handled);
                        sig_handled = -1;
                        signal(SIGUSR1, SIG_IGN);
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

        ~Display()
        {
            if ((int)pid > 0) kill((pid_t)pid, SIGTERM);
        }
        
        private void
        on_child_setup()
        {
            signal(SIGTERM,SIG_IGN);
            signal(SIGUSR1, SIG_IGN);
            signal(SIGINT, SIG_IGN);
            signal(SIGTTIN, SIG_IGN);
            signal(SIGTTOU, SIG_IGN);
        }

        private void
        on_child_watch(Pid pid, int status)
        {
            if (Process.if_exited(status))
            {
                stderr.printf("Display exited : %i", status);
                exited();
            }
            else if (Process.if_signaled(status))
            {
                stderr.printf("Display signaled : %i", status);
                died();
            }

            Process.close_pid(pid);
            this.pid = (Pid)0;
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
            if (signum == SIGUSR1)
                is_ready = true;
        }

        private bool
        get_running_pid()
        {
            string spid = null;
            
            try
            {
		        setenv("DISPLAY", ":" + number.to_string(), 1);
                Process.spawn_command_line_sync("/usr/lib/ConsoleKit/ck-get-x11-server-pid", out spid);
		        spid.strip();
		        stderr.printf("Found X server at pid %s\n", spid);
                if (spid != null)
                {
                    pid = (Pid)spid.to_int();
                    return (int)pid > 0;
                }
            }
            catch (GLib.Error err)
            {
                stderr.printf("Error on get display pid: %s\n", err.message);
            }

            return false;
        }

        public string?
        get_device()
        {
            string device = null;
            
            try
            {
                Process.spawn_command_line_sync("/usr/lib/ConsoleKit/ck-get-x11-display-device --display=:" 
                                                + number.to_string(), out device);
		        device.strip();

                int fd = open(device, O_RDWR);
                if (fd > 0)
                {
                    if (ioctl(fd, KDSETMODE, KD_GRAPHICS) < 0)
                        stderr.printf("KDSETMODE KD_GRAPHICS failed !");  
                    if (ioctl(fd, KDSKBMODE, K_RAW) < 0)
                        stderr.printf("KDSETMODE KD_RAW failed !"); 

                    termios tty_attr;
                    ioctl(fd, KDGKBMODE, out tty_attr);
                    tty_attr.c_iflag = (IGNPAR | IGNBRK) & (~PARMRK) & (~ISTRIP);
                    tty_attr.c_oflag = 0;
                    tty_attr.c_cflag = CREAD | CS8;
                    tty_attr.c_lflag = 0;
                    tty_attr.c_cc[VTIME]=0;
                    tty_attr.c_cc[VMIN]=1;
                    cfsetispeed(tty_attr, 9600);
                    cfsetospeed(tty_attr, 9600);
                    tcsetattr(fd, TCSANOW, tty_attr);
                    
                    close(fd);
                }
            }
            catch (GLib.Error err)
            {
                stderr.printf("Error on get display device: %s\n", err.message);
            }

            return device;
        }
    }
}

