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

        // signals
        public signal void clicked ();

        // methods
        construct
        {
            button_press_event.connect (on_button_press_event);
            button_release_event.connect (on_button_release_event);
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            if (m_Handle[m_State] != null)
            {
                inContext.save ();
                if (m_Reflect)
                {
                    inContext.push_group();

                    inContext.save ();

                    inContext.rectangle (0, base.height, base.width, base.height);
                    inContext.clip ();

                    Cairo.Matrix matrix = Cairo.Matrix(1, 0, 0, 1, 0, 0);
                    matrix.scale (base.width / m_Handle[m_State].width, -base.height / m_Handle[m_State].height);
                    matrix.translate (0, -(2 * m_Handle[m_State].height) + 1);

                    inContext.transform (matrix);

                    get_style ().set_fill_options (inContext);
                    m_Handle[m_State].render_cairo (inContext);

                    inContext.restore ();

                    inContext.pop_group_to_source();

                    Cairo.Pattern mask = new Cairo.Pattern.linear(0, height, 0, base.height);
                    mask.add_color_stop_rgba(0.25, 0, 0, 0, 0);
                    mask.add_color_stop_rgba(0.5, 0, 0, 0, 0.125);
                    mask.add_color_stop_rgba(0.75, 0, 0, 0, 0.4);
                    mask.add_color_stop_rgba(1.0, 0, 0, 0, 0.4);

                    inContext.mask (mask);
                }

                inContext.scale (base.width / m_Handle[m_State].width, base.height / m_Handle[m_State].height);
                get_style ().set_fill_options (inContext);
                m_Handle[m_State].render_cairo (inContext);
                inContext.restore ();
            }
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
