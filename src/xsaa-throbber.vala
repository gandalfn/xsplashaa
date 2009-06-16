/* xsaa-throbber.vala
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
using Gdk;
using Gtk;
using Posix;
using Config;

namespace XSAA
{
    class Throbber : Gtk.Image
    {
        uint interval;
        uint id_timeout;
        int steps;
        int current = 0;
        Gdk.Pixbuf initial;
        Gdk.Pixbuf finish;
        Gdk.Pixbuf[] pixbufs;
        
        public Throbber (string name, uint interval) throws GLib.Error
        {
            Gdk.Pixbuf spinner = new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + 
                                                          "/" + name + 
                                                          "/throbber-spinner.png");

            initial = new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + 
                                               name + "/throbber-initial.png");
            finish = new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + name + 
                                              "/throbber-finish.png");

            uint size = initial.get_width() > initial.get_height() ?
                        initial.get_width() : initial.get_height();
            
            int nb_steps = (spinner.get_height() * spinner.get_width()) / (int)size ;

            pixbufs = new Gdk.Pixbuf[nb_steps];
            for (uint i = 0; i < spinner.get_height(); i += size)
            {
                for (uint j = 0; j < spinner.get_width(); j += size, steps++)
                {
                    pixbufs[steps] = new Gdk.Pixbuf.subpixbuf(spinner, (int)j, 
                                                              (int)i, (int)size, 
                                                              (int)size);
                }
            }
            this.interval = interval;
            set_from_pixbuf(initial);
        }

        ~Throbber()
        {
            stop();
        }

        public void
        start()
        {
            if (id_timeout == 0)
            {
                id_timeout = Timeout.add(interval, on_timer);
            }
        }
        
        public void
        stop()
        {
            if (id_timeout != 0)
            {
                Source.remove(id_timeout);
                id_timeout = 0;
            }
        }

        public void
        finished()
        {
            stop();
            set_from_pixbuf(finish);
        }
        
        private bool
        on_timer()
        {
            if (++current == steps) current = 1;
            set_from_pixbuf(pixbufs[current]);
            
            return true;
        }
    }
}
