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
            LOADING,
            CHECK_DEVICE,
            SHUTDOWN
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
            public Args.starting (Status inStatus)
            {
                GLib.Object (event_type: Type.STARTING, status: inStatus);
            }

            public Args.check_filesystem (Status inStatus)
            {
                GLib.Object (event_type: Type.CHECK_FILESYSTEM, status: inStatus);
            }

            public Args.loading (Status inStatus)
            {
                GLib.Object (event_type: Type.LOADING, status: inStatus);
            }

            public Args.check_device (Status inStatus)
            {
                GLib.Object (event_type: Type.CHECK_DEVICE, status: inStatus);
            }

            public Args.shutdown (Status inStatus)
            {
                GLib.Object (event_type: Type.SHUTDOWN, status: inStatus);
            }
        }

        public EventBoot (Args inArgs)
        {
            base (inArgs);
        }

        public EventBoot.starting (Status inStatus)
        {
            this (new Args.starting (inStatus));
        }

        public EventBoot.check_filesystem (Status inStatus)
        {
            this (new Args.check_filesystem (inStatus));
        }

        public EventBoot.loading (Status inStatus)
        {
            this (new Args.loading (inStatus));
        }

        public EventBoot.check_device (Status inStatus)
        {
            this (new Args.check_device (inStatus));
        }

        public EventBoot.shutdown (Status inStatus)
        {
            this (new Args.shutdown (inStatus));
        }
    }
}
