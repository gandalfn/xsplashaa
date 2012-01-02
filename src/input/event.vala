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
        // properties
        private EventWatch[]        m_Events;
        private GLib.List<EventFile> m_Files;

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
                GLib.Dir dir = GLib.Dir.open ("/dev/input");
                unowned string file = null;
                m_Files = new GLib.List<EventFile> ();

                while ((file = dir.read_name ()) != null)
                {
                    if ("event" in file)
                    {
                        EventFile event = new EventFile ("/dev/input/" + file);
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
