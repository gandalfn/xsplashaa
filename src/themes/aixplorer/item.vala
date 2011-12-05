/* item.vala
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
    public class Item : Goo.CanvasItemSimple, XSAA.EngineItem, ItemPackOptions
    {
        // types
        public struct Geometry
        {
            public double x;
            public double y;
            public double width;
            public double height;
        }

        // properties
        private string                             m_Id;
        private int                                m_Layer;
        private Geometry                           m_Geometry;

        // accessors
        public virtual string node_name {
            get {
                return "item";
            }
        }

        public GLib.HashTable<string, EngineItem>? childs {
            get {
                return null;
            }
        }

        public string id {
            get {
                return m_Id;
            }
            set {
                m_Id = value;
            }
        }

        public int layer {
            get {
                return m_Layer;
            }
            set {
                m_Layer = value;
            }
        }

        public virtual double x {
            get {
                return m_Geometry.x;
            }
            set {
                m_Geometry.x = value;
                changed (true);
            }
        }

        public virtual double y {
            get {
                return m_Geometry.y;
            }
            set {
                m_Geometry.y = value;
                changed (true);
            }
        }

        public virtual double width {
            get {
                return m_Geometry.width;
            }
            set {
                m_Geometry.width = value;
                changed (true);
            }
        }

        public virtual double height {
            get {
                return m_Geometry.height;
            }
            set {
                m_Geometry.height = value;
                changed (true);
            }
        }

        public bool expand           { get; set; default = false; }
        public int row               { get; set; default = 0; }
        public int column            { get; set; default = 0; }
        public int rows              { get; set; default = 1; }
        public int columns           { get; set; default = 1; }
        public double top_padding    { get; set; default = 0.0; }
        public double bottom_padding { get; set; default = 0.0; }
        public double left_padding   { get; set; default = 0.0; }
        public double right_padding  { get; set; default = 0.0; }
        public double x_align        { get; set; default = 0.5; }
        public bool x_expand         { get; set; default = true; }
        public bool x_fill           { get; set; default = false; }
        public bool x_shrink         { get; set; default = false; }
        public double y_align        { get; set; default = 0.5; }
        public bool y_expand         { get; set; default = true; }
        public bool y_fill           { get; set; default = false; }
        public bool y_shrink         { get; set; default = false; }

        // methods
        public override bool
        simple_is_item_at (double inX, double inY, Cairo.Context inContext, bool inIsPointerEvent)
        {
            return (inX >= x && (inX <= x + width) && inY >= y || (inY <= y + height));
        }

        public override void
        simple_update (Cairo.Context inContext)
        {
            bounds.x1 = x;
            bounds.y1 = y;
            bounds.x2 = x + width;
            bounds.y2 = y + height;
        }
    }
}
