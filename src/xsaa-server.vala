/* xsaa-server.vala
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
    public class Server : Socket
    {
        private static int BUFFER_LENGTH = 200;

        public signal void phase(int val);
        public signal void progress(int val);
        public signal void progress_orientation(ProgressBarOrientation orientation);
        public signal void dbus();
        public signal void session();
        public signal void pulse();
        public signal void close_session();
        public signal void quit();

        public Server(string socket_name) throws SocketError
        {
            unlink(socket_name);

            base(socket_name);

            fcntl(fd, F_SETFD, FD_CLOEXEC);

            if (bind(fd, ref saddr, 110) != 0)
            {
                this.unref();
                throw new SocketError.CREATE("error on bind socket");
            }

            if (listen (fd, 5) != 0)
            {
                this.unref();
                throw new SocketError.CREATE("error on listen socket");
            }

            chmod (socket_name, 0666);

            in.connect(on_client_connect);
        }

        ~Server()
        {
            unlink(filename);
        }

        private void 
        on_client_connect ()
        {
            int client = accept(fd, null, 0);
            if (client > 0)
            {
                try
                {
                    IOChannel ioc = new IOChannel.unix_new(client);
                    ioc.set_encoding(null);
                    ioc.set_buffered(false);
                    ioc.set_flags(ioc.get_flags() | IOFlags.NONBLOCK);
                    ioc.add_watch(IOCondition.IN, on_client_message);
                }
                catch (IOChannelError err)
                {
                    GLib.stderr.printf("Error on accept\n");
                }
            }
        }

        private bool 
        on_client_message (IOChannel client, IOCondition condition)
        {
            char[] buffer = new char[BUFFER_LENGTH];
            size_t bytes_read = 0;

            try
            {
                client.read_chars(buffer, out bytes_read);
                if (bytes_read > 0 && bytes_read < 200)
                {
                    buffer[bytes_read] = (char)0;
                    handle_client_message(client, (string)buffer);
                }
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on read socket\n");
            }
            close(client.unix_get_fd());

            return false;
        }

        private void 
        handle_client_message(IOChannel client, string buffer)
        {
            if (buffer == "ping")
            {
                string message = "pong";
                if (write(client.unix_get_fd(), message, message.len() + 1) == 0)
                    GLib.stderr.printf("Error on send pong");
            }
            if (buffer.contains("phase="))
            {
                int val = buffer.split("=")[1].to_int();
                phase(val);
            }
            if (buffer.contains("progress="))
            {
                int val = buffer.split("=")[1].to_int();
                progress(val);
            }
            if (buffer == "left-to-right")
            {
                progress_orientation(ProgressBarOrientation.LEFT_TO_RIGHT);
            }
            if (buffer == "right-to-left")
            {
                progress_orientation(ProgressBarOrientation.RIGHT_TO_LEFT);
            }
            if (buffer == "pulse")
            {
                pulse();
            }
            if (buffer == "dbus")
            {
                dbus();
            }
            if (buffer == "session")
            {
                session();
            }
            if (buffer == "close-session")
            {
                close_session();
            }
            if (buffer == "quit")
            {
                quit();
            }
        }
    }
}
