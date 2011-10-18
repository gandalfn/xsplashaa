/* ssi-slide-notebook.vala
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
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    public class SlideNotebook : Gtk.Notebook, Gtk.Buildable
    {
        // properties
        private Timeline        m_Timeline;
        private Cairo.Surface   m_PreviousSurface = null;
        private int             m_PreviousPage = -1;

        // accessors
        [Description (nick="Slide duration", blurb="Notebook slide duration in ms")]
        public uint duration {
            get {
                return m_Timeline.duration;
            }
            set {
                m_Timeline.duration = value;
            }
        }

        // methods
        construct
        {
            m_Timeline = new Timeline.for_duration(400);
            m_Timeline.new_frame.connect(() => { queue_draw(); });
            m_Timeline.completed.connect(on_timeline_completed);
        }

        private void
        on_timeline_completed()
        {
            m_PreviousPage = get_current_page(); 
            Gtk.EventBox previous = (Gtk.EventBox)base.get_nth_page(m_PreviousPage);
            Cairo.Context cr = Gdk.cairo_create (previous.window);
            m_PreviousSurface = new Cairo.Surface.similar(cr.get_target(), 
                                                          Cairo.Content.COLOR_ALPHA,
                                                          previous.allocation.width,
                                                          previous.allocation.height);
            Cairo.Context cr_previous = new Cairo.Context(m_PreviousSurface);
            cr_previous.set_operator(Cairo.Operator.SOURCE);
            cr_previous.set_source_surface(cr.get_target(), 0, 0);
            cr_previous.paint();
        }

        private bool
        on_page_expose_event(Gtk.Widget inPage, Gdk.EventExpose inEvent)
        {
            var cr = Gdk.cairo_create (inPage.window);
            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            return false;
        }

        public override int
        insert_page_menu(Gtk.Widget inWidget, Gtk.Widget? inLabel, Gtk.Widget? inMenu, int inPosition)
        {
            Gtk.EventBox page;

            page = new Gtk.EventBox();
            page.show();
            page.set_app_paintable(true);
            page.realize.connect((p) => { p.window.set_composited(true); });
            page.expose_event.connect(on_page_expose_event);
            Gdk.Screen screen = page.get_screen();
            page.set_colormap (screen.get_rgba_colormap ());
            page.add(inWidget);

            return base.insert_page_menu(page, inLabel, inMenu, inPosition);
        }

        public new unowned Gtk.Widget
        get_nth_page(int inPosition)
        {
            Gtk.Widget? page= base.get_nth_page(inPosition);
            weak Gtk.Widget child = null;

            if (page != null)
            {
                child = ((Gtk.Container)page).get_children().nth_data(0);
            }

            return child;
        }

        public new unowned Gtk.Widget?
        get_tab_label(Gtk.Widget? inWidget)
        {
            Gtk.Widget? page= inWidget.get_parent();
            weak Gtk.Widget? child = null;

            if (page != null)
            {
                child = base.get_tab_label(page);
            }

            return child;
        }

        public new void
        set_tab_label(Gtk.Widget inWidget, Gtk.Widget? inLabel)
        {
            Gtk.Widget? page= inWidget.get_parent();

            if (page != null)
            {
                base.set_tab_label(page, inLabel);
            }
        }

        public new int
        page_num(Gtk.Widget inWidget)
        {
            Gtk.Widget? page= inWidget.get_parent();
            int num = -1;

            if (page != null)
            {
                num = base.page_num(page);
            }

            return num;
        }

        internal override void
        switch_page(Gtk.NotebookPage inPage, uint inPageNum)
        {
            m_PreviousPage = get_current_page();
            if (m_PreviousPage >= 0) m_Timeline.start();
            base.switch_page(inPage, inPageNum);
        }

        internal override bool
        expose_event(Gdk.EventExpose inEvent)
        {
            bool ret = base.expose_event((Gdk.EventExpose)inEvent);

            var cr = Gdk.cairo_create (this.window);

            cr.rectangle (inEvent.area.x, inEvent.area.y,
                          inEvent.area.width, inEvent.area.height);
            cr.clip ();

            if (page >= 0)
            {
                Gtk.EventBox current = (Gtk.EventBox)base.get_nth_page(page);

                Gdk.Region region = Gdk.Region.rectangle((Gdk.Rectangle)current.allocation);
                region.intersect(inEvent.region);
                Gdk.cairo_region(cr, region);
                cr.clip();

                if (m_PreviousPage != page && m_PreviousPage >= 0)
                {
                    var cr_current = Gdk.cairo_create (current.window);
                    int x;

                    if (page < m_PreviousPage)
                        x = current.allocation.x - (current.allocation.width - (int)((double)current.allocation.width * m_Timeline.progress));
                    else
                        x = current.allocation.x - (int)((double)current.allocation.width * m_Timeline.progress);
                    
                    cr.save();
                    cr.set_operator(Cairo.Operator.OVER);
                    if (page < m_PreviousPage)
                        cr.set_source_surface(cr_current.get_target(), 
                                              x, current.allocation.y);
                    else
                        cr.set_source_surface(m_PreviousSurface, 
                                              x, current.allocation.y);
                    cr.paint();
                    cr.restore();

                    if (page < m_PreviousPage)
                        x = current.allocation.x + (int)((double)current.allocation.width * m_Timeline.progress);
                    else
                        x = current.allocation.x + (current.allocation.width - (int)((double)current.allocation.width * m_Timeline.progress));

                    if (page < m_PreviousPage)
                        cr.set_source_surface(m_PreviousSurface, 
                                              x, current.allocation.y);
                    else
                        cr.set_source_surface(cr_current.get_target(), 
                                              x, current.allocation.y);

                    cr.save();
                    cr.paint();
                    cr.restore();
                }
                else
                {
                    var cr_current = Gdk.cairo_create (current.window);
                    cr.set_operator(Cairo.Operator.OVER);
                    cr.set_source_surface(cr_current.get_target(), 
                                          current.allocation.x, 
                                          current.allocation.y);
                    cr.paint();
                    on_timeline_completed();
                }
            }
            else
            {
                Gtk.EventBox current = (Gtk.EventBox)base.get_nth_page(0);

                if (current != null)
                {
                    var cr_current = Gdk.cairo_create (current.window);
                    cr.set_operator(Cairo.Operator.OVER);
                    cr.set_source_surface(cr_current.get_target(), 
                                          current.allocation.x, 
                                          current.allocation.y);
                    cr.paint();
                }
            }

            return ret;
        }

        private void
        add_child(Gtk.Builder inBuilder, GLib.Object inChild, string? inType)
        {
            if (inType == null)
            {
                append_page((Gtk.Widget)inChild, null);
            }
            else
            {
                base.add_child(inBuilder, inChild, inType);
            }
        }
    }
}
