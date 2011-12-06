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
    public class ProgressBar : Widget
    {
        // accessors
        public override string node_name {
            get {
                return "progressbar";
            }
        }

        public int bar_height {
            set {
                ((SegmentedBar)composite_widget).BarHeight = value;
            }
        }

        public string bar_color {
            set {
                Gdk.Color color;
                if (Gdk.Color.parse (value, out color))
                {
                    ((SegmentedBar)composite_widget).AddSegmentRgba ("", 0.0, 0);
                    ((SegmentedBar)composite_widget).AddSegmentB ("", 0.0, SegmentedBar.GdkColorToCairoColorA (color));
                    ((SegmentedBar)composite_widget).AddSegmentRgba ("", 1.0, 0);
                }
            }
        }

        public double percent {
            set {
                ((SegmentedBar)composite_widget).UpdateSegment (1, 0);
                ((SegmentedBar)composite_widget).UpdateSegment (2, value);
                ((SegmentedBar)composite_widget).UpdateSegment (3, (1.0 - value));
                composite_widget.queue_draw ();
            }
        }

        // methods
        construct
        {
            SegmentedBar progress = new SegmentedBar ();
            progress.ShowReflection = true;
            progress.ShowLabels = false;
            composite_widget = progress;
        }
    }
}
