/* socket.vala
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
    public errordomain SocketError
    {
        INVALID_NAME,
        CREATE
    }

    /**
     * Socket class
     */
    public class Socket : GLib.Object
    {
        // properties
        private static int     BUFFER_LENGTH = 1024;
        private string         m_Filename;
        private int            m_Fd = 0;
        private Os.SockAddrUn  m_SAddr;
        private GLib.IOChannel m_Channel;

        // accessors
        /**
         * Unix socket filename
         */
        public string filename {
            get {
                return m_Filename;
            }
        }

        /**
         * Unix socket file descriptor
         */
        public int fd {
            get {
                return m_Fd;
            }
        }

        /**
         * Socket adress
         */
        public unowned Os.SockAddrUn? saddr {
            get {
                return m_SAddr;
            }
        }

        // signals
        public signal void @in();

        // methods
        /**
         * Create a new socket
         *
         * @param inSocketName socket name
         *
         * @throws SocketError if something goes wrong
         */
        public Socket(string inSocketName) throws SocketError
        {
            int state = 1;

            if (inSocketName.length == 0)
            {
                throw new SocketError.INVALID_NAME("error socket name is empty");
            }
            m_Filename = inSocketName;

            m_Fd = Os.socket(Os.PF_UNIX, Os.SOCK_STREAM, 0);
            if (m_Fd < 0)
            {
                throw new SocketError.CREATE("error on create socket %s",
                                             inSocketName);
            }

            if (Os.setsockopt(m_Fd, Os.SOL_SOCKET, Os.SO_REUSEADDR, out state, sizeof(int)) != 0)
            {
                throw new SocketError.CREATE("error on setsockopt socket %s",
                                             inSocketName);
            }

            m_SAddr = Os.SockAddrUn();
            m_SAddr.sun_family = Os.AF_UNIX;
            GLib.Memory.copy(m_SAddr.sun_path, inSocketName, inSocketName.length);

            try
            {
                m_Channel = new IOChannel.unix_new(m_Fd);
                m_Channel.set_encoding(null);
                m_Channel.set_buffered(false);
                m_Channel.add_watch(IOCondition.IN, () => {
                    in ();
                    return true;
                });
            }
            catch (GLib.Error err)
            {
                throw new SocketError.CREATE("error on create stream %s",
                                             err.message);
            }
        }

        ~Socket()
        {
            if (m_Fd > 0) Os.close(m_Fd);
        }

        /**
         * Send a message on socket
         *
         * @param inMessage message to send
         *
         * @return ``true`` on success
         */
        public bool
        send (Message inMessage)
        {
            return Os.write (m_Fd, inMessage.raw, inMessage.raw.length + 1) > 0;
        }

        /**
         * Receive a message from socket
         *
         * @param outMessage the message received
         *
         * @return ``true`` if a message has been received
         */
        public bool
        recv (out Message outMessage)
        {
            char[] buffer = new char[BUFFER_LENGTH];
            size_t bytes_read = 0;

            try
            {
                m_Channel.read_chars(buffer, out bytes_read);
                if (bytes_read > 0 && bytes_read < BUFFER_LENGTH)
                {
                    buffer[bytes_read] = (char)0;
                    outMessage = new Message ((string)buffer);
                    return outMessage != null;
                }
            }
            catch (GLib.Error err)
            {
                Log.critical ("error on read socket");
            }

            return false;
        }
    }
}

