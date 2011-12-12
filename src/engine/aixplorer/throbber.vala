/* throbber.vala
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
    public class Throbber : Item
    {
        // properties
        private Animator               m_Animator;
        private Cairo.Pattern          m_Initial = null;
        private Cairo.Pattern          m_Finish = null;
        private Cairo.Pattern[]        m_Frames;
        private unowned Cairo.Pattern? m_Current = null;

        // accessors
        public override string node_name {
            get {
                return "throbber";
            }
        }

        public int step {
            set {
                m_Current = m_Frames [value];
                changed (false);
            }
        }

        public string theme_name {
            set {
                m_Initial = null;
                load_patterns (value);
            }
        }

        // methods
        construct
        {
            notify["visibility"].connect (() => {
                if (visibility <= Goo.CanvasItemVisibility.INVISIBLE)
                {
                    Log.debug ("stop thobber");
                    m_Animator.stop ();
                }
            });
        }

        private static Cairo.Pattern
        pixbuf_to_pattern (Gdk.Pixbuf inPixbuf)
        {
            var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                                  (int)inPixbuf.get_width (), (int)inPixbuf.get_height ());
            var ctx = new Cairo.Context (surface);
            ctx.set_operator (Cairo.Operator.SOURCE);
            Gdk.cairo_set_source_pixbuf (ctx, inPixbuf, 0, 0);
            ctx.paint ();
            return new Cairo.Pattern.for_surface (surface);
        }

        private void
        load_patterns (string inName)
        {
            try
            {
                Gdk.Pixbuf spinner = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + inName + "/throbber-spinner.png");

                Gdk.Pixbuf initial = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + inName + "/throbber-initial.png");
                m_Initial = pixbuf_to_pattern (initial);

                Gdk.Pixbuf finish = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + inName + "/throbber-finish.png");
                m_Finish = pixbuf_to_pattern (finish);

                uint size = initial.get_width() > initial.get_height() ? initial.get_width() : initial.get_height();

                int nb_steps = (spinner.get_height() * spinner.get_width()) / (int)(size * size);

                m_Frames = new Cairo.Pattern [nb_steps];
                int cpt = 0;
                for (uint i = 0; i < spinner.get_height(); i += size)
                {
                    for (uint j = 0; j < spinner.get_width(); j += size, ++cpt)
                    {
                        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.subpixbuf(spinner, (int)j,
                                                                    (int)i, (int)size,
                                                                    (int)size);
                        m_Frames[cpt] = pixbuf_to_pattern (pixbuf);
                    }
                }

                m_Current = m_Initial;

                width = initial.get_width ();
                height = initial.get_height ();

                m_Animator = new Animator (nb_steps, 2000);
                m_Animator.loop = true;
                uint transition = m_Animator.add_transition (0.0, 1.0, XSAA.Animator.ProgressType.LINEAR, null, null);
                GLib.Value from = (int)1;
                GLib.Value to = (int)nb_steps - 1;
                m_Animator.add_transition_property (transition, this, "step", from, to);
            }
            catch (GLib.Error err)
            {
                Log.warning ("Error on loading throbber: %s", err.message);
            }
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            if (m_Current != null)
            {
                Cairo.Matrix matrix = Cairo.Matrix.identity ();
                matrix.translate (-x, -y);
                m_Current.set_matrix (matrix);
                get_style ().set_fill_options (inContext);
                inContext.set_source (m_Current);
                inContext.rectangle (x, y, width, height);
                inContext.fill ();
            }
        }

        public void
        start ()
        {
            m_Animator.start ();
        }

        public void
        stop ()
        {
            m_Animator.stop ();
        }

        public void
        finished ()
        {
            m_Animator.stop ();
            m_Current = m_Finish;
            changed (false);
        }
    }
}
