/* engine.vala
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
    public enum CheckSubsystem
    {
        FILESYSTEM,
        TOUCHSCREEN,
        KEYBOARD
    }

    /**
     * Splash render engine
     */
    public interface Engine : Gtk.Widget, EngineItem
    {
        // signals
//        public signal void login_enter (string inLogin);
//        public signal void password_enter (string inPasswd);

        // methods
//        public abstract void show_loading ();
//        public abstract void show_starting ();
//        public abstract void show_checking (CheckSubsystem inSubsystem);
//        public abstract void show_login ();
//        public abstract void show_open_session ();
//        public abstract void session_open ();
//        public abstract void shutdown ();

//        public abstract void display_progress (int inProgress);
//        public abstract void display_login_message (string inMessage);
//        public abstract void display_message (string inMessage);
//        public abstract void display_error (string inMessage);

//        public abstract void show_face ();
//        public abstract void face_image (Cairo.Surface inSurface);
    }
}
