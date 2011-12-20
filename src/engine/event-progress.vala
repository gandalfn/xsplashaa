/* event-progress.vala
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
    public class EventProgress : Event<EventProgress.Args>
    {
        // types
        public enum Type
        {
            PULSE,
            PROGRESS
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type { get; construct; }
            public double progress_val  { get; construct; }

            // methods
            public Args.pulse ()
            {
                GLib.Object (event_type: Type.PULSE);
            }

            public Args.progress (double inProgress)
            {
                GLib.Object (event_type: Type.PROGRESS, progress_val: inProgress);
            }
        }

        public EventProgress (Args inArgs)
        {
            base (inArgs);
        }

        public EventProgress.pulse ()
        {
            this (new Args.pulse ());
        }

        public EventProgress.progress (double inProgress)
        {
            this (new Args.progress (inProgress));
        }
    }
}
