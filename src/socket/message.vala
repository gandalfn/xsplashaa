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

namespace XSAA
{
    public enum MessageType
    {
        INVALID,
        PING,
        PONG,
        QUIT,
        DBUS,
        SESSION,
        PHASE,
        PULSE,
        PROGRESS,
        CLOSE_SESSION
    }

    /**
     * Socket message class
     */
    public class Message : GLib.Object
    {
        // properties
        private MessageType m_Type = MessageType.INVALID;
        private string      m_Data = null;

        // accessors
        /**
         * Message type
         */
        public MessageType message_type {
            get {
                return m_Type;
            }
            construct set {
                m_Type = value;
            }
        }

        /**
         * Message content
         */
        public string data {
            get {
                return m_Data;
            }
            construct set {
                m_Data = value;
            }
        }

        /**
         * Message raw data
         */
        public string raw {
            owned get {
                string ret = "0|EOM";
                if (m_Data != null && m_Data.length > 0)
                    ret = "%i|%s|EOM".printf (m_Type, m_Data);
                else
                    ret = "%i|EOM".printf (m_Type);

                return ret;
            }
        }

        // methods
        /**
         * Create a new messsage from raw data
         */
        public Message (string inRaw)
        {
            try
            {
                GLib.Regex re = new GLib.Regex ("""([0-9]+)\|?([^\|]*)\|EOM""");
                if (re.match (inRaw))
                {
                    string[] split = re.split (inRaw);
                    XSAA.MessageType type = (XSAA.MessageType)int.parse (split[1]);
                    GLib.Object (message_type: type, data: split[2]);
                }
            }
            catch (GLib.Error err)
            {
                XSAA.Log.error ("Error on create message regex");
            }
        }

        /**
         * Create a new ping message
         */
        public Message.ping ()
        {
            GLib.Object (message_type: MessageType.PING);
        }

        /**
         * Create a new pong message
         */
        public Message.pong ()
        {
            GLib.Object (message_type: MessageType.PONG);
        }

        /**
         * Create a new quit message
         */
        public Message.quit ()
        {
            GLib.Object (message_type: MessageType.QUIT);
        }

        /**
         * Create a new dbus message
         */
        public Message.dbus ()
        {
            GLib.Object (message_type: MessageType.DBUS);
        }

        /**
         * Create a new session message
         */
        public Message.session ()
        {
            GLib.Object (message_type: MessageType.SESSION);
        }

        /**
         * Create a new close session message
         */
        public Message.close_session ()
        {
            GLib.Object (message_type: MessageType.CLOSE_SESSION);
        }

        /**
         * Create a new phase message
         *
         * @param inPhase phase number
         */
        public Message.phase (int inPhase)
        {
            GLib.Object (message_type: MessageType.PHASE, data: inPhase.to_string ());
        }

        /**
         * Create a new progress message
         *
         * @param inProgress progress value
         */
        public Message.progress (int inProgress)
        {
            GLib.Object (message_type: MessageType.PROGRESS, data: inProgress.to_string ());
        }

        /**
         * Create a new pulse message
         */
        public Message.pulse ()
        {
            GLib.Object (message_type: MessageType.PULSE);
        }
    }
}

