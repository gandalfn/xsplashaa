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


        // accessors
        public override string node_name {
            get {
                return "button";
            }
        }

        public string filename_press {
            set {
                try
                {
                    m_Handle[State.PRESS] = new Rsvg.Handle.from_file (value);
                    if (width <= 0)
                        width = m_Handle[State.PRESS].width;
                    if (height <= 0)
                        height = m_Handle[State.PRESS].height;
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
                    if (width <= 0)
                        width = m_Handle[State.RELEASE].width;
                    if (height <= 0)
                        height = m_Handle[State.RELEASE].height;
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
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            if (m_Handle[m_State] != null)
            {
                inContext.save ();
                inContext.scale (width / m_Handle[m_State].width, height / m_Handle[m_State].height);
                get_style ().set_fill_options (inContext);
                m_Handle[m_State].render_cairo (inContext);
                inContext.restore ();
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
