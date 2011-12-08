/* entry.vala
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

namespace XSAA.Aixplorer
{
    public class Entry : Widget
    {
        // accessors
        public override string node_name {
            get {
                return "entry";
            }
        }

        public bool entry_visibility {
            set {
                ((Gtk.Entry)composite_widget).visibility = value;
            }
        }

        public string text {
            get {
                return ((Gtk.Entry)composite_widget).text;
            }
            set {
                ((Gtk.Entry)composite_widget).text = value;
            }
        }

        // signals
        public signal void edited (string inVal);

        // methods
        construct
        {
            Gtk.Entry entry = new Gtk.Entry ();
            entry.can_focus = true;
            entry.activate.connect (() => {
                edited (entry.text);
            });
            composite_widget = entry;
        }

        public void
        grab_focus ()
        {
            composite_widget.grab_focus ();
        }
    }
}

