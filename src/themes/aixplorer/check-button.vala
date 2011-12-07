/* button.vala
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
    public class CheckButton : Item
    {
        // properties
        private bool        m_Active = false;
        private Gdk.Color   m_FgColor;

        // accessors
        public override string node_name {
            get {
                return "checkbutton";
            }
        }

        public bool active {
            get {
                return m_Active;
            }
            set
            {
                m_Active = value;
                changed (true);
            }
        }

        public string fg_color {
            set {
                Gdk.Color.parse (value, out m_FgColor);
            }
        }

        // signals
        public signal void toggled ();

        // methods
        construct
        {
            Gdk.Color.parse ("#FFFFFF", out m_FgColor);

            width = 24;
            height = 24;

            button_press_event.connect (on_button_press_event);
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            double w = width;
            double h = height;

            inContext.save ();

            get_style ().set_fill_options (inContext);

            Gdk.Color shade = CairoColor.shade (m_FgColor, 0.6);
            Gdk.cairo_set_source_color (inContext, shade);
            ((CairoContext)inContext).rounded_rectangle (0, 0, w, h, 5, CairoCorner.ALL);
            inContext.fill ();

            Gdk.cairo_set_source_color (inContext, m_FgColor);
            ((CairoContext)inContext).rounded_rectangle (1.5, 1.5, w - 3, h - 3, 5, CairoCorner.ALL);
            inContext.fill ();

            if (m_Active)
            {
                get_style ().set_stroke_options (inContext);
                inContext.move_to (0.5 + (w * 0.2), (h * 0.5));
                inContext.line_to (0.5 + (w * 0.4), (height * 0.7));

                inContext.curve_to (0.5 + (w * 0.4), (h * 0.7),
                                    0.5 + (w * 0.5), (h * 0.4),
                                    0.5 + (w * 0.70), (h * 0.25));
                inContext.stroke ();
            }
            inContext.restore ();
        }

        public bool
        on_button_press_event (Goo.CanvasItem inItem, Gdk.EventButton inEvent)
        {
            active = !m_Active;
            toggled ();
            return false;
        }
    }
}

