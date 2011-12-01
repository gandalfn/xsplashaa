/* ssi-slide-notebook.vala
 *
 * Copyright (C) 2009-2011  Supersonic Imagine
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
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */


namespace XSAA
{
    public class SlideNotebook : Gtk.Notebook, Gtk.Buildable
    {
        // properties
        private XSAA.Animator m_Animator;
        private Cairo.Surface m_PreviousSurface = null;
        private int m_PreviousPage = -1;
        private double m_Progress = 1.0;

        // accessors
        internal double progress {
            get {
                return m_Progress;
            }
            set {
                m_Progress = value;
                if (page >= 0 && m_PreviousSurface != null)
                {
                    Gtk.EventBox current = (Gtk.EventBox)base.get_nth_page(page);
                    if (current != null)
                        queue_draw_area (current.allocation.x, current.allocation.y, current.allocation.width, current.allocation.height);
                }
            }
        }

        [Description (nick="Slide duration", blurb="Notebook slide duration in ms")]
        public uint duration {
            get {
                return m_Animator.duration;
            }
            set {
                m_Animator.duration = value;
            }
        }

        // methods
        construct
        {
            m_Animator = new XSAA.Animator(60, 400);
            uint transition = m_Animator.add_transition (0.0, 1.0, XSAA.Animator.ProgressType.SINUSOIDAL, null, on_animation_finished);
            GLib.Value from = (double)0.0;
            GLib.Value to = (double)1.0;
            m_Animator.add_transition_property (transition, this, "progress", from, to);
        }

        private static Cairo.Surface?
        get_clone_surface (Gdk.Window inWindow, int inWidth, int inHeight)
        {
            Cairo.Surface? surface = null;

//            X.synchronize (Gdk.x11_display_get_xdisplay (inWindow.get_display ()), true);
            inWindow.get_display ().sync ();
            Gdk.error_trap_push ();
            if (inWindow.is_viewable () && inWindow.is_visible ())
            {
                var cr = Gdk.cairo_create (inWindow);
                surface = new Cairo.Surface.similar(cr.get_target(),
                                                    Cairo.Content.COLOR_ALPHA,
                                                    inWidth, inHeight);
                var cr_surface = new Cairo.Context(surface);

                cr_surface.set_operator(Cairo.Operator.SOURCE);
                cr_surface.set_source_surface(cr.get_target(), 0, 0);
                cr_surface.paint();

                cr_surface.set_operator(Cairo.Operator.OVER);
                foreach (unowned Gdk.Window window in inWindow.peek_children ())
                {
                    X.WindowAttributes attr;

                    Gdk.x11_display_get_xdisplay (inWindow.get_display ()).get_window_attributes (Gdk.x11_drawable_get_xid (window), out attr);
                    if (window.is_viewable () && window.is_visible () && attr.map_state != X.InputOnly)
                    {
                        int x, y, width, height, depth;
                        window.get_geometry (out x, out y, out width, out height, out depth);

                        cr = Gdk.cairo_create (window);
                        cr_surface.save ();
                        cr_surface.set_source_surface(cr.get_target(), x, y);
                        cr_surface.paint();
                        cr_surface.restore ();
                    }
                }
            }
            inWindow.get_display ().sync ();
            if (Gdk.error_trap_pop () != 0) surface = null;
//            X.synchronize (Gdk.x11_display_get_xdisplay (inWindow.get_display ()), false);

            return surface;
        }

        private void
        on_animation_finished ()
        {
            m_PreviousPage = get_current_page();
            var previous = (Gtk.EventBox)base.get_nth_page(m_PreviousPage);
            if (previous != null && previous.is_realized ())
            {
                previous.queue_draw ();
                previous.window.process_updates (true);
                var surface = get_clone_surface (previous.window,
                                                 previous.allocation.width,
                                                 previous.allocation.height);
                if (surface != null) m_PreviousSurface = surface;
            }
            else
                m_PreviousSurface = null;
        }

        private void
        on_child_realize (Gtk.Widget inChild)
        {
            int pos = page_num (inChild);
            if (pos == m_PreviousPage || m_PreviousPage == -1)
            {
                if (m_PreviousPage == -1)
                    m_PreviousPage = get_current_page();

                var previous = (Gtk.EventBox)base.get_nth_page(m_PreviousPage);
                if (previous != null && previous.is_realized ())
                {
                    previous.queue_draw ();
                    previous.window.process_updates (true);
                    var surface = get_clone_surface (previous.window,
                                                     previous.allocation.width,
                                                     previous.allocation.height);
                    if (surface != null) m_PreviousSurface = surface;
                }
                else
                    m_PreviousSurface = null;
            }
        }

        private void
        on_child_parent_set (Gtk.Widget inChild, Gtk.Widget? inParent)
        {
            if (parent != null)
            {
                inChild.realize.disconnect (on_child_realize);
                inChild.parent_set.disconnect (on_child_parent_set);
            }
        }

        private void
        add_child(Gtk.Builder builder, GLib.Object child, string? type)
        {
            if (type == null)
            {
                append_page((Gtk.Widget)child, null);
            }
            else
            {
                base.add_child(builder, child, type);
            }
        }

        private bool
        on_page_expose_event(Gtk.Widget inPage, Gdk.EventExpose inEvent)
        {
            var cr = Gdk.cairo_create (inPage.window);
            cr.save ();
            cr.set_operator (Cairo.Operator.CLEAR);
            cr.rectangle (inEvent.area.x, inEvent.area.y,
                          inEvent.area.width, inEvent.area.height);
            cr.clip ();
            cr.paint ();
            cr.restore ();
            return false;
        }

        internal override int
        insert_page_menu(Gtk.Widget inWidget, Gtk.Widget? inLabel, Gtk.Widget? inMenu, int inPosition)
        {
            Gtk.EventBox page;

            page = new Gtk.EventBox();
            page.set_above_child (false);
            page.set_visible_window (true);
            page.show();
            page.set_app_paintable(true);
            page.realize.connect((p) => { p.window.set_composited(true); });
            page.expose_event.connect(on_page_expose_event);
            Gdk.Screen screen = page.get_screen();
            page.set_colormap (screen.get_rgba_colormap ());
            page.add(inWidget);

            // connect on map event of widget
            inWidget.realize.connect (on_child_realize);
            inWidget.parent_set.connect (on_child_parent_set);

            return base.insert_page_menu(page, inLabel, inMenu, inPosition);
        }

        internal override void
        switch_page(Gtk.NotebookPage page, uint page_num)
        {
            if (is_realized ())
            {
                if (m_PreviousPage != page_num)
                {
                    m_PreviousPage = get_current_page();
                    if (m_PreviousPage >= 0)
                    {
                        var previous = (Gtk.EventBox)base.get_nth_page(m_PreviousPage);
                        if (previous != null && previous.is_realized ())
                        {
                            previous.queue_draw ();
                            previous.window.process_updates (true);
                            var surface = get_clone_surface (previous.window,
                                                             previous.allocation.width,
                                                             previous.allocation.height);
                            if (surface != null) m_PreviousSurface = surface;
                        }
                        else
                            m_PreviousSurface = null;

                        progress = 0.0;
                        m_Animator.start();
                    }
                }
            }

            base.switch_page(page, page_num);
        }

        internal override bool
        expose_event(Gdk.EventExpose inEvent)
        {
            bool ret = base.expose_event((Gdk.EventExpose)inEvent);

            paint (inEvent);

            return ret;
        }

        public void
        paint (Gdk.EventExpose inEvent)
        {
            if (is_drawable () && this.window != null)
            {
                var cr = Gdk.cairo_create (this.window);

                cr.save ();
                cr.rectangle (inEvent.area.x, inEvent.area.y,
                              inEvent.area.width, inEvent.area.height);
                cr.clip ();

                cr.set_operator (Cairo.Operator.OVER);
                if (page >= 0 && m_PreviousSurface != null)
                {
                    Gtk.EventBox current = (Gtk.EventBox)base.get_nth_page(page);

                    if (current != null && current.is_realized () && current.window != null)
                    {
                        current.window.process_updates (true);
                        Gdk.Region region = Gdk.Region.rectangle((Gdk.Rectangle)current.allocation);
                        region.intersect(inEvent.region);
                        if (!region.empty ())
                        {
                            Gdk.cairo_region(cr, region);
                            cr.clip();

                            if (m_PreviousPage != page && m_PreviousPage >= 0)
                            {
                                var cr_current = Gdk.cairo_create (current.window);
                                int x = current.allocation.x;
                                int y = current.allocation.y;

                                if (tab_pos == Gtk.PositionType.TOP || tab_pos == Gtk.PositionType.BOTTOM)
                                {
                                    if (page < m_PreviousPage)
                                        x = current.allocation.x - (current.allocation.width - (int)((double)current.allocation.width * m_Progress));
                                    else
                                        x = current.allocation.x - (int)((double)current.allocation.width * m_Progress);
                                }
                                else
                                {
                                    if (page < m_PreviousPage)
                                        y = current.allocation.y - (current.allocation.height - (int)((double)current.allocation.height * m_Progress));
                                    else
                                        y = current.allocation.y - (int)((double)current.allocation.height * m_Progress);
                                }

                                cr.save();
                                if (page < m_PreviousPage)
                                    cr.set_source_surface(cr_current.get_target(), x, y);
                                else
                                    cr.set_source_surface(m_PreviousSurface, x, y);
                                cr.paint();
                                cr.restore();

                                cr.save();
                                if (tab_pos == Gtk.PositionType.TOP || tab_pos == Gtk.PositionType.BOTTOM)
                                {
                                    if (page < m_PreviousPage)
                                        x = current.allocation.x + (int)((double)current.allocation.width * m_Progress);
                                    else
                                        x = current.allocation.x + (current.allocation.width - (int)((double)current.allocation.width * m_Progress));
                                }
                                else
                                {
                                    if (page < m_PreviousPage)
                                        y = current.allocation.y + (int)((double)current.allocation.height * m_Progress);
                                    else
                                        y = current.allocation.y + (current.allocation.height - (int)((double)current.allocation.height * m_Progress));
                                }

                                if (page < m_PreviousPage)
                                    cr.set_source_surface(m_PreviousSurface, x, y);
                                else
                                    cr.set_source_surface(cr_current.get_target(),  x, y);

                                cr.paint();
                                cr.restore();
                            }
                            else
                            {
                                var cr_current = Gdk.cairo_create (current.window);
                                cr.set_source_surface(cr_current.get_target(), current.allocation.x, current.allocation.y);
                                cr.paint();
                            }
                        }
                    }
                }
                else
                {
                    Gtk.EventBox current = (Gtk.EventBox)base.get_nth_page(int.max (page, 0));

                    if (current != null && current.is_realized () && current.window != null)
                    {
                        current.window.process_updates (true);
                        Gdk.Region region = Gdk.Region.rectangle((Gdk.Rectangle)current.allocation);
                        region.intersect(inEvent.region);
                        if (!region.empty ())
                        {
                            Gdk.cairo_region(cr, region);
                            cr.clip();

                            var cr_current = Gdk.cairo_create (current.window);
                            cr.set_source_surface(cr_current.get_target(), current.allocation.x, current.allocation.y);
                            cr.paint();
                        }
                    }
                }
                cr.restore ();
            }
        }

        public new unowned Gtk.Widget
        get_nth_page(int position)
        {
            Gtk.Widget? page= base.get_nth_page(position);
            unowned Gtk.Widget child = null;

            if (page != null)
            {
                child = ((Gtk.Container)page).get_children().nth_data(0);
            }

            return child;
        }

        public new unowned Gtk.Widget?
        get_tab_label(Gtk.Widget? widget)
        {
            Gtk.Widget? page= widget.get_parent();
            unowned Gtk.Widget? child = null;

            if (page != null)
            {
                child = base.get_tab_label(page);
            }

            return child;
        }

        public new void
        set_tab_label(Gtk.Widget widget, Gtk.Widget? label)
        {
            Gtk.Widget? page= widget.get_parent();

            if (page != null)
            {
                base.set_tab_label(page, label);
            }
        }

        public new void
        set_tab_label_packing(Gtk.Widget widget, bool inExpand, bool inFill, Gtk.PackType inPacking)
        {
            Gtk.Widget? page= widget.get_parent();

            if (page != null)
            {
                base.set_tab_label_packing(page, inExpand, inFill, inPacking);
            }
        }

        public new void
        set_tab_label_text(Gtk.Widget widget, string inText)
        {
            Gtk.Widget? page= widget.get_parent();

            if (page != null)
            {
                base.set_tab_label_text(page, inText);
            }
        }

        public new int
        page_num(Gtk.Widget widget)
        {
            Gtk.Widget? page= widget.get_parent();
            int num = -1;

            if (page != null)
            {
                num = base.page_num(page);
            }

            return num;
        }

        public new void
        child_set_property (Gtk.Widget widget, string name, GLib.Value value)
        {
            Gtk.Widget? page = widget.get_parent();

            if (page == this)
            {
                base.child_set_property(widget, name, value);
            }
            else if (page != null && page.get_parent () == this)
            {
                base.child_set_property(page, name, value);
            }
        }
    }
}

