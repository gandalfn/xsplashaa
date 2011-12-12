/* progress-bar.vala
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
    public class ProgressBar : Item
    {
        // properties
        private XSAA.Animator m_Animator;
        private double        m_Percent;
        private double        m_Pulse = 0.0;
        private bool          m_Reflect = true;

        // accessors
        public override string node_name {
            get {
                return "progressbar";
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

        public double pulse_progress {
            get {
                 return m_Pulse;
            }
            set {
                m_Pulse = value;
                changed (false);
            }
        }

        public double percent {
            get {
                return m_Percent;
            }
            set {
                m_Animator.stop ();
                m_Percent = value;
                changed (false);
            }
        }

        // methods
        construct
        {
            m_Animator = new XSAA.Animator(20, 2000);
            m_Animator.loop = true;
            uint transition = m_Animator.add_transition (0.0, 0.5, XSAA.Animator.ProgressType.SINUSOIDAL, null, null);
            GLib.Value from = (double)0.0;
            GLib.Value to = (double)0.9;
            m_Animator.add_transition_property (transition, this, "pulse_progress", from, to);
            transition = m_Animator.add_transition (0.5, 1.0, XSAA.Animator.ProgressType.SINUSOIDAL, null, null);
            m_Animator.add_transition_property (transition, this, "pulse_progress", to, from);

            width = 200;

            notify["visibility"].connect (() => {
                if (visibility <= Goo.CanvasItemVisibility.INVISIBLE)
                {
                    m_Animator.stop ();
                }
            });
        }

        private Cairo.Pattern
        render_bar (double inWidth, double inHeight)
        {
            Cairo.Surface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                                            (int)inWidth, (int)inHeight);
            Cairo.Context ctx = new Cairo.Context (surface);

            render_bar_segments (ctx, inWidth, inHeight, inHeight / 2.0);
            render_bar_strokes (ctx, inWidth, inHeight, inHeight / 2.0);

            return new Cairo.Pattern.for_surface (surface);
        }

        private void
        render_bar_segments (Cairo.Context inContext, double inWidth, double inHeight, double inRadius)
        {
            Cairo.Pattern grad = new Cairo.Pattern.linear (0, 0, inWidth, 0);
            Gdk.Color color;
            double alpha;
            CairoColor.rgba_to_color (fill_color_rgba, out color, out alpha);

            if (m_Animator.is_playing)
            {
                grad.add_color_stop_rgba (0.0, 0, 0, 0, 0.0);
                grad.add_color_stop_rgba (double.max (0.0, m_Pulse), 0, 0, 0, 0.0);
                grad.add_color_stop_rgba (double.max (0.0, m_Pulse),
                                          (double)color.red / 65535.0,
                                          (double)color.green / 65535.0,
                                          (double)color.blue / 65535.0, 1.0);
                grad.add_color_stop_rgba (double.min (1.0, m_Pulse + 0.1),
                                          (double)color.red / 65535.0,
                                          (double)color.green / 65535.0,
                                          (double)color.blue / 65535.0, 1.0);
                grad.add_color_stop_rgba (double.min (1.0, m_Pulse + 0.1), 0, 0, 0, 0);
                grad.add_color_stop_rgba (1.0, 0, 0, 0, 0);
            }
            else
            {
                grad.add_color_stop_rgba (0, (double)color.red / 65535.0,
                                             (double)color.green / 65535.0,
                                             (double)color.blue / 65535.0, 1.0);
                grad.add_color_stop_rgba (m_Percent, (double)color.red / 65535.0,
                                                     (double)color.green / 65535.0,
                                                     (double)color.blue / 65535.0, 1.0);
                grad.add_color_stop_rgba (m_Percent, 0, 0, 0, 0);
                grad.add_color_stop_rgba (1.0, 0, 0, 0, 0);
            }

            ((CairoContext)inContext).rounded_rectangle (0, 0, inWidth, inHeight, inRadius, CairoCorner.ALL);
            inContext.set_source(grad);
            inContext.fill_preserve ();

            grad = new Cairo.Pattern.linear (0, 0, 0, inHeight);
            grad.add_color_stop_rgba(0.0, 1, 1, 1, 0.125);
            grad.add_color_stop_rgba(0.35, 1, 1, 1, 0.255);
            grad.add_color_stop_rgba(1, 0, 0, 0, 0.4);
            inContext.set_source(grad);
            inContext.fill ();
        }

        private void
        render_bar_strokes (Cairo.Context inContext, double inWidth, double inHeight, double inRadius)
        {
            Gdk.Color black, white;
            Gdk.Color.parse ("#000000", out black);
            Gdk.Color.parse ("#FFFFFF", out white);

            Cairo.Pattern stroke = make_segment_gradient (inHeight, black, 0.25);
            Cairo.Pattern seg_sep_light = make_segment_gradient (inHeight, white, 0.125);
            Cairo.Pattern seg_sep_dark = make_segment_gradient (inHeight, black, 0.125);

            inContext.set_line_width (1);

            double seg_w = 20;
            double x = seg_w > inRadius ? seg_w : inRadius;

            while (x <= inWidth - inRadius)
            {
                inContext.move_to (x - 0.5, 1);
                inContext.line_to (x - 0.5, inHeight - 1);
                inContext.set_source (seg_sep_light);
                inContext.stroke ();

                inContext.move_to (x + 0.5, 1);
                inContext.line_to (x + 0.5, inHeight - 1);
                inContext.set_source (seg_sep_dark);
                inContext.stroke ();

                x += seg_w;
            }

            ((CairoContext)inContext).rounded_rectangle (0.5, 0.5, inWidth - 1.0, inHeight - 1.0, inRadius, CairoCorner.ALL);
            inContext.set_source(stroke);
            inContext.stroke ();
        }

        private Cairo.Pattern
        make_segment_gradient (double inHeight, Gdk.Color inColor, double inAlpha)
        {
            Cairo.Pattern grad = new Cairo.Pattern.linear(0, 0, 0, inHeight);

            Gdk.Color color = CairoColor.shade (inColor, 1.1);
            grad.add_color_stop_rgba(0, (double)color.red / 65535.0,
                                        (double)color.green / 65535.0,
                                        (double)color.blue / 65535.0, inAlpha);

            color = CairoColor.shade (inColor, 1.2);
            grad.add_color_stop_rgba(0, (double)color.red / 65535.0,
                                        (double)color.green / 65535.0,
                                        (double)color.blue / 65535.0, inAlpha);

            color = CairoColor.shade (inColor, 0.8);
            grad.add_color_stop_rgba(1, (double)color.red / 65535.0,
                                        (double)color.green / 65535.0,
                                        (double)color.blue / 65535.0, inAlpha);

            return grad;
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            Cairo.Matrix matrix = Cairo.Matrix.identity ();
            matrix.translate (-x, -y);
            Cairo.Pattern bar = render_bar (base.width, base.height);
            bar.set_matrix (matrix);

            inContext.rectangle (0, 0, base.width, base.height);
            inContext.set_source (bar);
            inContext.fill ();

            if (m_Reflect)
            {
                inContext.save ();

                inContext.rectangle (0, base.height, base.width, base.height);
                inContext.clip ();

                Cairo.Matrix m = Cairo.Matrix(1, 0, 0, 1, 0, 0);
                m.scale (1.0, -1.0);
                m.translate (0, -(2 * base.height) + 1);

                inContext.transform (m);

                get_style ().set_fill_options (inContext);
                inContext.set_source (bar);

                Cairo.Pattern mask = new Cairo.Pattern.linear(0, 0, 0, base.height);
                mask.add_color_stop_rgba(0.25, 0, 0, 0, 0);
                mask.add_color_stop_rgba(0.5, 0, 0, 0, 0.125);
                mask.add_color_stop_rgba(0.75, 0, 0, 0, 0.4);
                mask.add_color_stop_rgba(1.0, 0, 0, 0, 0.4);

                inContext.mask (mask);

                inContext.restore ();
            }
        }

        public void
        pulse ()
        {
            m_Animator.start ();
        }
    }
}
