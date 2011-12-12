/* image.vala
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
    public class Image : Item
    {
        // properties
        private Gdk.Pixbuf    m_Pixbuf;
        private Cairo.Pattern m_Pattern;

        // accessors
        public override string node_name {
            get {
                return "image";
            }
        }

        public override double width {
            get {
                return base.width;
            }
            set {
                if (base.width != value)
                {
                    m_Pattern = null;
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
                    m_Pattern = null;
                    base.height = value;
                }
            }
        }

        public Gdk.Pixbuf pixbuf {
            set {
                Log.debug ("Set image pixbuf");
                m_Pixbuf = value;
                if (width <= 0)
                    width = m_Pixbuf.width;
                if (height <= 0)
                    height = m_Pixbuf.height;
                m_Pattern = null;
                changed (false);
            }
        }

        // methods
        public override void
        simple_update (Cairo.Context inContext)
        {
            base.simple_update (inContext);

            if (m_Pattern == null && m_Pixbuf != null)
            {
                var surface = new Cairo.Surface.similar (inContext.get_target (), Cairo.Content.COLOR_ALPHA,
                                                         (int)width, (int)height);
                var ctx = new Cairo.Context (surface);
                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.scale (width / m_Pixbuf.width, height / m_Pixbuf.height);
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
                matrix.translate (-x, -y);
                m_Pattern.set_matrix (matrix);
                get_style ().set_fill_options (inContext);
                inContext.set_source (m_Pattern);
                inContext.paint ();
            }
        }
    }
}
