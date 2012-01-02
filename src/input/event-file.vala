/* event-file.vala
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

namespace XSAA.Input
{
    public errordomain EventFileError
    {
        OPEN,
        RECV
    }

    /**
     *  Handles the details of getting kernel events from the input file
     *  layer (/dev/input/event*).
     */
    public class EventFile : GLib.Object
    {
        // properties
        private string         m_Filename;
        private GLib.IOChannel m_Channel;
        private uint           m_IdWatch;

        // signals
        public signal void event (uint inType, uint inCode, uint inValue);

        // static methods
        private static inline ulong
        bits_per_long ()
        {
            return sizeof(long) * 8;
        }

        private static inline ulong
        nbits (ulong inX)
        {
            return (((inX) - 1) / bits_per_long ()) + 1;
        }

        private static inline ulong
        off (ulong inX)
        {
            return inX % bits_per_long ();
        }

        private static inline ulong
        lon (ulong inX)
        {
            return inX / bits_per_long ();
        }

        private static inline ulong
        test_bit (ulong inBit, ulong* inArray)
        {
            return (inArray[lon (inBit)] >> off (inBit)) & 1;
        }

        // methods
        /**
         * Create a new kernel event input layer object
         *
         * @param inDevice device file
         */
        public EventFile (string inDevice) throws EventFileError
        {
            m_Filename = inDevice;

            if (!GLib.FileUtils.test (inDevice, GLib.FileTest.EXISTS))
                throw new EventFileError.OPEN ("Error could not find %s", inDevice);

            try
            {
                m_Channel = new GLib.IOChannel.file (inDevice, "r");
                m_Channel.set_encoding(null);
                m_Channel.set_buffered(false);
                m_Channel.set_close_on_unref (true);
                m_Channel.set_flags (m_Channel.get_flags () | GLib.IOFlags.NONBLOCK);
                m_IdWatch = m_Channel.add_watch (GLib.IOCondition.IN | GLib.IOCondition.PRI, on_data);
            }
            catch (GLib.Error err)
            {
                throw new EventFileError.OPEN ("%s", err.message);
            }
        }

        ~EventFile ()
        {
            if (m_IdWatch != 0) GLib.Source.remove (m_IdWatch);
            m_IdWatch = 0;
        }

        private bool
        on_data ()
        {
            if (m_IdWatch != 0)
            {
                try
                {
                    char[] buf = new char [sizeof(Linux.Input.Event)];
                    size_t size;
                    if (m_Channel.read_chars (buf, out size) == GLib.IOStatus.NORMAL && size == sizeof(Linux.Input.Event))
                    {
                        unowned Linux.Input.Event? evt = (Linux.Input.Event?)buf;
                        event (evt.type, evt.code, evt.value);
                    }
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on read input event: %s", err.message);
                }
            }

            return m_IdWatch != 0;
        }

        public bool
        support_event (uint inType, uint inCode)
        {
            ulong[,] bit = new ulong [Linux.Input.EV_MAX, nbits(Linux.Input.KEY_MAX)];

            Linux.ioctl(m_Channel.unix_get_fd (), Linux.Input.EVIOCGBIT(0, Linux.Input.EV_MAX), &bit[0, 0]);

            for (int type = 0; type < Linux.Input.EV_MAX; ++type)
            {
                if (test_bit(type, &bit[0, 0]) != 0)
                {
                    if (type == Linux.Input.EV_SYN) continue;

                    Linux.ioctl(m_Channel.unix_get_fd (), Linux.Input.EVIOCGBIT(type, Linux.Input.KEY_MAX), &bit[type, 0]);

                    for (int code = 0; code < Linux.Input.KEY_MAX; code++)
                    {
                        if (test_bit(code, &bit[type,0]) != 0)
                        {
                            if (code == inCode && type == inType)
                                return true;
                        }
                    }
                }
            }
            return false;
        }
    }
}
