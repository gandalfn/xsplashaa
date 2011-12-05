/* xsaa-cairo-context.vala
 *
 * Copyright (C) 2009-2010  Nicolas Bruguier
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

namespace XSAA
{
    public enum CairoCorner
    {
        NONE        = 0,
        TOPLEFT     = 1,
        TOPRIGHT    = 2,
        BOTTOMLEFT  = 4,
        BOTTOMRIGHT = 8,
        ALL         = 15
    }

    public class CairoContext : Cairo.Context
    {
        // static methods
        private static inline uchar
        mult (uchar inC, uchar inA)
        {
            return inA > 0 ? inC * 255 / inA : 0;
        }

        // methods
        public CairoContext(Cairo.Surface inSurface)
        {
            base(inSurface);
        }

        public CairoContext.from_window(Gdk.Window inWindow)
        {
            base(Gdk.cairo_create(inWindow).get_target());
        }

        public CairoContext.from_widget(Gtk.Widget inWidget)
        {
            base(Gdk.cairo_create(inWidget.window).get_target());
        }

        public CairoContext.from_pixbuf(Gdk.Pixbuf inPixbuf)
        {
            Cairo.Surface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                                            inPixbuf.width, inPixbuf.width);

            base (surface);
        }

        public Gdk.Pixbuf
        to_pixbuf ()
        {
            Gdk.Pixbuf pixbuf = null;

            Cairo.ImageSurface surface = (Cairo.ImageSurface)get_target ();
            if (surface != null)
            {
                pixbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8,
                                         surface.get_width (), surface.get_height ());
                unowned uchar* dst = pixbuf.get_pixels ();
                unowned uchar* src = surface.get_data ();
                for (int i = 0; i < pixbuf.height; i++)
                {
                    for (int j = 0; j < pixbuf.width; j++)
                    {
                        dst[0] = mult (src[2], src[3]);
                        dst[1] = mult (src[1], src[3]);
                        dst[2] = mult (src[0], src[3]);
                        dst[3] = src[3];
                        src += 4;
                        dst += 4;
                    }
                    src += pixbuf.rowstride - pixbuf.width * 4;
                    dst += pixbuf.rowstride - pixbuf.width * 4;
                }
           }

           return pixbuf;
        }

        public void
        set_source_gdk_color_rgb(Gdk.Color inColor)
        {
            set_source_rgb((double)inColor.red / 65535.0,
                           (double)inColor.green / 65535.0,
                           (double)inColor.blue / 65535.0);
        }

        public void
        set_source_gdk_color_rgba(Gdk.Color inColor, double inAlpha)
        {
            set_source_rgba((double)inColor.red / 65535.0,
                            (double)inColor.green / 65535.0,
                            (double)inColor.blue / 65535.0,
                            inAlpha);
        }

        public void
        rounded_rectangle(double inX, double inY, double inW, double inH,
                          double inRadius, CairoCorner inCorners)
        {
            if ((inCorners & CairoCorner.TOPLEFT) == CairoCorner.TOPLEFT)
                move_to(inX + inRadius, inY);
            else
                move_to(inX, inY);

            if ((inCorners & CairoCorner.TOPRIGHT) == CairoCorner.TOPRIGHT)
                arc(inX + inW - inRadius, inY + inRadius, inRadius, GLib.Math.PI * 1.5, GLib.Math.PI * 2);
            else
                line_to(inX + inW, inY);

            if ((inCorners & CairoCorner.BOTTOMRIGHT) == CairoCorner.BOTTOMRIGHT)
                arc(inX + inW - inRadius, inY + inH - inRadius, inRadius, 0, GLib.Math.PI * 0.5);
            else
                line_to(inX + inW, inY + inH);

            if ((inCorners & CairoCorner.BOTTOMLEFT) == CairoCorner.BOTTOMLEFT)
                arc(inX + inRadius, inY + inH - inRadius, inRadius, GLib.Math.PI * 0.5, GLib.Math.PI);
            else
                line_to(inX, inY + inH);

            if ((inCorners & CairoCorner.TOPLEFT) == CairoCorner.TOPLEFT)
                arc(inX + inRadius, inY + inRadius, inRadius, GLib.Math.PI, GLib.Math.PI * 1.5);
            else
                move_to(inX, inY);
        }


    }
}
