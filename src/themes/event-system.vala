/* event-system.vala
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
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    /**
     * Engine event class
     */
    public class EventSystem : Event<EventSystem.Args>
    {
        // types
        public enum Type
        {
            REBOOT,
            HALT
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type { get; construct; }

            // methods
            public Args.reboot ()
            {
                GLib.Object (event_type: Type.REBOOT);
            }

            public Args.halt ()
            {
                GLib.Object (event_type: Type.HALT);
            }
        }

        public EventSystem (Args inArgs)
        {
            base (inArgs);
        }

        public EventSystem.reboot ()
        {
            this (new Args.reboot ());
        }

        public EventSystem.halt ()
        {
            this (new Args.halt ());
        }
    }
}
