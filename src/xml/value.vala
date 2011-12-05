/* value.vala
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

namespace XSAA
{
    public interface Value
    {
        private static bool s_SimpleTypeRegistered = false;

        private static void
        register_simple_type ()
        {
            GLib.Value.register_transform_func (typeof (string), typeof (double),
                                                (ValueTransform)string_to_double);
            GLib.Value.register_transform_func (typeof (double), typeof (string),
                                                (ValueTransform)double_to_string);

            GLib.Value.register_transform_func (typeof (string), typeof (int),
                                                (ValueTransform)string_to_int);
            GLib.Value.register_transform_func (typeof (int), typeof (string),
                                                (ValueTransform)int_to_string);

            GLib.Value.register_transform_func (typeof (string), typeof (bool),
                                                (ValueTransform)string_to_bool);
            GLib.Value.register_transform_func (typeof (bool), typeof (string),
                                                (ValueTransform)bool_to_string);

            s_SimpleTypeRegistered = true;
        }

        private static void
        double_to_string (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (double)))
        {
            double val = (double)inSrc;

            outDest = val.to_string ();
        }

        private static void
        string_to_double (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (string)))
            requires ((string)inSrc != null)
        {
            string val = (string)inSrc;

            outDest = double.parse (val);
        }

        private static void
        int_to_string (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (int)))
        {
            int val = (int)inSrc;

            outDest = val.to_string ();
        }

        private static void
        string_to_int (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (string)))
            requires ((string)inSrc != null)
        {
            string val = (string)inSrc;

            outDest = int.parse (val);
        }

        private static void
        bool_to_string (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (bool)))
        {
            bool val = (bool)inSrc;

            outDest = val.to_string ();
        }

        private static void
        string_to_bool (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (string)))
            requires ((string)inSrc != null)
        {
            string val = (string)inSrc;

            outDest = bool.parse (val);
        }

        public static GLib.Value
        from_string (Type inType, string inValue)
        {
            if (inType.is_classed ())
                inType.class_ref ();
            else if (!s_SimpleTypeRegistered)
                register_simple_type ();

            GLib.Value val = GLib.Value (inType);
            GLib.Value str = inValue;
            str.transform (ref val);

            return val;
        }
    }
}
