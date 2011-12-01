/* xsaa-throbber.vala
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
    public class Throbber : Gtk.Image
    {
        // properties
        private uint         m_Interval;
        private uint         m_IdTimeout;
        private int          m_Steps;
        private int          m_Current = 0;
        private Gdk.Pixbuf   m_Initial;
        private Gdk.Pixbuf   m_Finish;
        private Gdk.Pixbuf[] m_Pixbufs;

        // methods
        public Throbber (string name, uint interval) throws GLib.Error
        {
            Gdk.Pixbuf spinner = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + name + "/throbber-spinner.png");

            m_Initial = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + name + "/throbber-initial.png");
            m_Finish = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + name + "/throbber-finish.png");

            uint size = m_Initial.get_width() > m_Initial.get_height() ?
                        m_Initial.get_width() : m_Initial.get_height();

            int nb_steps = (spinner.get_height() * spinner.get_width()) / (int)size ;

            m_Pixbufs = new Gdk.Pixbuf[nb_steps];
            for (uint i = 0; i < spinner.get_height(); i += size)
            {
                for (uint j = 0; j < spinner.get_width(); j += size, m_Steps++)
                {
                    m_Pixbufs[m_Steps] = new Gdk.Pixbuf.subpixbuf(spinner, (int)j, 
                                                                (int)i, (int)size, 
                                                                (int)size);
                }
            }
            m_Interval = interval;
            set_from_pixbuf(m_Initial);
        }

        ~Throbber()
        {
            stop();
        }

        public void
        start()
        {
            if (m_IdTimeout == 0)
            {
                m_IdTimeout = GLib.Timeout.add(m_Interval, on_timer);
            }
        }

        public void
        stop()
        {
            if (m_IdTimeout != 0)
            {
                GLib.Source.remove(m_IdTimeout);
                m_IdTimeout = 0;
            }
        }

        public void
        finished()
        {
            stop();
            set_from_pixbuf(m_Finish);
        }

        private bool
        on_timer()
        {
            if (++m_Current == m_Steps) m_Current = 1;
            set_from_pixbuf(m_Pixbufs[m_Current]);
            
            return true;
        }
    }
}
