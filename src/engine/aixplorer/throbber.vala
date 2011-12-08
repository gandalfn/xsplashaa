/* throbber.vala
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
    public class Throbber : Widget
    {
        // accessors
        public override string node_name {
            get {
                return "throbber";
            }
        }

        public string theme_name {
            set {
                try
                {
                    composite_widget = new XSAA.Throbber (value, 83);
                    stop ();
                }
                catch (GLib.Error err)
                {
                    Log.critical ("Error on create throbber %s: %s", id, err.message);
                }
            }
        }

        // methods
        public void
        start ()
        {
            ((XSAA.Throbber)composite_widget).start ();
        }

        public void
        stop ()
        {
            ((XSAA.Throbber)composite_widget).stop ();
        }

        public void
        finished ()
        {
            ((XSAA.Throbber)composite_widget).finished ();
        }
    }
}
