/* xsaa-splash.vala
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

using GLib;
using Gtk;
using Posix;
using Config;
using SSI;

namespace XSAA
{
    public class Splash : Gtk.Window
    {
        Server socket;
        Throbber[] phase = new Throbber[3];
        Throbber throbber_session;
        Throbber throbber_shutdown;
        int current_phase = 0;
        ProgressBar progress;
        SlideNotebook notebook;
        Gtk.Label label_prompt;
        Gtk.Entry entry_prompt;
        string username;
        Gtk.Label label_message;
        uint id_pulse = 0;

        string theme = "chicken-curie";
        string layout = "horizontal";
        string bg = "#1B242D";
        string text = "#7BC4F5";
        float yposition = 0.5f;

        public signal void login(string username, string passwd);
        public signal void restart();
        public signal void shutdown();

        public Splash(Server server)
        {
            socket = server;
            socket.phase.connect(on_phase_changed);
            socket.pulse.connect(on_start_pulse);
            socket.progress.connect(on_progress);
            socket.progress_orientation.connect(on_progress_orientation);
        }

        construct
        {
            load_config();

            Gdk.Screen screen = Gdk.Screen.get_default();
            Gdk.Rectangle geometry;
            screen.get_monitor_geometry(0, out geometry);

            set_app_paintable(true);
            set_default_size(geometry.width, geometry.height);

            fullscreen();

            destroy.connect(Gtk.main_quit);

            var alignment = new Alignment(0.5f, yposition, 0, 0);
            alignment.show();
            add(alignment);

            var vbox = new Gtk.VBox(false, 75);
            vbox.set_border_width(25);
            vbox.show();
            alignment.add(vbox);

            Gtk.Box box = null;
            if (layout == "horizontal")
            {
                box = new Gtk.HBox(false, 25);
            }
            else
            {
                box = new Gtk.VBox(false, 25);
            }
            box.show();
            vbox.pack_start(box, false, false, 0);

            try
            {
                Gdk.Pixbuf pixbuf = 
                    new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + theme +
                                             "/distrib-logo.png");

                int width, height;

                if (layout == "horizontal")
                {
                    width = geometry.width / 3 > pixbuf.get_width() ? 
                            pixbuf.get_width() : geometry.width / 3;
                    height = (int)((double)width * 
                                   ((double)pixbuf.get_height() / 
                                    (double)pixbuf.get_width()));
                }
                else 
                {
                    width = geometry.width / 1.5 > pixbuf.get_width() ? 
                            pixbuf.get_width() : (int)(geometry.width / 1.5);
                    height = (int)((double)width * 
                                   ((double)pixbuf.get_height() / 
                                    (double)pixbuf.get_width()));
                }

                Gtk.Image image = 
                    new Gtk.Image.from_pixbuf(pixbuf.scale_simple(width, height, 
                                                                  Gdk.InterpType.BILINEAR));
                image.show();
                box.pack_start(image, false, false, layout == "horizontal" ? 0 : 36);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading %s: %s", 
                                   PACKAGE_DATA_DIR + "/" + theme + "/distrib-logo.png",
                                   err.message);
            }

            Gtk.Box box_info;
            if (layout == "horizontal")
            {
                box_info = new Gtk.VBox(false, 25);
            }
            else
            {
                box_info = new Gtk.HBox(false, 25);
            }
            box_info.show();
            box.pack_start(box_info, false, false, 0);

            try
            {
                Gdk.Pixbuf pixbuf = 
                    new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + theme +
                                             "/logo.png");
                int width, height;
                
                if (layout == "horizontal")
                {
                    width = geometry.width / 3 > pixbuf.get_width() ? 
                            pixbuf.get_width() : geometry.width / 3;
                    height = (int)((double)width * 
                                   ((double)pixbuf.get_height() / 
                                    (double)pixbuf.get_width()));
                }
                else 
                {
                    width = pixbuf.get_width() > geometry.width  ? 
                            geometry.width : pixbuf.get_width();
                    height = (int)((double)width * 
                                   ((double)pixbuf.get_height() / 
                                    (double)pixbuf.get_width()));
                }
                Gtk.Image image = 
                    new Gtk.Image.from_pixbuf(pixbuf.scale_simple(width, height, 
                                                                  Gdk.InterpType.BILINEAR));
                image.show();
                box_info.pack_start(image, true, true, 0);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading %s: %s", 
                                   PACKAGE_DATA_DIR + "/" + theme + "/logo.png",
                                   err.message);
            }

            alignment = new Alignment(0.5f, 0.5f, 0, 0);
            alignment.show();
            box_info.pack_start(alignment, true, true, 0);

            notebook = new SlideNotebook();
            notebook.show();
            alignment.add(notebook);
            notebook.set_show_tabs(false);
            notebook.set_show_border(false);

            construct_loading_page();

            construct_login_page();

            construct_launch_session_page();

            construct_shutdown_page();

            var table_progress = new Gtk.Table(5, 1, false);
            table_progress.show();
            table_progress.set_border_width(24);
            table_progress.set_col_spacings(12);
            table_progress.set_row_spacings(12);
            vbox.pack_start(table_progress, false, false, 12);

            progress = new ProgressBar();
            progress.show();
            table_progress.attach(progress, 2, 3, 0, 1, 
                                  AttachOptions.EXPAND | AttachOptions.FILL, 
                                  0, 0, 0);

            on_start_pulse();
        }

        private void
        load_config()
        {
            if (FileUtils.test(PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile();
                    config.load_from_file(PACKAGE_CONFIG_FILE, 
                                          KeyFileFlags.NONE);
                    theme = config.get_string("splash", "theme");
                    layout = config.get_string("splash", "layout");
                    bg = config.get_string("splash", "background");
                    text = config.get_string("splash", "text");
                    yposition = (float)config.get_double("splash", "yposition");
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on read %s: %s", 
                                       PACKAGE_CONFIG_FILE, err.message);
                }
            }
        }

        private void
        construct_loading_page()
        {
            var table = new Gtk.Table(3, 2, false);
            table.show();
            notebook.append_page(table, null);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label = new Gtk.Label("<span size='xx-large' color='" + 
                                  text +"'>Loading...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 0, 1);

            try
            {
                phase[0] = new Throbber(theme, 83);
                phase[0].show();
                phase[0].start();
                table.attach_defaults(phase[0], 1, 2, 0, 1);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading throbber %s", err.message);
            }

            label = new Gtk.Label("<span size='xx-large' color='" + 
                                  text +"'>Checking filesystem...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 1, 2);

            try
            {
                phase[1] = new Throbber(theme, 83);
                phase[1].show();
                table.attach_defaults(phase[1], 1, 2, 1, 2);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading throbber %s", err.message);
            }

            label = new Gtk.Label("<span size='xx-large' color='" + 
                                  text +"'>Starting...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 2, 3);
            
            try
            {
                phase[2] = new Throbber(theme, 83);
                phase[2].show();
                table.attach_defaults(phase[2], 1, 2, 2, 3);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading throbber %s", err.message);
            }
        }

        private void
        construct_login_page()
        {
            var alignment = new Alignment(0.5f, 1.0f, 0, 0);
            alignment.show();
            notebook.append_page(alignment, null);

            var box = new Gtk.VBox(false, 12);
            box.show();
            alignment.add(box);
            
            var table = new Gtk.Table(3, 3, false);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(24);
            table.show();
            box.pack_start(table, true, true, 0);

            label_prompt = new Gtk.Label("<span size='xx-large' color='" + 
                                         text +"'>Login :</span>");
            label_prompt.set_use_markup(true);
            label_prompt.set_alignment(0.0f, 0.5f);
            label_prompt.show();
            table.attach_defaults(label_prompt, 1, 2, 0, 1);

            entry_prompt = new Gtk.Entry();
            entry_prompt.show();
            table.attach_defaults(entry_prompt, 2, 3, 0, 1);

            label_message = new Gtk.Label("");
            label_message.set_use_markup(true);
            label_message.set_alignment(0.5f, 0.5f);
            label_message.show();
            table.attach_defaults(label_message, 0, 4, 1, 2);

            var button_box = new HButtonBox();
            button_box.show();
            button_box.set_spacing(12);
            button_box.set_layout(Gtk.ButtonBoxStyle.END);
            box.pack_start(button_box, false, false, 0);

            var button = new Gtk.Button.with_label("Restart");
            button.show();
            button.clicked.connect(on_restart_clicked);
            button_box.pack_start(button, false, false, 0);

            button = new Gtk.Button.with_label("Shutdown");
            button.show();
            button.clicked.connect(on_shutdown_clicked);
            button_box.pack_start(button, false, false, 0);
        }

        private void
        construct_launch_session_page()
        {
            var table = new Gtk.Table(1, 2, false);
            table.show();
            notebook.append_page(table, null);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label =  new Gtk.Label("<span size='xx-large' color='" + 
                                       text +"'>Launching session...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 0, 1);
            
            try
            {
                throbber_session = new Throbber(theme, 83);
                throbber_session.show();
                table.attach_defaults(throbber_session, 1, 2, 0, 1);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading throbber %s", err.message);
            }
        }

        private void
        construct_shutdown_page()
        {
            var table = new Gtk.Table(1, 2, false);
            table.show();
            notebook.append_page(table, null);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label =  new Gtk.Label("<span size='xx-large' color='" + 
                                       text +"'>Shutdown in progress...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 0, 1);
            
            try
            {
                throbber_shutdown = new Throbber(theme, 83);
                throbber_shutdown.show();
                table.attach_defaults(throbber_shutdown, 1, 2, 0, 1);
            }
            catch (GLib.Error err)
            {
                GLib.stderr.printf("Error on loading throbber %s", err.message);
            }
        }

        private void
        on_phase_changed(int new_phase)
        {
            if (current_phase != new_phase)
            {
                if (current_phase < 3 && current_phase >= 0)
                    phase[current_phase].finished();
                if (new_phase < 3 && new_phase >= 0)
                    phase[new_phase].start();
                current_phase = new_phase;
            }
        }

        private bool
        on_pulse()
        {
            progress.pulse();
            return true;
        }

        private void
        on_start_pulse()
        {
            if (id_pulse == 0)
            {
                id_pulse = Timeout.add(83, on_pulse);
            }
        }

        private void
        on_progress(int val)
        {
            if (id_pulse > 0) Source.remove(id_pulse);
            id_pulse = 0;
            progress.set_fraction((double)val / (double)100);
        }

        private void
        on_progress_orientation(ProgressBarOrientation orientation)
        {
            progress.set_orientation(orientation);
        }

        private void
        on_login_enter()
        {
            username = entry_prompt.get_text();
            if (username.len() > 0)
            {
                set_focus(entry_prompt);
                entry_prompt.activate -= on_login_enter;
                entry_prompt.set_visibility(false);
                entry_prompt.set_text("");
                entry_prompt.activate.connect(on_passwd_enter);
                label_prompt.set_markup("<span size='xx-large' color='" + 
                                        text +"'>Password :</span>");
                label_message.set_text("");
            }
        }

        private void
        on_passwd_enter()
        {
            entry_prompt.set_sensitive(false);
            entry_prompt.activate -= on_passwd_enter;
            login(username, entry_prompt.get_text());
        }

        private void
        on_restart_clicked()
        {
            restart();
        }

        private void
        on_shutdown_clicked()
        {
            shutdown();
        }

        override void
        realize ()
        {
            base.realize();

            if (!FileUtils.test(PACKAGE_DATA_DIR + "/" + theme + "/background.png",
                                FileTest.EXISTS))
            {
                Gdk.Color color;

                Gdk.Color.parse(bg, out color);
                modify_bg(StateType.NORMAL, color);
                notebook.modify_bg(StateType.NORMAL, color);

                var screen = get_window().get_screen();
                var root = screen.get_root_window();
                root.set_background(color);
            }
            else
            {
                try
                {
                    Gdk.Pixbuf pixbuf = 
                        new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + 
                                                 theme + "/background.png");

                    Gdk.Pixmap pixmap = new Gdk.Pixmap(window, allocation.width, 
                                                       allocation.height, -1);
                    Gdk.Pixbuf scale = 
                        pixbuf.scale_simple(allocation.width, allocation.height,
                                            Gdk.InterpType.BILINEAR);

                    pixmap.draw_rectangle (style.bg_gc[Gtk.StateType.NORMAL], 
                                           true, 0, 0, 
                                           allocation.width, allocation.height);
                    pixmap.draw_pixbuf (style.black_gc, scale, 0, 0, 0, 0, 
                                        allocation.width, allocation.height,
                                        Gdk.RgbDither.MAX, 0, 0);
                    Gtk.Style style = new Gtk.Style();
                    style.bg_pixmap[Gtk.StateType.NORMAL] = pixmap;
                    this.style = style;
                }
                catch (GLib.Error err)
                {
                    GLib.stderr.printf("Error on loading %s: %s", 
                                       PACKAGE_DATA_DIR + "/" + theme + "/background.png",
                                       err.message);
                } 
            }
        }

        override void
        hide()
        {
            throbber_session.finished();
            base.hide();
        }

        public void
        show_launch()
        {
            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);
            notebook.set_current_page(2);
            throbber_session.start();
        }

        public void
        show_shutdown()
        {
            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);
            notebook.set_current_page(3);
            progress.show();
            on_start_pulse();
            throbber_shutdown.start();
        }

        public void
        ask_for_login()
        {
            phase[2].finished();

            var cursor = new Gdk.Cursor(Gdk.CursorType.LEFT_PTR);
            get_window().set_cursor(cursor);

            notebook.set_current_page(1);
            label_prompt.set_markup("<span size='xx-large' color='" + 
                                     text +"'>Login :</span>");
            set_focus(entry_prompt);
            entry_prompt.grab_focus();
            entry_prompt.set_sensitive(true);
            entry_prompt.set_visibility(true);
            entry_prompt.set_text("");
            entry_prompt.activate.connect(on_login_enter);
            if (id_pulse > 0) Source.remove(id_pulse);
            id_pulse = 0;
            progress.hide();
        }

        public void
        login_message(string msg)
        {
            label_message.set_markup("<span size='xx-large' color='" + 
                                     text +"'>" + msg + "</span>");
        }
    }
}
