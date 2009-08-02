/* xsaa-splash.vala
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
        Label label_prompt;
        Entry entry_prompt;
        string username;
        Label label_message;
        uint id_pulse = 0;

        string theme = "chicken-curie";
        string bg = "#1B242D";
        string text = "#7BC4F5";
        float yposition = 0.5f;

        signal void login(string username, string passwd);
        signal void restart();
        signal void shutdown();
        
        public Splash(Server server)
        {
            socket = server;
            socket.phase += on_phase_changed;
            socket.pulse += on_start_pulse;
            socket.progress += on_progress;
            socket.progress_orientation += on_progress_orientation;
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
            
            destroy += Gtk.main_quit;

            var alignment = new Alignment(0.5f, yposition, 0, 0);
            alignment.show();
            add(alignment);

            var vbox = new VBox(false, 75);
            vbox.set_border_width(25);
            vbox.show();
            alignment.add(vbox);

            var hbox = new HBox(false, 25);
            hbox.show();
            vbox.pack_start(hbox, false, false, 0);

            try
            {
                Gdk.Pixbuf pixbuf = 
                    new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + theme +
                                             "/distrib-logo.png");
                int width = geometry.width / 3 > pixbuf.get_width() ? 
                            pixbuf.get_width() : geometry.width / 3;
                int height = (int)((double)width * 
                                   ((double)pixbuf.get_height() / 
                                    (double)pixbuf.get_width()));
                Gtk.Image image = 
                    new Image.from_pixbuf(pixbuf.scale_simple(width, height, 
                                                              Gdk.InterpType.BILINEAR));
                image.show();
                hbox.pack_start(image, false, false, 0);
            }
            catch (GLib.Error err)
            {
                stderr.printf("Error on loading %s: %s", 
                              PACKAGE_DATA_DIR + "/" + theme + "/distrib-logo.png",
                              err.message);
            }            

            var vbox_right = new VBox(false, 25);
            vbox_right.show();
            hbox.pack_start(vbox_right, false, false, 0);
            
            try
            {
                Gdk.Pixbuf pixbuf = 
                    new Gdk.Pixbuf.from_file(PACKAGE_DATA_DIR + "/" + theme +
                                             "/logo.png");
                int width = geometry.width / 3 > pixbuf.get_width() ? 
                            pixbuf.get_width() : geometry.width / 3;
                int height = (int)((double)width * 
                                   ((double)pixbuf.get_height() / 
                                    (double)pixbuf.get_width()));
                Gtk.Image image = 
                    new Image.from_pixbuf(pixbuf.scale_simple(width, height, 
                                                              Gdk.InterpType.BILINEAR));
                image.show();
                vbox_right.pack_start(image, true, true, 0);
            }
            catch (GLib.Error err)
            {
                stderr.printf("Error on loading %s: %s", 
                              PACKAGE_DATA_DIR + "/" + theme + "/logo.png",
                              err.message);
            }            

            alignment = new Alignment(0.5f, 0.5f, 0, 0);
            alignment.show();
            vbox_right.pack_start(alignment, true, true, 0);
            
            notebook = new SlideNotebook();
            notebook.show();
            alignment.add(notebook);
            notebook.set_show_tabs(false);
            notebook.set_show_border(false);
    
            construct_loading_page();

            construct_login_page();

            construct_launch_session_page();

            construct_shutdown_page();
            
            var table_progress = new Table(5, 1, false);
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
                    bg = config.get_string("splash", "background");
                    text = config.get_string("splash", "text");
                    yposition = (float)config.get_double("splash", "yposition");
                }
                catch (GLib.Error err)
                {
                    stderr.printf("Error on read %s: %s", 
                                  PACKAGE_CONFIG_FILE, err.message);
                }
            }
        }

        private void
        construct_loading_page()
        {
            var table = new Table(3, 2, false);
            table.show();
            notebook.append_page(table, null);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label = new Label("<span size='xx-large' color='" + 
                                  text +"'>Loading  ...</span>");
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
                stderr.printf("Error on loading throbber %s", err.message);
            }     

            label = new Label("<span size='xx-large' color='" + 
                              text +"'>Check filesystem ...</span>");
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
                stderr.printf("Error on loading throbber %s", err.message);
            } 

            label = new Label("<span size='xx-large' color='" + 
                              text +"'>Start System ...</span>");
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
                stderr.printf("Error on loading throbber %s", err.message);
            } 
        }

        private void
        construct_login_page()
        {
            var alignment = new Alignment(0.5f, 1.0f, 0, 0);
            alignment.show();
            notebook.append_page(alignment, null);

            var box = new VBox(false, 12);
            box.show();
            alignment.add(box);
            
            var table = new Table(3, 3, false);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(24);
            table.show();
            box.pack_start(table, true, true, 0);

            label_prompt = new Label("<span size='xx-large' color='" + 
                                  text +"'>Login :</span>");
            label_prompt.set_use_markup(true);
            label_prompt.set_alignment(0.0f, 0.5f);
            label_prompt.show();
            table.attach_defaults(label_prompt, 1, 2, 0, 1);

            entry_prompt = new Entry();
            entry_prompt.show();
            table.attach_defaults(entry_prompt, 2, 3, 0, 1);

            label_message = new Label("");
            label_message.set_use_markup(true);
            label_message.set_alignment(0.5f, 0.5f);
            label_message.show();
            table.attach_defaults(label_message, 0, 4, 1, 2);

            var button_box = new HButtonBox();
            button_box.show();
            button_box.set_spacing(12);
            button_box.set_layout(Gtk.ButtonBoxStyle.END);
            box.pack_start(button_box, false, false, 0);

            var button = new Button.with_label("Restart");
            button.show();
            button.clicked += on_restart_clicked;
            button_box.pack_start(button, false, false, 0);

            button = new Button.with_label("Shutdown");
            button.show();
            button.clicked += on_shutdown_clicked;
            button_box.pack_start(button, false, false, 0);
        }

        private void
        construct_launch_session_page()
        {
            var table = new Table(1, 2, false);
            table.show();
            notebook.append_page(table, null);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label =  new Label("<span size='xx-large' color='" + 
                                   text +"'>Launch session ...</span>");
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
                stderr.printf("Error on loading throbber %s", err.message);
            }
        }

        private void
        construct_shutdown_page()
        {
            var table = new Table(1, 2, false);
            table.show();
            notebook.append_page(table, null);
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label =  new Label("<span size='xx-large' color='" + 
                                   text +"'>Shutdown in progress ...</span>");
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
                stderr.printf("Error on loading throbber %s", err.message);
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
                entry_prompt.activate += on_passwd_enter;
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
            
            Gdk.Color color;

            Gdk.Color.parse("#1B242D", out color);
            modify_bg(StateType.NORMAL, color);
            notebook.modify_bg(StateType.NORMAL, color);
    	}

        public void
        show_launch()
        {
            notebook.set_current_page(2);
            throbber_session.start();
        }
        
        public void
        show_shutdown()
        {
            notebook.set_current_page(3);
            progress.show();
            on_start_pulse();
            throbber_shutdown.start();
        }

        public void
        ask_for_login()
        {
            notebook.set_current_page(1);
            label_prompt.set_markup("<span size='xx-large' color='" + 
                                     text +"'>Login :</span>");
            set_focus(entry_prompt);
            entry_prompt.grab_focus();
            entry_prompt.set_sensitive(true);
            entry_prompt.set_visibility(true);
            entry_prompt.set_text("");
            entry_prompt.activate += on_login_enter;
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
