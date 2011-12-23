/* server.vala
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
    /**
     * Unix socket servver class
     */
    public class Server : Socket
    {
        // static properties
        private static int BUFFER_LENGTH = 1024;

        // signals
        public signal void phase(int inVal);
        public signal void progress(int inVal);
        public signal void dbus();
        public signal void session();
        public signal void pulse();
        public signal void close_session();
        public signal void quit();
        public signal void message(string inMessage);
        public signal void error(string inMessage);
        public signal void fatal_error(string inMessage);

        // methods
        /**
         * Create a new unix server socket
         *
         * @param inSocketName socket name
         *
         * @throws SocketError whene something goes wrong
         */
        public Server(string inSocketName) throws SocketError
        {
            Log.debug ("create server: %s", inSocketName);

            GLib.FileUtils.unlink(inSocketName);

            base(inSocketName);

            Os.fcntl(fd, Os.F_SETFD, Os.FD_CLOEXEC);

            Os.SockAddrUn addr = saddr;
            if (Os.bind(fd, &addr, 110) != 0)
            {
                throw new SocketError.CREATE("error on bind socket");
            }

            if (Os.listen (fd, 5) != 0)
            {
                throw new SocketError.CREATE("error on listen socket");
            }

            GLib.FileUtils.chmod (inSocketName, 0666);

            in.connect(on_client_connect);
        }

        ~Server()
        {
            GLib.FileUtils.unlink(filename);
        }

        private void
        on_client_connect ()
        {
            Log.debug ("client connected");

            int client = Os.accept(fd, null, 0);
            if (client > 0)
            {
                try
                {
                    Log.debug ("accept client connection");

                    IOChannel ioc = new IOChannel.unix_new(client);
                    ioc.set_encoding(null);
                    ioc.set_buffered(false);
                    ioc.set_flags(ioc.get_flags() | IOFlags.NONBLOCK);
                    ioc.add_watch(IOCondition.IN, on_client_message);
                }
                catch (IOChannelError err)
                {
                    Log.critical ("error on accept");
                }
            }
        }

        private bool
        on_client_message (GLib.IOChannel inClient, GLib.IOCondition inCondition)
        {
            Log.debug ("received client message");

            char[] buffer = new char[BUFFER_LENGTH];
            size_t bytes_read = 0;

            try
            {
                inClient.read_chars(buffer, out bytes_read);
                if (bytes_read > 0 && bytes_read < BUFFER_LENGTH)
                {
                    buffer[bytes_read] = (char)0;
                    Log.debug ("received: %s", (string)buffer);
                    Message message = new Message ((string)buffer);
                    if (message != null)
                    {
                        handle_client_message(inClient, message);
                    }
                }
            }
            catch (GLib.Error err)
            {
                Log.critical ("error on read socket");
            }
            Os.close(inClient.unix_get_fd());

            return false;
        }

        private void
        handle_client_message(GLib.IOChannel inClient, Message inMessage)
        {
            Log.debug ("handle client message");

            switch (inMessage.message_type)
            {
                case MessageType.PING:
                {
                    Log.info ("received ping message");
                    Message message = new Message.pong ();
                    if (Os.write(inClient.unix_get_fd(), message.raw, message.raw.length + 1) == 0)
                        Log.critical ("error on send pong");
                }
                break;

                case MessageType.PHASE:
                {
                    int val = int.parse (inMessage.data);
                    Log.info ("received phase message: %i", val);
                    phase(val);
                }
                break;

                case MessageType.PROGRESS:
                {
                    int val = int.parse (inMessage.data);
                    Log.info ("received progress message: %i", val);
                    progress(val);
                }
                break;

                case MessageType.PULSE:
                {
                    Log.info ("received pulse message");
                    pulse();
                }
                break;

                case MessageType.DBUS:
                {
                    Log.info ("received dbus message");
                    dbus();
                }
                break;

                case MessageType.SESSION:
                {
                    Log.info ("received session message");
                    session();
                }
                break;

                case MessageType.CLOSE_SESSION:
                {
                    Log.info ("received close session message");
                    close_session();
                }
                break;

                case MessageType.QUIT:
                {
                    Log.info ("received quit message");
                    quit();
                }
                break;

                case MessageType.MESSAGE:
                {
                    Log.info ("received message message: %s", inMessage.data);
                    message(inMessage.data);
                }
                break;

                case MessageType.ERROR:
                {
                    Log.info ("received error message: %s", inMessage.data);
                    error(inMessage.data);
                }
                break;

                case MessageType.FATAL_ERROR:
                {
                    Log.info ("received fatal error message: %s", inMessage.data);
                    fatal_error(inMessage.data);
                }
                break;

                default:
                    Log.warning ("Received an invalid message");
                    break;
            }
        }
    }
}

