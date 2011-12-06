/* event-boot.vala
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
    public class EventBoot : Event<EventBoot.Args>
    {
        // types
        public enum Type
        {
            STARTING,
            CHECK_FILESYSTEM,
            LOADING
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type { get; construct; }
            public bool completed  { get; construct; }

            // methods
            public Args.starting (bool inCompleted)
            {
                GLib.Object (event_type: Type.STARTING, completed: inCompleted);
            }

            public Args.check_filesystem (bool inCompleted)
            {
                GLib.Object (event_type: Type.CHECK_FILESYSTEM, completed: inCompleted);
            }

            public Args.loading (bool inCompleted)
            {
                GLib.Object (event_type: Type.LOADING, completed: inCompleted);
            }
        }

        public EventBoot (Args inArgs)
        {
            base (inArgs);
        }

        public EventBoot.starting (bool inCompleted)
        {
            this (new Args.starting (inCompleted));
        }

        public EventBoot.check_filesystem (bool inCompleted)
        {
            this (new Args.check_filesystem (inCompleted));
        }

        public EventBoot.loading (bool inCompleted)
        {
            this (new Args.loading (inCompleted));
        }
    }
}
