/* message.vala
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
    /**
     * Netlink socket message
     */
    public class Message<T> : GLib.Object
    {
        // types
        public enum ControlCommand
        {
            UNSPEC,
            NEWFAMILY,
            DELFAMILY,
            GETFAMILY,
            NEWOPS,
            DELOPS,
            GETOPS,
            NEWMCAST_GRP,
            DELMCAST_GRP,
            GETMCAST_GRP
        }

        public enum ControlAttribute
        {
            UNSPEC,
            FAMILY_ID,
            FAMILY_NAME,
            VERSION,
            HDRSIZE,
            MAXATTR,
            OPS,
            MCAST_GROUPS
        }

        private enum ControlAttributeMCastGrp
        {
            UNSPEC,
            NAME,
            ID
        }

        private enum AcpiGenlAttribute
        {
            UNSPEC,
            EVENT
        }

        public class Header : GLib.Object
        {
            // properties
            private unowned Os.NlMsgHdr? m_Msg;
            private Linux.Netlink.RtAttr*[] m_Attribs;

            // accessors
            internal size_t len {
                get {
                    return Os.NLMSG_ALIGN (m_Msg.nlmsg_len);
                }
            }

            internal virtual size_t length {
                get {
                    return (size_t)Os.NLMSG_ALIGN ((int)sizeof(Os.NlMsgHdr));
                }
            }

            internal unowned Os.NlMsgHdr? msg {
                get {
                    return m_Msg;
                }
                private set {
                    m_Msg = value;
                }
            }

            internal virtual void* data {
                set {
                    m_Msg = (Os.NlMsgHdr?)value;

                    int l = (int)m_Msg.nlmsg_len - Linux.Netlink.NLMSG_LENGTH ((int)length);
                    void* ptr = (void*)Os.NLMSG_DATA (m_Msg);
                    Linux.Netlink.RtAttr* attrs = (Linux.Netlink.RtAttr*)((char*)ptr + length);
                    while (Linux.Netlink.RTA_OK (attrs, l))
                    {
                        if (m_Attribs.length <= attrs->rta_type)
                            m_Attribs.resize (attrs->rta_type + 1);
                        m_Attribs [attrs->rta_type] = attrs;
                        attrs = Linux.Netlink.RTA_NEXT (attrs, l);
                    }
                }
            }

            // methods
            construct
            {
                m_Attribs = {};
            }

            internal Header (Os.NlMsgHdr? inMsgHeader)
            {
                m_Msg = inMsgHeader;
            }

            private inline unowned Linux.Netlink.RtAttr?
            tail ()
            {
                void* ptr = (void*)m_Msg;
                return (Linux.Netlink.RtAttr?)((char*)ptr + len);
            }

            internal void
            add_attribute_l (int inType, char[] inData)
            {
                int l = Linux.Netlink.RTA_LENGTH (inData.length + 1);
                unowned Linux.Netlink.RtAttr? rta = tail ();

                rta.rta_type = (ushort)inType;
                rta.rta_len = (ushort)l;
                GLib.Memory.copy (Linux.Netlink.RTA_DATA ((Linux.Netlink.RtAttr*)rta), inData, inData.length + 1);
                m_Msg.nlmsg_len = (uint32)len + Os.RTA_ALIGN (l);
            }

            public bool
            contains (int inType)
            {
                return m_Attribs.length > inType && m_Attribs[inType] != null;
            }

            public new void*
            @get (int inType)
            {
                void* ret = null;

                if (inType < m_Attribs.length)
                {
                    Linux.Netlink.RtAttr* rta = m_Attribs[inType];

                    if (rta != null)
                    {
                        ret = Linux.Netlink.RTA_DATA (rta);
                    }
                }

                return ret;
            }

            internal int
            get_payload (int inType)
            {
                int ret = 0;
                if (inType < m_Attribs.length)
                {
                    Linux.Netlink.RtAttr* rta = m_Attribs[inType];

                    if (rta != null)
                    {
                        ret = Os.RTA_PAYLOAD (rta);
                    }
                }
                return ret;
            }
        }

        public class HeaderGenl : Header
        {
            // types
            private struct GenlMsg
            {
                public Os.NlMsgHdr header;
                public uint8       data[4096];
            }

            private struct GenlMsgHdr
            {
                public uint8  cmd;
                public uint8  version;
                public uint16 reserved;
            }

            // properties
            private GenlMsg m_Msg;
            private GLib.HashTable<string, uint32?> m_MCastGroups;

            // accessors
            internal override void* data {
                set {
                    base.data = value;

                    if (ControlAttribute.MCAST_GROUPS in this)
                    {
                        parse_mcast_groups ();
                    }
                }
            }

            internal override size_t length {
                get {
                    return (size_t)Os.NLMSG_ALIGN ((int)sizeof(GenlMsgHdr));
                }
            }

            // methods
            construct
            {
                m_MCastGroups = new GLib.HashTable<string, uint32?> (GLib.str_hash, GLib.str_equal);
            }

            internal HeaderGenl ()
            {
                base (null);

                m_Msg = GenlMsg ();
                msg = m_Msg.header;
            }

            internal HeaderGenl.get_family (string inFamilyName)
            {
                this ();

                m_Msg.header.nlmsg_len = Linux.Netlink.NLMSG_LENGTH ((int)length);
                m_Msg.header.nlmsg_flags = (uint16)(Linux.Netlink.NLM_F_REQUEST | Linux.Netlink.NLM_F_ACK);
                m_Msg.header.nlmsg_type = (uint16)Linux.Netlink.NLMSG_MIN_TYPE;

                GenlMsgHdr ghdr = GenlMsgHdr ();
                ghdr.cmd = ControlCommand.GETFAMILY;
                GLib.Memory.copy (Os.NLMSG_DATA (m_Msg.header), &ghdr, length);

                add_attribute_l (ControlAttribute.FAMILY_NAME, inFamilyName.to_utf8 ());
            }

            private void
            add_mcast_group (Linux.Netlink.RtAttr* inAttrs)
            {
                Linux.Netlink.RtAttr* attrs = Linux.Netlink.RTA_DATA (inAttrs);
                int l = Os.RTA_PAYLOAD (inAttrs);
                string name = null;
                uint32 id = 0;

                Log.debug ("parse mcast group %i", l);
                while (Linux.Netlink.RTA_OK (attrs, l))
                {
                    if (attrs->rta_type == ControlAttributeMCastGrp.NAME)
                    {
                        name = "%s".printf ((string)Linux.Netlink.RTA_DATA (attrs));
                    }
                    if (attrs->rta_type == ControlAttributeMCastGrp.ID)
                    {
                        uint32? val = (uint32?)Linux.Netlink.RTA_DATA (attrs);
                        id = val;
                    }
                    attrs = Linux.Netlink.RTA_NEXT (attrs, l);
                }

                if (name != null)
                {
                    Log.debug ("Add mcast group %s %lu", name, id);
                    m_MCastGroups.insert (name, id);
                }
            }

            private void
            parse_mcast_groups ()
            {
                Linux.Netlink.RtAttr* attrs = this[ControlAttribute.MCAST_GROUPS];
                int l = get_payload (ControlAttribute.MCAST_GROUPS);
                Log.debug ("found mcast groups attribute parse it %i", l);

                while (Linux.Netlink.RTA_OK (attrs, l))
                {
                    Log.debug ("add mcast groups %i", attrs->rta_type);
                    add_mcast_group (attrs);
                    attrs = Linux.Netlink.RTA_NEXT (attrs, l);
                }
            }

            public uint32?
            get_mcast_group (string inGroupName)
            {
                return m_MCastGroups.lookup (inGroupName);
            }
        }

        public class HeaderGenlAcpi : HeaderGenl
        {
            // types
            private struct AcpiGenlEvent
            {
                public char   device_class[20];
                public char   bus_id[15];
                public uint32 type;
                public uint32 data;
            }

            // properties
            private unowned AcpiGenlEvent? m_Event = null;

            // accessors
            public string? event_device_class {
                owned get {
                    return m_Event == null ? null : "%s".printf ((string)m_Event.device_class);
                }
            }

            public string? event_bus_id {
                owned get {
                    return m_Event == null ? null : "%s".printf ((string)m_Event.bus_id);
                }
            }

            public uint32 event_type {
                get {
                    return m_Event == null ? 0 : m_Event.type;
                }
            }

            public uint32 event_data {
                get {
                    return m_Event == null ? 0 : m_Event.data;
                }
            }

            internal override void* data {
                set {
                    base.data = value;

                    acpi_init ();
                    if (msg.nlmsg_type == sFamilyId && AcpiGenlAttribute.EVENT in this)
                    {
                        m_Event = (AcpiGenlEvent?)this [AcpiGenlAttribute.EVENT];
                        Log.debug ("acpi event %s %s %lu %u", event_device_class, event_bus_id, event_type, event_data);
                    }
                }
            }
        }

        public class Iterator<T> : GLib.Object
        {
            private unowned Message<T>?  m_Message;
            private unowned Os.NlMsgHdr? m_Current;
            private size_t               m_Size;

            internal Iterator (Message<T> inMessage)
            {
                m_Message = inMessage;
                m_Current = null;
                m_Size    = m_Message.m_Size;
            }

            public bool
            next ()
            {
                bool ret = false;

                if (m_Size > 0)
                {
                    if (m_Current == null)
                    {
                        m_Current = (Os.NlMsgHdr?)m_Message.m_Data;
                    }
                    else
                    {
                        uint32 len = Os.NLMSG_ALIGN (m_Current.nlmsg_len);
                        m_Current = (Os.NlMsgHdr?)((char*)m_Current + len);
                    }
                    m_Size -= Os.NLMSG_ALIGN (m_Current.nlmsg_len);
                    ret = true;
                }

                return ret;
            }

            public new T
            @get ()
            {
                return (T)GLib.Object.new (typeof (T), data: m_Current);
            }
        }

        // properties
        private Os.SockAddrNl  m_Addr;
        private Os.MsgHdr      m_Msg;
        private Posix.iovector m_Vector[1];
        private uint8[]        m_Data;
        private size_t         m_Size = 0;

        // static properties
        private static uint32? sFamilyId = null;
        private static uint32? sMCastGroup = null;

        // static methods
        private static void
        acpi_init ()
        {
            if (sFamilyId == null || sMCastGroup == null)
            {
                try
                {
                    Socket socket = new Socket (0);
                    Message<Header> message = new Message<Header>.get_family ("acpi_event");
                    socket.send (message);
                    Message<HeaderGenl> recv = new Message<HeaderGenl>.raw (16384);
                    socket.recv (ref recv);

                    foreach (HeaderGenl msg in recv)
                    {
                        if (ControlAttribute.FAMILY_ID in msg)
                        {
                            sFamilyId = (uint32?)msg[ControlAttribute.FAMILY_ID];
                            Log.debug ("family id: %lu", sFamilyId);
                        }

                        if (ControlAttribute.MCAST_GROUPS in msg)
                        {
                            sMCastGroup = msg.get_mcast_group ("acpi_mc_group");
                            Log.debug ("mcast groups: %lu", sMCastGroup);
                        }
                    }
                }
                catch (SocketError err)
                {
                    Log.critical ("error on initialize acpi netlink: %s", err.message);
                }
            }
        }

        public static uint32?
        acpi_group ()
        {
            acpi_init ();
            return sMCastGroup;
        }

        // methods
        /**
         * Create a new socket message
         *
         * @param inMsg netlink message header
         * @param inPid pid of sender
         * @param inGroups dest netlink group
         */
        public Message (Header inMsg, GLib.Pid inPid, uint inGroups)
        {
            this.raw ((int)inMsg.len);

            unowned Os.NlMsgHdr? msg = inMsg.msg;

            GLib.Memory.copy (m_Data, (void*)msg, sizeof (Os.NlMsgHdr));
            m_Addr.nl_pid = inPid;
            m_Addr.nl_groups = inGroups;
        }

        /**
         * Create a new get family socket message
         *
         * @param inFamilyName family name
         */
        public Message.get_family (string inFamilyName)
        {
            HeaderGenl header_msg = new HeaderGenl.get_family (inFamilyName);

            this.raw ((int)header_msg.len);

            unowned Os.NlMsgHdr? msg = header_msg.msg;

            GLib.Memory.copy (m_Data, (void*)msg, header_msg.len);
        }

        /**
         * Create a new socket message
         *
         * @param inSize size of message
         */
        public Message.raw (int inSize)
        {
            m_Data = new uint8[inSize];

            m_Addr = Os.SockAddrNl ();
            m_Msg.msg_name = &m_Addr;
            m_Msg.msg_namelen = (Posix.socklen_t)sizeof (Os.SockAddrNl);

            m_Addr.nl_family = Linux.Socket.AF_NETLINK;
            m_Addr.nl_pid = 0;
            m_Addr.nl_groups = 0;

            m_Msg.msg_iov = m_Vector;
            m_Msg.msg_iov[0].iov_base = m_Data;
            m_Msg.msg_iov[0].iov_len = m_Data.length;
        }

        internal void
        recv (Socket inSocket) throws SocketError
        {
            m_Size = Os.recvmsg (inSocket.fd, m_Msg, 0);
            if (m_Size < 0)
                throw new SocketError.RECV ("Error on reading message");
        }

        internal void
        send (Socket inSocket) throws SocketError
        {
            unowned Os.NlMsgHdr? msg = (Os.NlMsgHdr?)m_Data;
            msg.nlmsg_seq = inSocket.seq;
            if (Os.sendmsg (inSocket.fd, m_Msg, 0) < 0)
                throw new SocketError.SEND ("Cannot talk to rtnetlink");
        }

        public Iterator<T>
        iterator ()
        {
            return new Iterator<T> (this);
        }
    }
}
