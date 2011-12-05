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
        private Gdk.Pixbuf    m_Pixbuf[2];
        private Cairo.Pattern m_Pattern[2];


        // accessors
        public override string node_name {
            get {
                return "button";
            }
        }

        public override double width {
            get {
                return base.width;
            }
            set {
                if (base.width != value)
                {
                    m_Pattern[State.PRESS] = null;
                    m_Pattern[State.RELEASE] = null;
                    base.width = value;
                }
            }
        }

        public override double height {
            get {
                return base.height;
            }
            set {
                if (base.height != value)
                {
                    m_Pattern[State.PRESS] = null;
                    m_Pattern[State.RELEASE] = null;
                    base.height = value;
                }
            }
        }

        public string filename_press {
            set {
                try
                {
                    m_Pixbuf[State.PRESS] = new Gdk.Pixbuf.from_file (value);
                    m_Pattern[State.PRESS] = null;
                    base.width = double.max (base.width, m_Pixbuf[State.PRESS].width);
                    base.height = double.max (base.height, m_Pixbuf[State.PRESS].height);
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
                    m_Pixbuf[State.RELEASE] = new Gdk.Pixbuf.from_file (value);
                    m_Pattern[State.RELEASE] = null;
                    base.width = double.max (base.width, m_Pixbuf[State.RELEASE].width);
                    base.height = double.max (base.height, m_Pixbuf[State.RELEASE].height);
                }
                catch (GLib.Error err)
                {
                    Log.critical ("error on loading %s: %s", value, err.message);
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
        simple_update (Cairo.Context inContext)
        {
            base.simple_update (inContext);

            for (int cpt = 0; cpt < State.N; ++cpt)
            {
                if (m_Pattern[cpt] == null && m_Pixbuf[cpt] != null)
                {
                    var surface = new Cairo.Surface.similar (inContext.get_target (), Cairo.Content.COLOR_ALPHA,
                                                             (int)width, (int)height);
                    var ctx = new Cairo.Context (surface);
                    ctx.set_operator (Cairo.Operator.SOURCE);
                    ctx.scale (width / m_Pixbuf[cpt].width, height / m_Pixbuf[cpt].height);
                    Gdk.cairo_set_source_pixbuf (ctx, m_Pixbuf[cpt], 0, 0);
                    ctx.paint ();
                    m_Pattern[cpt] = new Cairo.Pattern.for_surface (surface);
                }
            }
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            if (m_Pattern[m_State] != null)
            {
                Cairo.Matrix matrix = Cairo.Matrix.identity ();
                matrix.translate (-x, -y);
                m_Pattern[m_State].set_matrix (matrix);
                get_style ().set_fill_options (inContext);
                inContext.set_source (m_Pattern[m_State]);
                inContext.paint ();
            }
        }

        public bool
        on_button_press_event (Goo.CanvasItem inItem, Gdk.EventButton inEvent)
        {
            m_State = State.PRESS;
            changed (true);
            return false;
        }

        public bool
        on_button_release_event (Goo.CanvasItem inItem, Gdk.EventButton inEvent)
        {
            m_State = State.RELEASE;
            changed (true);
            clicked ();
            return false;
        }
    }
}

