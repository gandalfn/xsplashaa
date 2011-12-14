/* cairo-context.vala
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

        /**
         * Sets the source pattern within context to a diagonal gradient.
         *
         * @param inColor the begin color of gradient
         * @param inShadeColor the end color of gradient
         * @param inW the width of rectangle where apply the pattern
         * @param inH the height of rectangle where apply the pattern
         * @param inInvert invert the begin and end colors of gradient
         * @param inVariance the shade variance of begin and end colors
         */
        public void
        diagonal_gradient(Gdk.Color inColor, Gdk.Color inShadeColor,
                          double inW, double inH, bool inInvert, double inVariance)
        {
            double angle = GLib.Math.atan(inW * 1.16 / inH);
            double offset = (inH * 0.5) / GLib.Math.tan(angle);
            Gdk.Color start;
            Gdk.Color end;

            if (inInvert)
            {
                start = CairoColor.shade(inShadeColor, 1 - inVariance);
                end = CairoColor.shade(inColor, 1 + inVariance);
            }
            else
            {
                end = CairoColor.shade(inShadeColor, 1 - inVariance);
                start = CairoColor.shade(inColor, 1 + inVariance);
            }
            CairoPattern linearGradient =
                new CairoPattern.linear(inW * 0.5 - offset, 0,
                                        inW * 0.5 + offset, inH);
            linearGradient.add_gdk_color_stop_rgb(0.0, start);
            linearGradient.add_gdk_color_stop_rgb(0.4, start);
            linearGradient.add_gdk_color_stop_rgb(0.5, inColor);
            linearGradient.add_gdk_color_stop_rgb(0.6, end);
            linearGradient.add_gdk_color_stop_rgb(1.0, end);
            set_source(linearGradient);
        }

        public void
        shade_text(string inText, Pango.FontDescription inFtDesc,
                   Pango.Alignment inAlignment, Gdk.Color inColor,
                   Gdk.Color inShadeColor, double inAlpha, bool inInvert)
        {
            Pango.Layout layout = Pango.cairo_create_layout(this);
            int height, width;
            double x, y, delta;
            Gdk.Color start, end;

            set_source_gdk_color_rgba(inColor, inAlpha);
            layout.set_font_description(inFtDesc);
            layout.set_alignment(inAlignment);
            layout.set_markup(inText, -1);
            layout.get_pixel_size(out width, out height);

            if (inInvert)
            {
                start = CairoColor.shade(inShadeColor, 1.2);
                end = CairoColor.shade(inShadeColor, 0.8);
            }
            else
            {
                end = CairoColor.shade(inShadeColor, 1.2);
                start = CairoColor.shade(inShadeColor, 0.8);
            }
            x = -(double)width / 2.0;
            y = (double)height / 4.0;
            delta = (double)height / (double)layout.get_line_count();
            for (int cpt = 0; cpt < layout.get_line_count(); cpt++)
            {
                move_to(x - 1,y + (delta * cpt) - 1);
                set_source_gdk_color_rgba(start, inAlpha);
                Pango.cairo_show_layout_line(this, layout.get_line(cpt));
                move_to(x + 1, y + (delta * cpt) + 1);
                set_source_gdk_color_rgba(end, inAlpha);
                Pango.cairo_show_layout_line(this, layout.get_line(cpt));
                move_to(x, y + (delta * cpt));
                set_source_gdk_color_rgba(inColor, inAlpha);
                Pango.cairo_show_layout_line(this, layout.get_line(cpt));
            }
        }

        public void
        button (Gdk.Color inBg, Gdk.Color inColorActive, Gdk.Color inColorInactive,
                double inX, double inY, double inWidth, double inHeight,
                double inBorder, double inProgress, double inVariance)
        {
            save();
            translate(inX, inY);

            //Background
            diagonal_gradient(inBg, inBg, inWidth, inHeight, true, inVariance);
            rounded_rectangle(0.0, 0.0, inWidth, inHeight, inBorder, CairoCorner.ALL);
            fill();

            // Old state
            if (inProgress < 1.0)
            {
                //Background
                diagonal_gradient(inColorInactive, inColorInactive, inWidth, inHeight, true, inVariance);
                rounded_rectangle(0, 0, inWidth, inHeight, inBorder, CairoCorner.ALL);
                fill();

                //corners
                CairoPattern radialGradient = new CairoPattern.radial(inBorder, inBorder, 0.0, inBorder, inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(0, 0, inBorder, inBorder, inBorder, CairoCorner.TOPLEFT);
                fill ();

                radialGradient = new CairoPattern.radial(inWidth - inBorder, inBorder, 0.0, inWidth - inBorder, inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(inWidth - inBorder, 0, inBorder, inBorder, inBorder, CairoCorner.TOPRIGHT);
                fill ();

                radialGradient = new CairoPattern.radial(inBorder, inHeight - inBorder, 0.0, inBorder, inHeight - inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(0, inHeight- inBorder, inBorder, inBorder, inBorder, CairoCorner.BOTTOMLEFT);
                fill ();

                radialGradient = new CairoPattern.radial(inWidth - inBorder, inHeight - inBorder, 0.0, inWidth - inBorder, inHeight - inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(inWidth - inBorder, inHeight - inBorder, inBorder, inBorder, inBorder, CairoCorner.BOTTOMRIGHT);
                fill ();

                // Borders
                CairoPattern linearGradient = new CairoPattern.linear(inBorder, inHeight / 2.0, 0, inHeight / 2.0);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(linearGradient);
                rectangle(0, inBorder, inBorder, inHeight - (inBorder*2));
                fill ();

                linearGradient = new CairoPattern.linear(inWidth / 2.0, inBorder, inWidth / 2.0, 0);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(linearGradient);
                rectangle(inBorder, 0, inWidth - (inBorder*2), inBorder);
                fill ();

                linearGradient = new CairoPattern.linear(inWidth - inBorder, inHeight / 2.0, inWidth, inHeight / 2.0);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(linearGradient);
                rectangle(inWidth - inBorder, inBorder, inBorder, inHeight - (inBorder*2));
                fill ();

                linearGradient = new CairoPattern.linear(inWidth / 2.0, inHeight - inBorder, inWidth / 2.0, inHeight);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorInactive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorInactive, 0.1);
                set_source(linearGradient);
                rectangle(inBorder, inHeight - inBorder, inWidth - (inBorder*2), inBorder);
                fill ();

                // And finally the real background
                set_source_gdk_color_rgb (inColorInactive);
                rectangle(inBorder, inBorder, inWidth - (inBorder*2), inHeight - (inBorder*2));
                fill ();
            }

            if (inProgress > 0.0)
            {
                new_path();
                rectangle ((inWidth / 2.0) - (inWidth * inProgress) / 2.0, (inHeight / 2.0) - (inHeight * inProgress) / 2.0, inWidth * inProgress, inHeight * inProgress);
                close_path();
                clip();

                //Background
                diagonal_gradient(inColorActive, inColorActive, inWidth, inHeight, false, inVariance);
                rounded_rectangle(0, 0, inWidth, inHeight, inBorder, CairoCorner.ALL);
                fill();

                //corners
                CairoPattern radialGradient = new CairoPattern.radial(inBorder, inBorder, 0.0, inBorder, inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(0, 0, inBorder, inBorder, inBorder, CairoCorner.TOPLEFT);
                fill ();

                radialGradient = new CairoPattern.radial(inWidth - inBorder, inBorder, 0.0, inWidth - inBorder, inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(inWidth - inBorder, 0, inBorder, inBorder, inBorder, CairoCorner.TOPRIGHT);
                fill ();

                radialGradient = new CairoPattern.radial(inBorder, inHeight - inBorder, 0.0, inBorder, inHeight - inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(0, inHeight - inBorder, inBorder, inBorder, inBorder, CairoCorner.BOTTOMLEFT);
                fill ();

                radialGradient = new CairoPattern.radial(inWidth - inBorder, inHeight - inBorder, 0.0, inWidth - inBorder, inHeight - inBorder, inBorder);
                radialGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                radialGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(radialGradient);
                rounded_rectangle(inWidth - inBorder, inHeight - inBorder, inBorder, inBorder, inBorder, CairoCorner.BOTTOMRIGHT);
                fill ();

                // Borders
                CairoPattern linearGradient = new CairoPattern.linear(inBorder, inHeight / 2.0, 0, inHeight / 2.0);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(linearGradient);
                rectangle(0, inBorder, inBorder, inHeight - (inBorder*2));
                fill ();

                linearGradient = new CairoPattern.linear(inWidth / 2.0, inBorder, inWidth / 2.0, 0);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(linearGradient);
                rectangle(inBorder, 0, inWidth - (inBorder*2), inBorder);
                fill ();

                linearGradient = new CairoPattern.linear(inWidth - inBorder, inHeight / 2.0, inWidth, inHeight / 2.0);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(linearGradient);
                rectangle(inWidth - inBorder, inBorder, inBorder, inHeight - (inBorder * 2));
                fill ();

                linearGradient = new CairoPattern.linear(inWidth / 2.0, inHeight - inBorder, inWidth / 2.0, inHeight);
                linearGradient.add_gdk_color_stop_rgba(0.1, inColorActive, 1.0);
                linearGradient.add_gdk_color_stop_rgba(1.0, inColorActive, 0.1);
                set_source(linearGradient);
                rectangle(inBorder, inHeight - inBorder, inWidth - (inBorder * 2), inBorder);
                fill ();

                // And finally the real background
                set_source_gdk_color_rgb (inColorActive);
                rectangle(inBorder, inBorder, inWidth - (inBorder * 2), inHeight - (inBorder * 2));
                fill ();
            }

            restore();
        }
    }
}

