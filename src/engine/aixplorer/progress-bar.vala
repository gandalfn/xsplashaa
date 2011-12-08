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
        // properties
        private XSAA.Animator m_Animator;
        SegmentedBar.Segment  m_Before;
        SegmentedBar.Segment  m_Value;
        SegmentedBar.Segment  m_After;

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
                    if (m_Before == null)
                    {
                        m_Before = new SegmentedBar.Segment ("", 0, SegmentedBar.BarColour (0, 0, 0, 0), false);
                        ((SegmentedBar)composite_widget).AddSegment (m_Before);
                        uint transition = m_Animator.add_transition (0.0, 0.5, XSAA.Animator.ProgressType.SINUSOIDAL, () => {
                            composite_widget.queue_draw ();
                            return false;
                        }, null);
                        GLib.Value from = (double)0.0;
                        GLib.Value to = (double)0.9;
                        m_Animator.add_transition_property (transition, m_Before, "Percent", from, to);

                        transition = m_Animator.add_transition (0.5, 1.0, XSAA.Animator.ProgressType.SINUSOIDAL, () => {
                            composite_widget.queue_draw ();
                            return false;
                        }, null);
                        m_Animator.add_transition_property (transition, m_Before, "Percent", to, from);
                    }
                    if (m_Value == null)
                    {
                        m_Value = new SegmentedBar.Segment ("", 1, SegmentedBar.GdkColorToCairoColorA (color), true);
                        ((SegmentedBar)composite_widget).AddSegment (m_Value);
                    }
                    else
                    {
                        m_Value.Color = SegmentedBar.GdkColorToCairoColorA (color);
                    }
                    if (m_After == null)
                    {
                        m_After = new SegmentedBar.Segment ("", 1, SegmentedBar.BarColour (0, 0, 0, 0), false);
                        ((SegmentedBar)composite_widget).AddSegment (m_After);
                        uint transition = m_Animator.add_transition (0.0, 0.5, XSAA.Animator.ProgressType.SINUSOIDAL, null, null);
                        GLib.Value from = (double)0.1;
                        GLib.Value to = (double)1.0;
                        m_Animator.add_transition_property (transition, m_After, "Percent", from, to);

                        transition = m_Animator.add_transition (0.5, 1.0, XSAA.Animator.ProgressType.SINUSOIDAL, null, null);
                        m_Animator.add_transition_property (transition, m_After, "Percent", to, from);
                    }
                }
            }
        }

        public double percent {
            set {
                m_Animator.stop ();

                m_Before.Percent = 0.0;
                m_Value.Percent = value;
                m_After.Percent = 1.0 - value;

                changed (true);
            }
        }

        // methods
        construct
        {
            SegmentedBar progress = new SegmentedBar ();
            progress.ShowReflection = true;
            progress.ShowLabels = false;
            composite_widget = progress;

            m_Animator = new XSAA.Animator(60, 2000);
            m_Animator.loop = true;
        }

        public void
        pulse ()
        {
            m_Value.Percent = 0.1;
            m_Animator.start ();
        }
    }
}

