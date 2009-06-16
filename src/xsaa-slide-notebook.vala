/* xsaa-slide-notebook.vala
 *
 * Copyright (C) 2009  Nicolas Bruguier
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

using GLib;
using Gtk;
using Posix;
using CCM;

namespace XSAA
{
    public class SlideNotebook : Gtk.Notebook
    {
        Timeline timeline;
        public uint duration {
            get {
                return timeline.get_duration();
            }
            set {
                timeline.set_duration(value);
            }
            default = 400;
        }

        Cairo.Surface previous_surface = null;
        int previous_page = -1;
        
        construct
        {
            timeline = new Timeline.for_duration(400);
            timeline.new_frame += () => { queue_draw(); };
            timeline.completed += on_timeline_completed;
        }

        private void
        on_timeline_completed()
        {
            previous_page = get_current_page(); 
            var previous = (EventBox)get_nth_page(previous_page);
            var cr = Gdk.cairo_create (previous.window);
            previous_surface = new Cairo.Surface.similar(cr.get_target(), 
                                                         Cairo.Content.COLOR_ALPHA,
                                                         previous.allocation.width,
                                                         previous.allocation.height);
            var cr_previous = new Cairo.Context(previous_surface);
            cr_previous.set_operator(Cairo.Operator.SOURCE);
            cr_previous.set_source_surface(cr.get_target(), 0, 0);
            cr_previous.paint();
        }

        private bool
        on_page_expose_event(Gtk.EventBox page, Gdk.EventExpose event)
        {
            var cr = Gdk.cairo_create (page.window);
            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            return false;
        }
        
        public new int
        append_page(Gtk.Widget widget, Gtk.Widget? label)
        {
            EventBox page = new EventBox();
            page.show();
            page.set_app_paintable(true);
            page.realize += (p) => { p.window.set_composited(true); };
            page.expose_event += on_page_expose_event;
            var screen = page.get_screen();
            page.set_colormap (screen.get_rgba_colormap ());
            page.add(widget);
            
            return base.append_page(page, label);
        }

        public override void
        switch_page(void* page, uint page_num)
        {
            previous_page = get_current_page();
            if (previous_page >= 0) timeline.start();
            base.switch_page(page, page_num);
        }

        public override bool
        expose_event(Gdk.EventExpose event)
        {
            bool ret = base.expose_event(event);
            
            var cr = Gdk.cairo_create (this.window);

            cr.rectangle (event.area.x, event.area.y,
                          event.area.width, event.area.height);
            cr.clip ();

            if (page >= 0)
            {
                EventBox current = (EventBox)get_nth_page(page);

                Gdk.Region region = Gdk.Region.rectangle((Gdk.Rectangle)current.allocation);
                region.intersect(event.region);
                Gdk.cairo_region(cr, region);
                cr.clip();
                
                if (previous_page != page && previous_page >= 0)
                {
                    var cr_current = Gdk.cairo_create (current.window);
                    int x;

                    if (page < previous_page)
                        x = current.allocation.x - 
                             (current.allocation.width - 
                              (int)((double)current.allocation.width * timeline.get_progress()));
                    else
                        x = current.allocation.x -
                            (int)((double)current.allocation.width * timeline.get_progress());
                    
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
                        x = current.allocation.x +
                            (int)((double)current.allocation.width * timeline.get_progress());
                    else
                        x = current.allocation.x + 
                             (current.allocation.width - 
                              (int)((double)current.allocation.width * timeline.get_progress()));
                    
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
                    Gdk.cairo_set_source_pixmap(cr, (Gdk.Pixmap*)current.window, 
                                                current.allocation.x, 
                                                current.allocation.y);

                    cr.set_operator(Cairo.Operator.OVER);
                    cr.paint();
		            on_timeline_completed();
                }
            }
            
            return ret;
        }
    }
}
