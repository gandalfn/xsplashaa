/* xsaa-socket.vala
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

using GLib;
using Gtk;
using Posix;

namespace XSAA
{
    public errordomain SocketError
    {
        INVALID_NAME,
        CREATE
    }

    public class Socket : GLib.Object
    {
        private static int BUFFER_LENGTH = 200;

        protected string filename;
        protected int fd = 0;
        protected sockaddr_un saddr;
        protected IOChannel ioc;

        public signal void @in();

        public Socket(string socket_name) throws SocketError
        {
            int state = 1;

            if (socket_name.len() == 0)
            {
                this.unref();
                throw new SocketError.INVALID_NAME("error socket name is empty");
            }
            filename = socket_name;
            
            fd = socket(PF_UNIX, SOCK_STREAM, 0);
            if (fd < 0)
            {
                this.unref();
                throw new SocketError.CREATE("error on create socket %s", 
                                             socket_name);
            }

            if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, 
                           &state, sizeof(int)) != 0)
            {
                this.unref();
                throw new SocketError.CREATE("error on setsockopt socket %s", 
                                             socket_name);
            }

            saddr = sockaddr_un();
            saddr.sun_family = AF_UNIX;
            memcpy(saddr.sun_path, socket_name, socket_name.len());

            try
            {
                ioc = new IOChannel.unix_new(fd);
                ioc.set_encoding(null);
                ioc.set_buffered(false);
                ioc.add_watch(IOCondition.IN, on_in_data);
            }
            catch (GLib.Error err)
            {
                this.unref();
                throw new SocketError.CREATE("error on create stream %s", 
                                             err.message);
            }
        }

        ~Socket()
        {
            if (fd > 0) close(fd);
        }

        private bool
        on_in_data(IOChannel client, IOCondition condition)
        {
            in();

            return true;
        }

        public bool
        send(string message)
        {
            return write (fd, message, message.len() + 1) > 0;
        }

        public bool
        recv(out string message)
        {
            char[] buffer = new char[BUFFER_LENGTH];
            size_t bytes_read = 0;

            try
            {
                ioc.read_chars(buffer, out bytes_read);
                if (bytes_read > 0 && bytes_read < 200)
                {
                    buffer[bytes_read] = (char)0;
                    message = (string)buffer;
                    return true;
                }
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on read socket\n");
            }

            return false;
        }
    }
}
