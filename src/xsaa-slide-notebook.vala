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
        // Properties
        [Description (nick="Slide duration", blurb="Notebook slide duration in ms")]
        public uint duration {
            get {
                return timeline.duration;
            }
            set {
                timeline.duration = value;
            }
        }

        // Private properties
        Timeline timeline;
        Cairo.Surface previous_surface = null;
        int previous_page = -1;

        construct
        {
            timeline = new Timeline.for_duration(400);
            timeline.new_frame.connect(() => { queue_draw(); });
            timeline.completed.connect(on_timeline_completed);
        }

        private void
        on_timeline_completed()
        {
            previous_page = get_current_page(); 
            Gtk.EventBox previous = (Gtk.EventBox)base.get_nth_page(previous_page);
            Cairo.Context cr = Gdk.cairo_create (previous.window);
            previous_surface = new Cairo.Surface.similar(cr.get_target(), 
                                                         Cairo.Content.COLOR_ALPHA,
                                                         previous.allocation.width,
                                                         previous.allocation.height);
            Cairo.Context cr_previous = new Cairo.Context(previous_surface);
            cr_previous.set_operator(Cairo.Operator.SOURCE);
            cr_previous.set_source_surface(cr.get_target(), 0, 0);
            cr_previous.paint();
        }

        private bool
        on_page_expose_event(Gtk.Widget page, Gdk.EventExpose event)
        {
            var cr = Gdk.cairo_create (page.window);
            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            return false;
        }

        private override int
        insert_page_menu(Gtk.Widget widget, Gtk.Widget? label, Gtk.Widget? menu, int position)
        {
            Gtk.EventBox page;

            page = new Gtk.EventBox();
            page.show();
            page.set_app_paintable(true);
            page.realize.connect((p) => { p.window.set_composited(true); });
            page.expose_event.connect(on_page_expose_event);
            Gdk.Screen screen = page.get_screen();
            page.set_colormap (screen.get_rgba_colormap ());
            page.add(widget);

            return base.insert_page_menu(page, label, menu, position);
        }

        public new unowned Gtk.Widget
        get_nth_page(int position)
        {
            Gtk.Widget? page= base.get_nth_page(position);
            weak Gtk.Widget child = null;

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
            weak Gtk.Widget? child = null;

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

        private override void
        switch_page(Gtk.NotebookPage page, uint page_num)
        {
            previous_page = get_current_page();
            if (previous_page >= 0) timeline.start();
            base.switch_page(page, page_num);
        }

        private override bool
        expose_event(Gdk.EventExpose event)
        {
            bool ret = base.expose_event((Gdk.EventExpose)event);

            var cr = Gdk.cairo_create (this.window);

            cr.rectangle (event.area.x, event.area.y,
                          event.area.width, event.area.height);
            cr.clip ();

            if (page >= 0)
            {
                Gtk.EventBox current = (Gtk.EventBox)base.get_nth_page(page);

                Gdk.Region region = Gdk.Region.rectangle((Gdk.Rectangle)current.allocation);
                region.intersect(event.region);
                Gdk.cairo_region(cr, region);
                cr.clip();

                if (previous_page != page && previous_page >= 0)
                {
                    var cr_current = Gdk.cairo_create (current.window);
                    int x;

                    if (page < previous_page)
                        x = current.allocation.x - (current.allocation.width - (int)((double)current.allocation.width * timeline.progress));
                    else
                        x = current.allocation.x - (int)((double)current.allocation.width * timeline.progress);
                    
                    cr.save();
                    cr.set_operator(Cairo.Operator.OVER);
                    if (page < previous_page)
                        cr.set_source_surface(cr_current.get_target(), 
                                              x, current.allocation.y);
                    else
                        cr.set_source_surface(previous_surface, 
                                              x, current.allocation.y);
                    cr.paint();
                    cr.restore();

                    if (page < previous_page)
                        x = current.allocation.x + (int)((double)current.allocation.width * timeline.progress);
                    else
                        x = current.allocation.x + (current.allocation.width - (int)((double)current.allocation.width * timeline.progress));

                    if (page < previous_page)
                        cr.set_source_surface(previous_surface, 
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
    }
}
