/* table.vala
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
    public class Table : Goo.CanvasTable, Goo.CanvasItem, XSAA.EngineItem, ItemPackOptions
    {
        // properties
        private string                             m_Id;
        private int                                m_Layer;
        private GLib.HashTable<string, EngineItem> m_Childs;
        private bool                               m_Clip;

        // accessors
        public virtual string node_name {
            get {
                return "table";
            }
        }

        public GLib.HashTable<string, EngineItem>? childs {
            get {
                if (m_Childs == null)
                    m_Childs = new GLib.HashTable<string, EngineItem> (GLib.str_hash, GLib.str_equal);
                return m_Childs;
            }
        }

        public string id {
            get {
                return m_Id;
            }
            set {
                XSAA.Log.debug ("set id: %s", value);
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

        public bool clip {
            get {
                return m_Clip;
            }
            set {
                m_Clip = value;
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
        public int  page_num         { get; set; default = -1; }

        public Notebook.Animation.AnimType animation { get; set; default = Notebook.Animation.AnimType.HORIZONTAL_SLIDE; }

        // methods
        construct
        {
            notify["visibility"].connect (() => {
                foreach (unowned EngineItem item in find_by_type (typeof (Widget)))
                {
                    ((Goo.CanvasItemSimple)item).visibility = visibility;
                }
            });
        }

        public void
        paint (Cairo.Context inContext, Goo.CanvasBounds inBounds, double inScale)
        {
            inContext.save ();
            {
                if (m_Clip)
                {
                    inContext.rectangle (0, 0, inBounds.x1 + inBounds.x2, inBounds.y1 + inBounds.y2);
                    inContext.clip ();
                }
                base.paint (inContext, inBounds, inScale);
            }
            inContext.restore ();
        }

        public void
        append_child (EngineItem inChild)
        {
            if (inChild is Goo.CanvasItemSimple)
            {
                childs.insert (inChild.id, inChild);
                add_child ((Goo.CanvasItemSimple)inChild, inChild.layer);
                if (inChild is ItemPackOptions)
                {
                    unowned ItemPackOptions? pack_options = (ItemPackOptions?)inChild;
                    set_child_properties (((Goo.CanvasItem)inChild),
                                          row: pack_options.row,
                                          column: pack_options.column,
                                          rows: pack_options.rows,
                                          columns: pack_options.columns,
                                          top_padding: pack_options.top_padding,
                                          bottom_padding: pack_options.bottom_padding,
                                          right_padding: pack_options.right_padding,
                                          left_padding: pack_options.left_padding,
                                          x_expand: pack_options.x_expand,
                                          x_fill: pack_options.x_fill,
                                          x_shrink: pack_options.y_shrink,
                                          y_expand: pack_options.y_expand,
                                          y_fill: pack_options.y_fill,
                                          y_shrink: pack_options.y_shrink,
                                          x_align: pack_options.x_align,
                                          y_align: pack_options.y_align);
                }
                if (inChild is Widget)
                {
                    ((Widget)inChild).visibility = visibility;
                }
                Log.debug ("%s %f,%f,%f,%f", id, bounds.x1, bounds.y1, bounds.x2, bounds.y2);
            }
        }
    }
}
