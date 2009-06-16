/* test-slide-notebook.vala
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

namespace XSAA
{
    public class TestSlideWindow : Window 
    {
	    private SlideNotebook notebook;

        public TestSlideWindow () 
        {
		    title = "Test Slide Notebook";
	    }

	    construct 
        {
		    //set_default_size (600, 400);

		    destroy += Gtk.main_quit;

		    notebook = new SlideNotebook();
            notebook.show();
		    add (notebook);

            var label = new Label("<span size='xx-large'>Page 1</span>");
            label.set_use_markup(true);
            label.show();
            notebook.append_page(label, null);

            label = new Label("<span size='xx-large'>Page 2</span>");
            label.set_use_markup(true);
            label.show();
            notebook.append_page(label, null);

            label = new Label("<span size='xx-large'>Page 3</span>");
            label.set_use_markup(true);
            label.show();
            notebook.append_page(label, null);
	    }

	    public void run () 
        {
		    show ();

		    Gtk.main ();
	    }
    }
    
	static int 
    main (string[] args) 
    {
        Gtk.init (ref args);

		var window = new TestSlideWindow ();
		window.run ();
		return 0;
	}
}