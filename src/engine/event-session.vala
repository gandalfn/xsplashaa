/* event-session.vala
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
    public class EventSession : Event<EventSession.Args>
    {
        // types
        public enum Type
        {
            LOADING
        }

        public enum Status
        {
            PENDING,
            FINISHED,
            ERROR
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type { get; construct; }
            public Status status  { get; construct; }

            // methods
            public Args.loading (Status inStatus)
            {
                GLib.Object (event_type: Type.LOADING, status: inStatus);
            }
        }

        public EventSession (Args inArgs)
        {
            base (inArgs);
        }

        public EventSession.loading (Status inStatus)
        {
            this (new Args.loading (inStatus));
        }
    }
}
