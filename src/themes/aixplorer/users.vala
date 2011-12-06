/* users.vala
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
    public class Users : Widget
    {
        // properties
        private Gtk.ListStore m_Model;

        // accessors
        public override string node_name {
            get {
                return "users";
            }
        }

        // signals
        public signal void selected (string inLogin);

        // methods
        construct
        {
            m_Model = new Gtk.ListStore (5, typeof (Gdk.Pixbuf), typeof (string), typeof (string), typeof (int), typeof (bool));
            clear ();

            Gtk.TreeModelFilter filter_model = new Gtk.TreeModelFilter (m_Model, null);
            filter_model.set_visible_column (4);

            Gtk.TreeView tree_view = new Gtk.TreeView.with_model (filter_model);
            tree_view.can_focus = false;
            tree_view.headers_visible = false;
            tree_view.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (), "pixbuf", 0);
            tree_view.insert_column_with_attributes (-1, "", new Gtk.CellRendererText (), "markup", 1);
            tree_view.get_selection ().changed.connect (on_selection_changed);
            tree_view.show ();

            Gtk.ScrolledWindow scrolled_window = new Gtk.ScrolledWindow (null, null);
            scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scrolled_window.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled_window.set_shadow_type (Gtk.ShadowType.IN);
            scrolled_window.add (tree_view);

            composite_widget = scrolled_window;
        }

        public void
        add_user (Gdk.Pixbuf inPixbuf, string inLogin, string inRealName, int inFrequency)
        {
            Gtk.TreeIter iter;
            m_Model.prepend (out iter);
            m_Model.set (iter, 0, inPixbuf, 1, "<span size='x-large'>" + inRealName + "</span>", 2, inLogin, 3, inFrequency, 4, true);
        }

        public void
        clear ()
        {
            m_Model.clear ();

            Gtk.TreeIter iter;
            m_Model.append (out iter);
            m_Model.set (iter, 0, null, 1, "<span size='x-large'>Other...</span>", 2, null, 3, 0, 4, true);
        }
    }
}

