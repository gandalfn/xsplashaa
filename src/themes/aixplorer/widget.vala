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
    public class Widget : Goo.CanvasWidget, XSAA.EngineItem, ItemPackOptions
    {
        // properties
        private string                             m_Id;
        private int                                m_Layer;

        // accessors
        public virtual string node_name {
            get {
                return "widget";
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

        public new Gtk.Widget composite_widget {
            get {
                return ((Gtk.EventBox)widget).get_child ();
            }
            set {
                Gtk.EventBox box = new Gtk.EventBox ();
                box.set_above_child (false);
                box.set_visible_window (true);
                box.set_app_paintable (true);
                box.realize.connect ((b) => { b.window.set_composited(true); });
                box.expose_event.connect ((e) => {
                    var cr = Gdk.cairo_create (box.window);
                    cr.set_operator (Cairo.Operator.CLEAR);
                    cr.paint ();
                    return false;
                });

                value.show ();
                box.add (value);

                widget = box;
            }
        }

        public string widget_font {
            set {
                Pango.FontDescription font_desc = Pango.FontDescription.from_string (value);
                composite_widget.modify_font (font_desc);
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
        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            if (widget != null && widget.window != null)
            {
                var cr_widget = Gdk.cairo_create (widget.window);
                var pattern = new Cairo.Pattern.for_surface (cr_widget.get_target());

                get_style ().set_fill_options (inContext);
                inContext.set_source (pattern);
                inContext.rectangle (0, 0, inBounds.x1 + inBounds.x2, inBounds.y1 + inBounds.y2);
                inContext.fill();
            }
        }
    }
}

