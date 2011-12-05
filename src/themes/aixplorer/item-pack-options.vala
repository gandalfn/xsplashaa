/* item-pack-options.vala
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
    public interface ItemPackOptions : Goo.CanvasItemSimple, XSAA.EngineItem
    {
        // accessors
        public abstract bool   expand         { get; set; default = false; }
        public abstract int    row            { get; set; default = 0; }
        public abstract int    column         { get; set; default = 0; }
        public abstract int    rows           { get; set; default = 1; }
        public abstract int    columns        { get; set; default = 1; }
        public abstract double top_padding    { get; set; default = 0.0; }
        public abstract double bottom_padding { get; set; default = 0.0; }
        public abstract double left_padding   { get; set; default = 0.0; }
        public abstract double right_padding  { get; set; default = 0.0; }
        public abstract double x_align        { get; set; default = 0.5; }
        public abstract bool   x_expand       { get; set; default = true; }
        public abstract bool   x_fill         { get; set; default = false; }
        public abstract bool   x_shrink       { get; set; default = false; }
        public abstract double y_align        { get; set; default = 0.5; }
        public abstract bool   y_expand       { get; set; default = true; }
        public abstract bool   y_fill         { get; set; default = false; }
        public abstract bool   y_shrink       { get; set; default = false; }
    }
}
