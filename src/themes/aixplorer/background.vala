/* background.vala
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
    public class Background : Goo.CanvasItemSimple
    {
        // properties
        private string        m_Theme;
        private Gdk.Pixbuf    m_Pixbuf;
        private double        m_X = 0.0;
        private double        m_Y = 0.0;
        private double        m_Width = 0.0;
        private double        m_Height = 0.0;
        private Cairo.Pattern m_Pattern;

        // accessors
        public double x {
            get {
                return m_X;
            }
            construct set {
                m_X = value;
                changed (true);
            }
        }

        public double y {
            get {
                return m_Y;
            }
            construct set {
                m_Y = value;
                changed (true);
            }
        }

        public double width {
            get {
                return m_Width;
            }
            construct set {
                m_Width = value;
                m_Pattern = null;
                changed (true);
            }
        }

        public double height {
            get {
                return m_Height;
            }
            construct set {
                m_Height = value;
                m_Pattern = null;
                changed (true);
            }
        }

        // methods
        public Background (Goo.CanvasItem inParent, string inThemeName, double inX, double inY)
        {
            GLib.Object ();

            inParent.add_child (this, 0);

            m_X = inX;
            m_Y = inY;

            m_Theme = inThemeName;

            m_Pixbuf = new Gdk.Pixbuf.from_file ("/usr/share/xsplashaa/leaves/background.png");
        }

        public override bool
        simple_is_item_at (double inX, double inY, Cairo.Context inContext, bool inIsPointerEvent)
        {
            return (inX >= m_X && (inX <= m_X + m_Width) && inY >= m_Y || (inY <= m_Y + m_Height));
        }

        public override void
        simple_update (Cairo.Context inContext)
        {
            bounds.x1 = m_X;
            bounds.y1 = m_Y;
            bounds.x2 = m_X + m_Width;
            bounds.y2 = m_Y + m_Height;

            if (m_Pattern == null)
            {
                var surface = new Cairo.Surface.similar (inContext.get_target (), Cairo.Content.COLOR_ALPHA,
                                                         (int)m_Width, (int)m_Height);
                var ctx = new Cairo.Context (surface);
                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.scale (m_Width / m_Pixbuf.width, m_Height / m_Pixbuf.height);
                Gdk.cairo_set_source_pixbuf (ctx, m_Pixbuf, 0, 0);
                ctx.paint ();
                m_Pattern = new Cairo.Pattern.for_surface (surface);
            }
        }

        public override void
        simple_paint (Cairo.Context inContext, Goo.CanvasBounds inBounds)
        {
            if (m_Pattern != null)
            {
                Cairo.Matrix matrix = Cairo.Matrix.identity ();
                matrix.translate (-m_X, -m_Y);
                m_Pattern.set_matrix (matrix);
                get_style ().set_fill_options (inContext);
                inContext.set_source (m_Pattern);
                inContext.paint ();
            }
        }
    }
}
