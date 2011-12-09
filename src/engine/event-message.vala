/* event-message.vala
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
    public class EventMessage : Event<EventMessage.Args>
    {
        // types
        public enum Type
        {
            MESSAGE
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type { get; construct; }
            public string text { get; construct; }

            // methods
            public Args.message (string inMessage)
            {
                GLib.Object (event_type: Type.MESSAGE, text: inMessage);
            }
        }

        public EventMessage (Args inArgs)
        {
            base (inArgs);
        }

        public EventMessage.message (string inMessage)
        {
            this (new Args.message (inMessage));
        }
    }
}
