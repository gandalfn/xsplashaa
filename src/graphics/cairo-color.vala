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
    /**
     * Miscellaneous functions for color manipulation
     */
    namespace CairoColor
    {
        ////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////
        /**
         * Compute HLS color from RGB color
         *
         * @param inoutRed red component in input hue component on output
         * @param inoutGreen green component in input light component on output
         * @param inoutBlue blue component in input sat component on output
         */
        public static void
        rgb_to_hls (ref double inoutRed, ref double inoutGreen, ref double inoutBlue)
        {
            double min;
            double max;
            double red;
            double green;
            double blue;
            double h, l, s;
            double delta;

            red = inoutRed;
            green = inoutGreen;
            blue = inoutBlue;

            if (red > green)
            {
                if (red > blue)
                    max = red;
                else
                    max = blue;

                if (green < blue)
                    min = green;
                else
                    min = blue;
            }
            else
            {
                if (green > blue)
                    max = green;
                else
                    max = blue;

                if (red < blue)
                    min = red;
                else
                    min = blue;
            }

            l = (max + min) / 2;
            s = 0;
            h = 0;

            if (max != min)
            {
                if (l <= 0.5)
                    s = (max - min) / (max + min);
                else
                    s = (max - min) / (2 - max - min);

                delta = max -min;
                if (red == max)
                    h = (green - blue) / delta;
                else if (green == max)
                    h = 2 + (blue - red) / delta;
                else if (blue == max)
                    h = 4 + (red - green) / delta;

                h *= 60;
                if (h < 0.0) h += 360;
            }

            inoutRed = h;
            inoutGreen = l;
            inoutBlue = s;
        }

        /**
         * Compute RGB color from HLS color
         *
         * @param inoutHue hue component in input red component on output
         * @param inoutLightness light component in input green component on output
         * @param inoutSaturation sat component in input blue component on output
         */
        public static void
        hls_to_rgb (ref double inoutHue, ref double inoutLightness, ref double inoutSaturation)
        {
            double hue;
            double lightness;
            double saturation;
            double m1, m2;
            double r, g, b;

            lightness = inoutLightness;
            saturation = inoutSaturation;

            if (lightness <= 0.5)
                m2 = lightness * (1 + saturation);
            else
                m2 = lightness + saturation - lightness * saturation;

            m1 = 2 * lightness - m2;

            if (saturation == 0)
            {
                inoutHue = lightness;
                inoutLightness = lightness;
                inoutSaturation = lightness;
            }
            else
            {
                hue = inoutHue + 120;
                while (hue > 360)
                    hue -= 360;
                while (hue < 0)
                    hue += 360;

                if (hue < 60)
                    r = m1 + (m2 - m1) * hue / 60;
                else if (hue < 180)
                    r = m2;
                else if (hue < 240)
                    r = m1 + (m2 - m1) * (240 - hue) / 60;
                else
                    r = m1;

                hue = inoutHue;
                while (hue > 360)
                    hue -= 360;
                while (hue < 0)
                    hue += 360;

                if (hue < 60)
                    g = m1 + (m2 - m1) * hue / 60;
                else if (hue < 180)
                    g = m2;
                else if (hue < 240)
                    g = m1 + (m2 - m1) * (240 - hue) / 60;
                else
                    g = m1;

                hue = inoutHue - 120;
                while (hue > 360)
                    hue -= 360;
                while (hue < 0)
                    hue += 360;

                if (hue < 60)
                    b = m1 + (m2 - m1) * hue / 60;
                else if (hue < 180)
                    b = m2;
                else if (hue < 240)
                    b = m1 + (m2 - m1) * (240 - hue) / 60;
                else
                    b = m1;

                inoutHue = r;
                inoutLightness = g;
                inoutSaturation = b;
            }
        }

        /**
         * Computes a lighter or darker variant of color
         *
         * @param inColor the color to compute from
         * @param inPercent Shading factor, a factor of 1.0 leaves the color unchanged,
         *                  smaller factors yield darker colors, larger factors
         *                  yield lighter colors.
         *
         * @return the computed color
         */
        public static Gdk.Color
        shade(Gdk.Color inColor, double inPercent)
        {
            Gdk.Color color = Gdk.Color();
            double red;
            double green;
            double blue;

            red   = (double)inColor.red / 65535.0;
            green = (double)inColor.green / 65535.0;
            blue  = (double)inColor.blue / 65535.0;

            rgb_to_hls (ref red, ref green, ref blue);

            green *= inPercent;
            if (green > 1.0)
                green = 1.0;
            else if (green < 0.0)
                green = 0.0;

            blue *= inPercent;
            if (blue > 1.0)
                blue = 1.0;
            else if (blue < 0.0)
                blue = 0.0;

            hls_to_rgb(ref red, ref green, ref blue);

            color.red = (uint16)(red * 65535.0);
            color.green = (uint16)(green * 65535.0);
            color.blue = (uint16)(blue * 65535.0);

            return color;
        }
    }
}

