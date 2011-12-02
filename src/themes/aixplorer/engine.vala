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

namespace XSAA.Aixplorer
{
    /**
     * Aixplorer theme engine
     */
    public class Engine : Goo.Canvas, XSAA.Engine
    {
        // private
        private string                   m_Name;
        private unowned Goo.CanvasItem?  m_Root;
        private Background               m_Background;

        // methods
        /**
         * Create a new Aixplorer theme engine
         */
        public Engine (string inName)
        {
            m_Name = inName;

            m_Root = get_root_item ();
            m_Background = new Background (m_Root, m_Name, 0, 0);
        }

        public override void
        size_allocate (Gdk.Rectangle inAllocation)
        {
            base.size_allocate (inAllocation);

            set_bounds (0, 0, inAllocation.width, inAllocation.height);
            m_Background.width = inAllocation.width;
            m_Background.height = inAllocation.height;
        }
    }
}

public XSAA.Engine? plugin_init (string inName)
{
    return new XSAA.Aixplorer.Engine (inName);
}
