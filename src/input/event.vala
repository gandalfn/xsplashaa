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
    public enum EventWatch
    {
        POWER_BUTTON,
        F12_BUTTON;

        internal uint
        get_event_type ()
        {
            switch (this)
            {
                case POWER_BUTTON:
                case F12_BUTTON:
                    return Linux.Input.EV_KEY;
            }

            return 0;
        }

        internal uint
        get_event_code ()
        {
            switch (this)
            {
                case POWER_BUTTON:
                    return Linux.Input.KEY_POWER;
                case F12_BUTTON:
                    return Linux.Input.KEY_F12;
            }

            return 0;
        }
    }

    /**
     * Handles the details of getting kernel events from the input files
     * layer (/dev/input/event*).
     */
    public class Event : GLib.Object
    {
        // constants
        const string DEV_INPUT_PATH = "/dev/input";

        // properties
        private EventWatch[]         m_Events;
        private GLib.List<EventFile> m_Files;
        private int                  m_INotifyFd;
        private GLib.IOChannel       m_INotifyChannel;
        private uint                 m_INotifyIdWatch;

        // signals
        public signal void event (EventWatch inWatch, uint inValue);

        // methods
        /**
         * Create a new input layer event
         */
        public Event (EventWatch[] inEvents)
        {
            m_Events = inEvents;

            try
            {
                GLib.Dir dir = GLib.Dir.open (DEV_INPUT_PATH);
                unowned string file = null;
                m_Files = new GLib.List<EventFile> ();

                while ((file = dir.read_name ()) != null)
                {
                    if ("event" in file)
                    {
                        EventFile event = new EventFile (DEV_INPUT_PATH + "/" + file);
                        foreach (EventWatch watch in inEvents)
                        {
                            if (event.support_event (watch.get_event_type (), watch.get_event_code ()))
                            {
                                m_Files.prepend (event);
                                event.event.connect (on_event);
                                break;
                            }
                        }
                    }
                }
            }
            catch (GLib.Error err)
            {
                Log.error ("Error on listen input event");
            }

            // Open inotify directory
            m_INotifyFd = Linux.inotify_init ();
            if (m_INotifyFd >= 0)
            {
                if (Linux.inotify_add_watch (m_INotifyFd, DEV_INPUT_PATH, Linux.InotifyMaskFlags.CREATE) >= 0)
                {
                    try
                    {
                        m_INotifyChannel = new GLib.IOChannel.unix_new (m_INotifyFd);
                        m_INotifyChannel.set_encoding(null);
                        m_INotifyChannel.set_buffered(false);
                        m_INotifyIdWatch = m_INotifyChannel.add_watch(GLib.IOCondition.IN | GLib.IOCondition.PRI, on_input_added);
                    }
                    catch (GLib.Error err)
                    {
                        Os.close (m_INotifyFd);
                        Log.error ("Error on watch %s: %s", DEV_INPUT_PATH, err.message);
                    }
                }
                else
                {
                    Os.close (m_INotifyFd);
                    Log.error ("Error on add watch %s", DEV_INPUT_PATH);
                }
            }
            else
            {
                Log.error ("Error on watch %s", DEV_INPUT_PATH);
            }
        }

        ~Event ()
        {
            if (m_INotifyIdWatch != 0) GLib.Source.remove (m_INotifyIdWatch);
            m_INotifyIdWatch = 0;
            if (m_INotifyFd >= 0) Os.close (m_INotifyFd);
        }

        private bool
        on_input_added ()
        {
            if (m_INotifyIdWatch != 0)
            {
                char buf[4096];
                size_t size;
                try
                {
                    if (m_INotifyChannel.read_chars (buf, out size) == GLib.IOStatus.NORMAL && size >= sizeof (Linux.InotifyEvent))
                    {
                        unowned Linux.InotifyEvent? evt = (Linux.InotifyEvent?)buf;
                        if ("event" in evt.name)
                        {
                            Log.debug ("New input file %s", DEV_INPUT_PATH + "/" + evt.name);
                            EventFile event = new EventFile (DEV_INPUT_PATH + "/" + evt.name);
                            foreach (EventWatch watch in m_Events)
                            {
                                if (event.support_event (watch.get_event_type (), watch.get_event_code ()))
                                {
                                    m_Files.prepend (event);
                                    event.event.connect (on_event);
                                    break;
                                }
                            }
                        }
                    }
                }
                catch (GLib.Error err)
                {
                    Log.critical ("Error on watch event %s: %s", DEV_INPUT_PATH, err.message);
                }
            }

            return m_INotifyIdWatch != 0;
        }

        private void
        on_event (uint inType, uint inCode, uint inValue)
        {
            foreach (EventWatch watch in m_Events)
            {
                if (watch.get_event_type () == inType && watch.get_event_code () == inCode)
                    event (watch, inValue);
            }
        }
    }
}

