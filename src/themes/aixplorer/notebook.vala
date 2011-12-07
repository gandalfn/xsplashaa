/* table.vala
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
    public class Notebook : Goo.CanvasTable, Goo.CanvasItem, XSAA.EngineItem, ItemPackOptions
    {
        // types
        public class Animation : GLib.Object
        {
            // types
            public enum AnimType
            {
                VERTICAL_SLIDE,
                HORIZONTAL_SLIDE;

                public string
                to_string ()
                {
                    switch (this)
                    {
                        case VERTICAL_SLIDE:
                            return "vertical-slide";
                        case HORIZONTAL_SLIDE:
                            return "horizontal-slide";
                    }

                    return "";
                }

                public static AnimType
                from_string (string inType)
                {
                    switch (inType)
                    {
                        case "vertical-slide":
                            return VERTICAL_SLIDE;
                        case "horizontal-slide":
                            return HORIZONTAL_SLIDE;
                    }

                    return HORIZONTAL_SLIDE;
                }
            }

            // properties
            private unowned Notebook m_Notebook;
            private Animator         m_Animator;
            private Goo.CanvasItem   m_Previous;
            private Goo.CanvasItem   m_Current;

            // signals
            public signal void finished ();

            // methods
            public Animation (Notebook inNotebook, AnimType inType, Goo.CanvasItem inPrevious, Goo.CanvasItem inCurrent)
            {
                m_Notebook = inNotebook;
                m_Animator = new Animator (60, 400);
                m_Previous = inPrevious;
                m_Current = inCurrent;

                switch (inType)
                {
                    case AnimType.HORIZONTAL_SLIDE:
                        create_horizontal_slide ();
                        break;

                    case AnimType.VERTICAL_SLIDE:
                        create_vertical_slide ();
                        break;
                }
            }

            private void
            create_horizontal_slide ()
            {
                double previous_x, current_x, current_width;
                ((GLib.Object)m_Previous).get ("x", out previous_x);
                ((GLib.Object)m_Current).get ("x", out current_x);
                ((GLib.Object)m_Current).get ("width", out current_width);

                uint transition = m_Animator.add_transition (0.0, 1.0, XSAA.Animator.ProgressType.SINUSOIDAL, null, on_finished);

                if (((ItemPackOptions)m_Current).page_num > ((ItemPackOptions)m_Previous).page_num)
                {
                    GLib.Value from = (double)previous_x;
                    GLib.Value to = (double)previous_x - (m_Notebook.bounds.x2 - m_Notebook.bounds.x1);
                    m_Animator.add_transition_property (transition, m_Previous, "x", from, to);

                    from = (double)current_x + (m_Notebook.bounds.x2 - m_Notebook.bounds.x1);
                    to = (double)current_x;
                    m_Animator.add_transition_property (transition, m_Current, "x", from, to);

                    // TODO: set current pos on start
                    m_Current.set_property ("x", from);
                }
                else
                {
                    GLib.Value from = (double)previous_x;
                    GLib.Value to = (double)previous_x + (m_Notebook.bounds.x2 - m_Notebook.bounds.x1);
                    m_Animator.add_transition_property (transition, m_Previous, "x", from, to);

                    from = (double)m_Notebook.bounds.x1 - current_width;
                    to = (double)current_x;
                    m_Animator.add_transition_property (transition, m_Current, "x", from, to);

                    // TODO: set current pos on start
                    m_Current.set_property ("x", from);
                }
            }

            private void
            create_vertical_slide ()
            {
                double previous_y, current_y;
                ((GLib.Object)m_Previous).get ("y", out previous_y);
                ((GLib.Object)m_Current).get ("y", out current_y);

                uint transition = m_Animator.add_transition (0.0, 1.0, XSAA.Animator.ProgressType.SINUSOIDAL, null, on_finished);

                if (((ItemPackOptions)m_Current).page_num > ((ItemPackOptions)m_Previous).page_num)
                {
                    GLib.Value from = (double)previous_y;
                    GLib.Value to = (double)previous_y - (m_Notebook.bounds.y2 - m_Notebook.bounds.y1);
                    m_Animator.add_transition_property (transition, m_Previous, "y", from, to);

                    from = (double)current_y + (m_Notebook.bounds.y2 - m_Notebook.bounds.y1);
                    to = (double)current_y;
                    m_Animator.add_transition_property (transition, m_Current, "y", from, to);

                    // TODO: set current pos on start
                    m_Current.set_property ("y", from);
                }
                else
                {
                    GLib.Value from = (double)previous_y;
                    GLib.Value to = (double)previous_y + (m_Notebook.bounds.y2 - m_Notebook.bounds.y1);
                    m_Animator.add_transition_property (transition, m_Previous, "y", from, to);

                    from = (double)current_y - (m_Notebook.bounds.y2 - m_Notebook.bounds.y1);
                    to = (double)current_y;
                    m_Animator.add_transition_property (transition, m_Current, "y", from, to);

                    // TODO: set current pos on start
                    m_Current.set_property ("y", from);
                }
            }

            private void
            on_finished ()
            {
                if (m_Previous != null)
                {
                    // TODO: set current pos on start
                    GLib.Value y_val = (double)0.0;
                    GLib.Value visibility_val = Goo.CanvasItemVisibility.INVISIBLE;
                    m_Previous.set_property ("y", y_val);
                    m_Previous.set_property ("visibility", visibility_val);
                }

                finished ();
            }

            public void
            start ()
            {
                Log.debug ("start animation");
                m_Current.visibility = Goo.CanvasItemVisibility.VISIBLE;
                m_Previous.visibility = Goo.CanvasItemVisibility.VISIBLE;
                m_Animator.start ();
            }
        }

        // properties
        private string                             m_Id;
        private int                                m_Layer;
        private GLib.HashTable<string, EngineItem> m_Childs;
        private bool                               m_Clip = true;
        private int                                m_CurrentPage = 0;
        private GLib.Queue<Animation>              m_Animations;

        // accessors
        public virtual string node_name {
            get {
                return "notebook";
            }
        }

        public GLib.HashTable<string, EngineItem>? childs {
            get {
                if (m_Childs == null)
                    m_Childs = new GLib.HashTable<string, EngineItem> (GLib.str_hash, GLib.str_equal);
                return m_Childs;
            }
        }

        public string id {
            get {
                return m_Id;
            }
            set {
                m_Id = value;
            }
        }

        public int layer {
            get {
                return m_Layer;
            }
            set {
                m_Layer = value;
            }
        }

        public bool clip {
            get {
                return m_Clip;
            }
            set {
                m_Clip = value;
            }
        }

        public int current_page {
            get {
                return m_CurrentPage;
            }
            set {
                if (m_CurrentPage != value)
                {
                    switch_page (value);
                }
            }
        }

        public bool expand           { get; set; default = false; }
        public int row               { get; set; default = 0; }
        public int column            { get; set; default = 0; }
        public int rows              { get; set; default = 1; }
        public int columns           { get; set; default = 1; }
        public double top_padding    { get; set; default = 0.0; }
        public double bottom_padding { get; set; default = 0.0; }
        public double left_padding   { get; set; default = 0.0; }
        public double right_padding  { get; set; default = 0.0; }
        public double x_align        { get; set; default = 0.5; }
        public bool x_expand         { get; set; default = true; }
        public bool x_fill           { get; set; default = false; }
        public bool x_shrink         { get; set; default = false; }
        public double y_align        { get; set; default = 0.5; }
        public bool y_expand         { get; set; default = true; }
        public bool y_fill           { get; set; default = false; }
        public bool y_shrink         { get; set; default = false; }
        public int  page_num         { get; set; default = -1; }

        public Notebook.Animation.AnimType animation { get; set; default = Notebook.Animation.AnimType.HORIZONTAL_SLIDE; }

        // static methods
        static construct
        {
            GLib.Value.register_transform_func (typeof (string), typeof (Animation.AnimType),
                                                (ValueTransform)string_to_animation_animtype);
            GLib.Value.register_transform_func (typeof (Animation.AnimType), typeof (string),
                                                (ValueTransform)animation_animtype_to_string);
        }

        private static void
        animation_animtype_to_string (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (Animation.AnimType)))
        {
            Animation.AnimType val = (Animation.AnimType)inSrc;

            outDest = val.to_string ();
        }

        private static void
        string_to_animation_animtype (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (string)))
            requires ((string)inSrc != null)
        {
            string val = (string)inSrc;

            outDest = Animation.AnimType.from_string (val);
        }

        // methods
        construct
        {
            m_Animations = new GLib.Queue<Animation> ();
        }

        private void
        switch_page (int inPageNum)
        {
            int old_page = m_CurrentPage;
            unowned Goo.CanvasItemSimple current = null;
            unowned Goo.CanvasItemSimple previous = null;

            foreach (unowned EngineItem item in this)
            {
                if (item is ItemPackOptions)
                {
                    unowned ItemPackOptions? pack_options = (ItemPackOptions?)item;
                    if (pack_options.page_num == inPageNum)
                    {
                        current = (Goo.CanvasItemSimple)item;
                        m_CurrentPage = inPageNum;
                    }
                    else if (pack_options.page_num == old_page)
                    {
                        previous = (Goo.CanvasItemSimple)item;
                    }
                    else
                    {
                        ((Goo.CanvasItemSimple)item).visibility = Goo.CanvasItemVisibility.INVISIBLE;
                    }
                }
            }

            if (previous != null && current != null)
            {
                Animation animation = new Animation (this, ((ItemPackOptions)current).animation, previous, current);
                animation.finished.connect (() => {
                    m_Animations.pop_head ().ref ();
                    unowned Animation? anim = m_Animations.peek_head ();
                    if (anim != null)
                        anim.start ();
                });
                m_Animations.push_tail (animation);

                if (m_Animations.length == 1)
                    animation.start ();
            }
        }

        public void
        paint (Cairo.Context inContext, Goo.CanvasBounds inBounds, double inScale)
        {
            inContext.save ();
            {
                if (m_Clip)
                {
                    inContext.rectangle (0, 0, inBounds.x1 + inBounds.x2, inBounds.y1 + inBounds.y2);
                    inContext.clip ();
                }
                base.paint (inContext, inBounds, inScale);
            }
            inContext.restore ();
        }

        public void
        append_child (EngineItem inChild)
        {
            if (inChild is Goo.CanvasItemSimple)
            {
                childs.insert (inChild.id, inChild);
                add_child ((Goo.CanvasItemSimple)inChild, inChild.layer);
                if (inChild is ItemPackOptions)
                {
                    unowned ItemPackOptions? pack_options = (ItemPackOptions?)inChild;
                    if (pack_options.page_num < 0) pack_options.page_num = (int)childs.size () - 1;
                    set_child_properties (((Goo.CanvasItem)inChild),
                                          row: pack_options.row,
                                          column: pack_options.column,
                                          rows: pack_options.rows,
                                          columns: pack_options.columns,
                                          top_padding: pack_options.top_padding,
                                          bottom_padding: pack_options.bottom_padding,
                                          right_padding: pack_options.right_padding,
                                          left_padding: pack_options.left_padding,
                                          x_expand: pack_options.x_expand,
                                          x_fill: pack_options.x_fill,
                                          x_shrink: pack_options.y_shrink,
                                          y_expand: pack_options.y_expand,
                                          y_fill: pack_options.y_fill,
                                          y_shrink: pack_options.y_shrink,
                                          x_align: pack_options.x_align,
                                          y_align: pack_options.y_align);

                    if (pack_options.page_num == m_CurrentPage)
                        ((Goo.CanvasItemSimple)inChild).visibility = Goo.CanvasItemVisibility.VISIBLE;
                    else
                        ((Goo.CanvasItemSimple)inChild).visibility = Goo.CanvasItemVisibility.INVISIBLE;
                }
            }
        }
    }
}
