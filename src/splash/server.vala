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
        // static properties
        private static int BUFFER_LENGTH = 200;

        // signals
        public signal void phase(int inVal);
        public signal void progress(int inVal);
        public signal void progress_orientation(Gtk.ProgressBarOrientation inOrientation);
        public signal void dbus();
        public signal void session();
        public signal void pulse();
        public signal void close_session();
        public signal void quit();

        // methods
        public Server(string inSocketName) throws SocketError
        {
            GLib.debug ("create server: %s", inSocketName);

            GLib.FileUtils.unlink(inSocketName);

            base(inSocketName);

            Os.fcntl(m_Fd, Os.F_SETFD, Os.FD_CLOEXEC);

            if (Os.bind(m_Fd, &m_SAddr, 110) != 0)
            {
                throw new SocketError.CREATE("error on bind socket");
            }

            if (Os.listen (m_Fd, 5) != 0)
            {
                throw new SocketError.CREATE("error on listen socket");
            }

            GLib.FileUtils.chmod (inSocketName, 0666);

            in.connect(on_client_connect);
        }

        ~Server()
        {
            GLib.FileUtils.unlink(m_Filename);
        }

        private void
        on_client_connect ()
        {
            GLib.debug ("client connected");

            int client = Os.accept(m_Fd, null, 0);
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
        on_client_message (GLib.IOChannel inClient, GLib.IOCondition inCondition)
        {
            GLib.debug ("received client message");

            char[] buffer = new char[BUFFER_LENGTH];
            size_t bytes_read = 0;

            try
            {
                inClient.read_chars(buffer, out bytes_read);
                if (bytes_read > 0 && bytes_read < 200)
                {
                    buffer[bytes_read] = (char)0;
                    handle_client_message(inClient, (string)buffer);
                }
            }
            catch (GLib.Error err)
            {
                GLib.critical ("error on read socket");
            }
            Os.close(inClient.unix_get_fd());

            return false;
        }

        private void
        handle_client_message(GLib.IOChannel inClient, string inBuffer)
        {
            GLib.debug ("handle client message");

            if (inBuffer == "ping")
            {
                GLib.message ("received ping message");
                string message = "pong";
                if (Os.write(inClient.unix_get_fd(), message, message.length + 1) == 0)
                    GLib.critical ("error on send pong");
            }
            if (inBuffer.contains("phase="))
            {
                int val = int.parse (inBuffer.split("=")[1]);
                GLib.message ("received phase message: %i", val);
                phase(val);
            }
            if (inBuffer.contains("progress="))
            {
                int val = int.parse (inBuffer.split("=")[1]);
                GLib.message ("received progress message: %i", val);
                progress(val);
            }
            if (inBuffer == "left-to-right")
            {
                GLib.message ("received left-to-right message");
                progress_orientation(Gtk.ProgressBarOrientation.LEFT_TO_RIGHT);
            }
            if (inBuffer == "right-to-left")
            {
                GLib.message ("received right-to-left message");
                progress_orientation(Gtk.ProgressBarOrientation.RIGHT_TO_LEFT);
            }
            if (inBuffer == "pulse")
            {
                GLib.message ("received pulse message");
                pulse();
            }
            if (inBuffer == "dbus")
            {
                GLib.message ("received dbus message");
                dbus();
            }
            if (inBuffer == "session")
            {
                GLib.message ("received session message");
                session();
            }
            if (inBuffer == "close-session")
            {
                GLib.message ("received close session message");
                close_session();
            }
            if (inBuffer == "quit")
            {
                GLib.message ("received quit message");
                quit();
            }
        }
    }
}
