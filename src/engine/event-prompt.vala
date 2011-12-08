/* event-prompt.vala
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
    public class EventPrompt : Event<EventPrompt.Args>
    {
        // types
        public enum Type
        {
            SHOW_LOGIN,
            SHOW_PASSWORD,
            SHOW_FACE_AUTHENTIFICATION,
            MESSAGE,
            EDITED
        }

        public class Args : XSAA.Event.Args
        {
            // accessors
            public Type event_type            { get; construct; }
            public string text                { get; construct; }
            public string msg                 { get; construct; }
            public bool face_authentification { get; construct; default = false; }

            // methods
            public Args.show_login ()
            {
                GLib.Object (event_type: Type.SHOW_LOGIN);
            }

            public Args.show_password ()
            {
                GLib.Object (event_type: Type.SHOW_PASSWORD);
            }

            public Args.show_face_authentification ()
            {
                GLib.Object (event_type: Type.SHOW_FACE_AUTHENTIFICATION);
            }

            public Args.message (string inMessage)
            {
                GLib.Object (event_type: Type.MESSAGE, msg: inMessage);
            }

            public Args.edited (string inPrompt, bool inFaceAuthentification)
            {
                GLib.Object (event_type: Type.EDITED, text: inPrompt, face_authentification: inFaceAuthentification);
            }
        }

        public EventPrompt (Args inArgs)
        {
            base (inArgs);
        }

        public EventPrompt.show_login ()
        {
            this (new Args.show_login ());
        }

        public EventPrompt.show_password ()
        {
            this (new Args.show_password ());
        }

        public EventPrompt.show_face_authentification ()
        {
            this (new Args.show_face_authentification ());
        }

        public EventPrompt.message (string inMessage)
        {
            this (new Args.message (inMessage));
        }

        public EventPrompt.edited (string inPrompt, bool inFaceAuthentification = false)
        {
            this (new Args.edited (inPrompt, inFaceAuthentification));
        }
    }
}

