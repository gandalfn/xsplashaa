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
    public class Button : Item
    {
        // types
        private enum State
        {
            PRESS,
            RELEASE,
            N;
        }

        // properties
        private State         m_State = State.RELEASE;
        private Rsvg.Handle   m_Handle[2];
        private bool          m_Reflect = false;
        private Gdk.Color     m_ActiveColor;
        private Gdk.Color     m_InactiveColor;
        private double        m_Border = 12.0;
        private string        m_Text = null;

        // accessors
        public override string node_name {
            get {
                return "button";
            }
        }

        public override double height {
            get {
                return m_Reflect ? base.height * 2.0 : base.height;
            }
            set {
                base.height = value;
            }
        }

        public string filename_press {
            set {
                try
                {
                    m_Handle[State.PRESS] = new Rsvg.Handle.from_file (value);
                    if (base.width <= 0)
                        base.width = m_Handle[State.PRESS].width;
                    if (base.height <= 0)
                        base.height = m_Handle[State.PRESS].height;
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on loading %s: %s", value, err.message);
                }
            }
        }

        public string filename_release {
            set {
                try
                {
                    m_Handle[State.RELEASE] = new Rsvg.Handle.from_file (value);
                    if (base.width <= 0)
                        base.width = m_Handle[State.RELEASE].width;
                    if (base.height <= 0)
                        base.height = m_Handle[State.RELEASE].height;
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on loading %s: %s", value, err.message);
                }
            }
        }

        public string active_color {
            set {
                Gdk.Color.parse (value, out m_ActiveColor);
            }
        }

        public string inactive_color {
            set {
                Gdk.Color.parse (value, out m_InactiveColor);
            }
        }

        public double border {
            set {
                m_Border = value;
            }
        }

        public bool show_reflection {
            get {
                return m_Reflect;
            }
            set {
                if (m_Reflect != value)
                {
                    m_Reflect = value;
                }
            }
        }

        public string text {
            set {
                m_Text = value;
            }
        }

        // signals
        public signal void clicked ();

        // methods
        construct
        {
            button_press_event.connect (on_button_press_event);
            button_release_event.connect (on_button_release_event);
        }

        private void
        draw_button (Cairo.Context inContext)
        {
            if (m_Handle[m_State] != null)
            {
                m_Handle[m_State].render_cairo (inContext);
            }
            else
            {
                Gdk.Color fg;
                double alpha;
                CairoColor.rgba_to_color (fill_color_rgba, out fg, out alpha);
                ((CairoContext)inContext).button (fg, m_ActiveColor, m_InactiveColor,
                                                  0, 0, base.width, base.height, m_Border,
                                                  m_State == State.RELEASE ? 1 : 0, 0.9);
                if (m_Text != null)
                {
                    Gdk.Color text_color;
                    CairoColor.rgba_to_color (stroke_color_rgba, out text_color, out alpha);
                    Gdk.Color shade_color = CairoColor.shade (text_color, 0.8);
                    inContext.save ();
                    inContext.translate (base.width / 2, base.height / 2);
                    ((CairoContext)inContext).shade_text (m_Text, font_desc, Pango.Alignment.CENTER,
                    text_color, shade_color, 1.0, m_State == State.PRESS ? true : false);
                    inContext.restore ();
                }
            }
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            inContext.save ();
            if (m_Reflect)
            {
                inContext.push_group();

                inContext.save ();

                inContext.rectangle (0, base.height, base.width, base.height);
                inContext.clip ();

                Cairo.Matrix matrix = Cairo.Matrix(1, 0, 0, 1, 0, 0);
                if (m_Handle[m_State] != null)
                {
                    matrix.scale (base.width / m_Handle[m_State].width, -base.height / m_Handle[m_State].height);
                    matrix.translate (0, -(2 * m_Handle[m_State].height) + 1);
                }
                else
                {
                    matrix.scale (1, -1);
                    matrix.translate (0, -(2 * base.height) + 1);
                }

                inContext.transform (matrix);

                get_style ().set_fill_options (inContext);
                draw_button (inContext);

                inContext.restore ();

                inContext.pop_group_to_source();

                Cairo.Pattern mask = new Cairo.Pattern.linear(0, height, 0, base.height);
                mask.add_color_stop_rgba(0.25, 0, 0, 0, 0);
                mask.add_color_stop_rgba(0.5, 0, 0, 0, 0.125);
                mask.add_color_stop_rgba(0.75, 0, 0, 0, 0.4);
                mask.add_color_stop_rgba(1.0, 0, 0, 0, 0.4);

                inContext.mask (mask);
            }

            if (m_Handle[m_State] != null)
            {
                inContext.scale (base.width / m_Handle[m_State].width, base.height / m_Handle[m_State].height);
            }
            get_style ().set_fill_options (inContext);
            draw_button (inContext);
            inContext.restore ();
        }

        public bool
        on_button_press_event (Goo.CanvasItem inItem, Gdk.EventButton inEvent)
        {
            m_State = State.PRESS;
            changed (false);
            return false;
        }

        public bool
        on_button_release_event (Goo.CanvasItem inItem, Gdk.EventButton inEvent)
        {
            m_State = State.RELEASE;
            changed (false);
            clicked ();
            return false;
        }
    }
}

