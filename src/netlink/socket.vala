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

namespace XSAA.Netlink
{
    public errordomain SocketError
    {
        CREATE,
        RECV,
        SEND
    }

    /**
     * Rt Netlink socket management, provide a way to talk with kernel trought
     * Netlink socket
     */
    public class Socket : GLib.Object
    {
        // properties
        private int            m_Fd;
        private Os.SockAddrNl  m_Local;
        private uint32         m_Seq;
        private GLib.IOChannel m_Channel;
        private uint           m_IdWatch;

        // accessors
        public int fd {
            get {
                return m_Fd;
            }
        }

        public uint32 seq {
            get {
                return m_Seq;
            }
            set {
                m_Seq = value;
            }
        }

        // signals
        public signal void @in();

        // static methods
        public static inline uint32
        group (uint32 inGroup)
            requires (inGroup <= 31)
        {
            return inGroup > 0 ? (1 << (inGroup - 1)) : 0;
        }

        // methods
        /**
         * Create a new RTNetlink socket
         */
        public Socket (uint32 inSubscriptions) throws SocketError
        {
            m_Fd = Os.socket(Linux.Socket.AF_NETLINK, Os.SOCK_RAW, Linux.Netlink.NETLINK_GENERIC);
            if (m_Fd < 0)
                throw new SocketError.CREATE ("Cannot open netlink socket");

            int sndbuf = 32768;
            if (Os.setsockopt (m_Fd, Os.SOL_SOCKET, Os.SO_SNDBUF, ref sndbuf, sizeof(int)) < 0)
                throw new SocketError.CREATE ("SO_SNDBUF");

            int rcvbuf = 32768;
            if (Os.setsockopt (m_Fd, Os.SOL_SOCKET, Os.SO_RCVBUF, ref rcvbuf, sizeof(int)) < 0)
                throw new SocketError.CREATE ("SO_RCVBUF");

            m_Local.nl_family = Linux.Socket.AF_NETLINK;
            m_Local.nl_groups = inSubscriptions;
            unowned Os.SockAddr? addr = m_Local;
            if (Os.bind(m_Fd, addr, sizeof (Os.SockAddrNl)) < 0)
                throw new SocketError.CREATE ("Cannot bind netlink socket");

            size_t addr_len = sizeof (Os.SockAddrNl);
            if (Os.getsockname(m_Fd, addr, ref addr_len) < 0)
                throw new SocketError.CREATE ("Cannot getsockname");

            if (addr_len != sizeof(Os.SockAddrNl))
                throw new SocketError.CREATE ("Wrong address length %d\n", addr_len);

            if (m_Local.nl_family != Linux.Socket.AF_NETLINK)
                throw new SocketError.CREATE ("Wrong address family %d\n", m_Local.nl_family);

            m_Seq = (uint32)time_t();

            try
            {
                m_Channel = new GLib.IOChannel.unix_new (m_Fd);
                m_Channel.set_encoding(null);
                m_Channel.set_buffered(false);
                m_IdWatch = m_Channel.add_watch(GLib.IOCondition.IN | GLib.IOCondition.PRI, () => {
                    if (m_IdWatch != 0)
                    {
                        in ();
                    }
                    return m_IdWatch != 0;
                });
            }
            catch (GLib.Error err)
            {
                throw new SocketError.CREATE("error on create stream %s", err.message);
            }
        }

        ~Socket ()
        {
            if (m_IdWatch != 0) GLib.Source.remove (m_IdWatch);
            m_IdWatch = 0;
            if (m_Fd > 0) Os.close (m_Fd);
        }

        public void
        recv (ref Message inoutMessage) throws SocketError
        {
            inoutMessage.recv (this);
        }

        public void
        send (Message inMessage) throws SocketError
        {
            m_Seq++;
            inMessage.send (this);
        }
    }
}
