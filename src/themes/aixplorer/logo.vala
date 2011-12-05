/* logo.vala
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
    public class Logo : Image
    {
        // properties
        private string m_Filename;

        // accessors
        public override string node_name {
            get {
                return "logo";
            }
        }

        public string filename {
            get {
                return m_Filename;
            }
            set {
                m_Filename = value;
                try
                {
                    pixbuf = new Gdk.Pixbuf.from_file (m_Filename);
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on loading %s: %s", m_Filename, err.message);
                }
            }
        }
    }
}
