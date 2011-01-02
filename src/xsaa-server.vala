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

namespace XSAA
{
    public class Server : Socket
    {
        private static int BUFFER_LENGTH = 200;

        public signal void phase(int val);
        public signal void progress(int val);
        public signal void progress_orientation(Gtk.ProgressBarOrientation orientation);
        public signal void dbus();
        public signal void session();
        public signal void pulse();
        public signal void close_session();
        public signal void quit();

        public Server(string socket_name) throws SocketError
        {
            GLib.debug ("create server: %s", socket_name);

            Posix.unlink(socket_name);

            base(socket_name);

            Posix.fcntl(fd, Posix.F_SETFD, Posix.FD_CLOEXEC);

            if (Posix.bind(fd, &saddr, 110) != 0)
            {
                throw new SocketError.CREATE("error on bind socket");
            }

            if (Posix.listen (fd, 5) != 0)
            {
                throw new SocketError.CREATE("error on listen socket");
            }

            Posix.chmod (socket_name, 0666);

            in.connect(on_client_connect);
        }

        ~Server()
        {
            Posix.unlink(filename);
        }

        private void 
        on_client_connect ()
        {
            GLib.debug ("client connected");

            int client = Posix.accept(fd, null, 0);
            if (client > 0)
            {
                try
                {
                    GLib.debug ("accept client connection");

                    IOChannel ioc = new IOChannel.unix_new(client);
                    ioc.set_encoding(null);
                    ioc.set_buffered(false);
                    ioc.set_flags(ioc.get_flags() | IOFlags.NONBLOCK);
                    ioc.add_watch(IOCondition.IN, on_client_message);
                }
                catch (IOChannelError err)
                {
                    GLib.critical ("error on accept");
                }
            }
        }

        private bool 
        on_client_message (IOChannel client, IOCondition condition)
        {
            GLib.debug ("received client message");

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
                GLib.critical ("error on read socket");
            }
            Posix.close(client.unix_get_fd());

            return false;
        }

        private void 
        handle_client_message(IOChannel client, string buffer)
        {
            GLib.debug ("handle client message");

            if (buffer == "ping")
            {
                GLib.message ("received ping message");
                string message = "pong";
                if (Posix.write(client.unix_get_fd(), message, message.length + 1) == 0)
                    GLib.critical ("error on send pong");
            }
            if (buffer.contains("phase="))
            {
                int val = buffer.split("=")[1].to_int();
                GLib.message ("received phase message: %i", val);
                phase(val);
            }
            if (buffer.contains("progress="))
            {
                int val = buffer.split("=")[1].to_int();
                GLib.message ("received progress message: %i", val);
                progress(val);
            }
            if (buffer == "left-to-right")
            {
                GLib.message ("received left-to-right message");
                progress_orientation(Gtk.ProgressBarOrientation.LEFT_TO_RIGHT);
            }
            if (buffer == "right-to-left")
            {
                GLib.message ("received right-to-left message");
                progress_orientation(Gtk.ProgressBarOrientation.RIGHT_TO_LEFT);
            }
            if (buffer == "pulse")
            {
                GLib.message ("received pulse message");
                pulse();
            }
            if (buffer == "dbus")
            {
                GLib.message ("received dbus message");
                dbus();
            }
            if (buffer == "session")
            {
                GLib.message ("received session message");
                session();
            }
            if (buffer == "close-session")
            {
                GLib.message ("received close session message");
                close_session();
            }
            if (buffer == "quit")
            {
                GLib.message ("received quit message");
                quit();
            }
        }
    }
}
