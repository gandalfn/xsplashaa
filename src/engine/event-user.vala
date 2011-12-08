/* event-user.vala
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
    public class EventUser : Event<EventUser.Args>
    {
        // types
        public enum Type
        {
            ADD_USER,
            CLEAR
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type { get; construct; }
            public int shm_id_pixbuf { get; construct; }
            public string real_name { get; construct; }
            public string login  { get; construct; }
            public int frequency  { get; construct; }

            // methods
            public Args.add_user (int inShmIdPixbuf, string inRealName, string inLogin, int inFrequency)
            {
                GLib.Object (event_type: Type.ADD_USER, shm_id_pixbuf: inShmIdPixbuf, real_name: inRealName,
                             login: inLogin, frequency: inFrequency);
            }

            public Args.clear ()
            {
                GLib.Object (event_type: Type.CLEAR);
            }
        }

        public EventUser (Args inArgs)
        {
            base (inArgs);
        }

        public EventUser.add_user (int inShmIdPixbuf, string inRealName, string inLogin, int inFrequency)
        {
            this (new Args.add_user (inShmIdPixbuf, inRealName, inLogin, inFrequency));
        }

        public EventUser.clear ()
        {
            this (new Args.clear ());
        }
    }
}

