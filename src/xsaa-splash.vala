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
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    public enum FaceAuthenticationStatus
    {
        INPROGRESS = 35,

        STOPPED = 28,
        STARTED = 21,

        CANCEL = 14,
        AUTHENTICATE = 7,
        DISPLAY_ERROR = 1,
        EXIT_GUI = 2
    }

    public class Splash : Gtk.Window
    {
        const int ICON_SIZE = 90;

        const Posix.key_t FACE_AUTHENTICATION_IPC_KEY_SEM_IMAGE = 567816;
        const Posix.key_t FACE_AUTHENTICATION_IPC_KEY_IMAGE = 567814;
        const Posix.key_t FACE_AUTHENTICATION_IPC_KEY_STATUS = 567813;
        const int         FACE_AUTHENTICATION_IMAGE_WIDTH = 320;
        const int         FACE_AUTHENTICATION_IMAGE_HEIGHT = 240;
        const int         FACE_AUTHENTICATION_IMAGE_SIZE = 307200;

        Server socket;
        DBus.Connection conn;
        Throbber[] phase = new Throbber[3];
        Throbber throbber_session;
        Throbber throbber_shutdown;
        int current_phase = 0;
        Gtk.ProgressBar progress;
        SlideNotebook notebook;
        Gtk.ScrolledWindow user_scrolled_window;
        Gtk.ListStore user_list;
        Gtk.TreeView user_treeview;
        Gtk.Table login_prompt;
        Gtk.Label label_prompt;
        Gtk.Entry entry_prompt;
        Gtk.HButtonBox button_box;
        string username;
        Gtk.Label label_message;
        uint id_pulse = 0;

        Gtk.DrawingArea face_authentication;
        Timeline face_authentication_refresh;
        int face_authentication_sem_pixels_id = 0;
        int face_authentication_pixels_id = 0;
        int face_authentication_status_id = 0;
        unowned uchar* face_authentication_pixels = null;
        int* face_authentication_status = null;

        string theme = "chicken-curie";
        string layout = "horizontal";
        string bg = "#1B242D";
        string text = "#7BC4F5";
        float yposition = 0.5f;

        public signal void login(string username);
        public signal void passwd(string passwd);
        public signal void restart();
        public signal void shutdown();

        public Splash(Server server)
        {
            GLib.debug ("create splash window");
            socket = server;
            socket.phase.connect(on_phase_changed);
            socket.pulse.connect(on_start_pulse);
            socket.progress.connect(on_progress);
            socket.progress_orientation.connect(on_progress_orientation);
        }

        construct
        {
            load_config();

            if (theme != null)
            {
                string gtkrc = Config.PACKAGE_DATA_DIR + "/" + theme + "/gtkrc"; 
                if (GLib.FileUtils.test (gtkrc, FileTest.EXISTS))
                {
                    GLib.debug ("Load theme %s", gtkrc);
                    Gtk.rc_add_default_file (gtkrc);
                    Gtk.rc_parse (gtkrc);
                    Gtk.rc_reparse_all ();
                    Gtk.rc_reset_styles (Gtk.Settings.get_default ());
                }
            }

            user_list = new Gtk.ListStore (5, typeof (Gdk.Pixbuf),
                                              typeof (string), typeof (string),
                                              typeof (int), typeof (bool));
            Gdk.Screen screen = Gdk.Screen.get_default();
            Gdk.Rectangle geometry;
            screen.get_monitor_geometry(0, out geometry);

            set_app_paintable(true);
            set_default_size(geometry.width, geometry.height);
            set_colormap (screen.get_rgba_colormap ());

            GLib.debug ("splash window geometry (%i,%i)", geometry.width, geometry.height);
            fullscreen();

            destroy.connect(Gtk.main_quit);

            var alignment = new Gtk.Alignment(0.5f, yposition, 0, 0);
            alignment.show();
            add(alignment);

            var vbox = new Gtk.VBox(false, 75);
            vbox.set_border_width(25);
            vbox.show();
            alignment.add(vbox);

            Gtk.Box box = null;
            GLib.debug ("layout: %s", layout);
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
                GLib.debug ("load %s", Config.PACKAGE_DATA_DIR + "/" + theme + "/distrib-logo.png");

                Gdk.Pixbuf pixbuf =
                    new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + theme + "/distrib-logo.png");

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
                GLib.warning ("error on loading %s: %s",
                              Config.PACKAGE_DATA_DIR + "/" + theme + "/distrib-logo.png",
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
                GLib.debug ("load %s", Config.PACKAGE_DATA_DIR + "/" + theme + "/logo.png");

                Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + theme + "/logo.png");
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
                GLib.warning ("error on loading %s: %s",
                              Config.PACKAGE_DATA_DIR + "/" + theme + "/logo.png",
                              err.message);
            }

            alignment = new Gtk.Alignment(0.5f, 0.5f, 0, 0);
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

            progress = new Gtk.ProgressBar();
            progress.show();
            table_progress.attach(progress, 2, 3, 0, 1, Gtk.AttachOptions.EXPAND | Gtk.AttachOptions.FILL,
                                  0, 0, 0);

            on_start_pulse();
        }

        private void
        load_config()
        {
            GLib.debug ("load config %s", Config.PACKAGE_CONFIG_FILE);

            if (FileUtils.test(Config.PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile();
                    config.load_from_file(Config.PACKAGE_CONFIG_FILE, KeyFileFlags.NONE);
                    theme = config.get_string("splash", "theme");
                    layout = config.get_string("splash", "layout");
                    bg = config.get_string("splash", "background");
                    text = config.get_string("splash", "text");
                    yposition = (float)config.get_double("splash", "yposition");
                }
                catch (GLib.Error err)
                {
                    GLib.warning ("error on read %s: %s",
                                  Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
            else
            {
                GLib.warning ("unable to found %s", Config.PACKAGE_CONFIG_FILE);
            }
        }

        private Gdk.Pixbuf
        get_face_pixbuf (int shm_id)
        {
            unowned uchar* src = (uchar*)Posix.shmat(shm_id, null, 0);
            uchar[] dst = new uchar [ICON_SIZE * ICON_SIZE * 4];
            GLib.Memory.copy (dst, src, ICON_SIZE * ICON_SIZE * 4);
            Posix.shmdt (src);

            Cairo.ImageSurface surface = new Cairo.ImageSurface.for_data (dst, 
                                                                          Cairo.Format.ARGB32,
                                                                          ICON_SIZE, ICON_SIZE,
                                                                          Cairo.Format.ARGB32.stride_for_width (ICON_SIZE));
            CairoContext ctx = new CairoContext (surface);
            return ctx.to_pixbuf ();
        }

        private void
        reload_user_list (int nb_users)
        {
            if (conn == null)
            {
                try
                {
                    conn = DBus.Bus.get (DBus.BusType.SYSTEM);
                }
                catch (DBus.Error err)
                {
                    GLib.warning ("Error on connect to dbus system: %s", err.message);
                }
            }

            user_list.clear ();

            for (int cpt = 0; cpt < nb_users; ++cpt)
            {
                XSAA.User user = (XSAA.User)conn.get_object ("fr.supersonicimagine.XSAA.Manager.User", 
                                                             "/fr/supersonicimagine/XSAA/Manager/User/%i".printf (cpt),
                                                             "fr.supersonicimagine.XSAA.Manager.User");

                Gdk.Pixbuf pixbuf = get_face_pixbuf (user.face_icon_shm_id);

                string login = user.login;
                GLib.debug ("add user %s in list", login);

                Gtk.TreeIter iter;
                user_list.append (out iter);
                user_list.set (iter, 0, pixbuf, 1, "<span size='x-large'>" + user.real_name + "</span>",
                                     2, login, 3, user.frequency, 4, true);
            }

            Gtk.TreeIter iter;
            user_list.append (out iter);
            user_list.set (iter, 0, null, 1, "<span size='x-large'>Other...</span>",
                                 2, null, 3, 0, 4, true);
        }

        private void
        construct_loading_page()
        {
            GLib.debug ("construct loading page");

            var table = new Gtk.Table(4, 2, false);
            table.show();
            table.set_border_width(12);
            table.set_col_spacings(12);
            table.set_row_spacings(12);

            var label = new Gtk.Label("<span size='xx-large' color='" +
                                  text +"'>Loading...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach(label, 0, 1, 0, 1,
                         Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                         Gtk.AttachOptions.FILL,
                         0, 0);

            try
            {
                phase[0] = new Throbber(theme, 83);
                phase[0].show();
                phase[0].start();
                table.attach(phase[0], 1, 2, 0, 1,
                             Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                             Gtk.AttachOptions.FILL,
                             0, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            label = new Gtk.Label("<span size='xx-large' color='" +
                                  text +"'>Checking filesystem...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach(label, 0, 1, 1, 2,
                         Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                         Gtk.AttachOptions.FILL,
                         0, 0);

            try
            {
                phase[1] = new Throbber(theme, 83);
                phase[1].show();
                table.attach(phase[1], 1, 2, 1, 2,
                             Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                             Gtk.AttachOptions.FILL,
                             0, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            label = new Gtk.Label("<span size='xx-large' color='" +
                                  text +"'>Starting...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach(label, 0, 1, 2, 3,
                         Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                         Gtk.AttachOptions.FILL,
                         0, 0);

            try
            {
                phase[2] = new Throbber(theme, 83);
                phase[2].show();
                table.attach(phase[2], 1, 2, 2, 3,
                             Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                             Gtk.AttachOptions.FILL,
                             0, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            notebook.append_page(table, null);
        }

        private void
        construct_login_page()
        {
            GLib.debug ("construct login page");

            var alignment = new Gtk.Alignment(0.5f, 1.0f, 1.0f, 1.0f);
            alignment.show();

            var box = new Gtk.VBox(false, 12);
            box.show();
            alignment.add(box);

            user_scrolled_window = new Gtk.ScrolledWindow (null, null);
            user_scrolled_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
            user_scrolled_window.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            user_scrolled_window.set_size_request (-1, ICON_SIZE + 5);
            user_scrolled_window.set_shadow_type (Gtk.ShadowType.IN);
            user_scrolled_window.show ();
            box.pack_start (user_scrolled_window, true, true, 12);

            var model = new Gtk.TreeModelFilter (user_list, null);
            model.set_visible_column (4);
            user_treeview = new Gtk.TreeView.with_model (model);
            user_treeview.can_focus = false;
            user_treeview.headers_visible = false;
            user_treeview.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (), "pixbuf", 0);
            user_treeview.insert_column_with_attributes (-1, "", new Gtk.CellRendererText (), "markup", 1);
            user_treeview.get_selection ().changed.connect (on_selection_changed);
            user_treeview.show ();
            user_scrolled_window.add (user_treeview);

            face_authentication_refresh = new Timeline(60, 60);
            face_authentication_refresh.loop = true;
            face_authentication_refresh.new_frame.connect (on_refresh_face_authentication);

            face_authentication = new Gtk.DrawingArea ();
            face_authentication.set_size_request (320, 240);
            face_authentication.expose_event.connect (on_face_authentication_expose_event);
            box.pack_start(face_authentication, false, false, 0);

            login_prompt = new Gtk.Table(1, 3, false);
            login_prompt.set_border_width(12);
            login_prompt.set_col_spacings(12);
            login_prompt.set_row_spacings(12);
            box.pack_start(login_prompt, true, true, 0);

            label_prompt = new Gtk.Label("<span size='xx-large' color='" +
                                         text +"'>Login :</span>");
            label_prompt.set_use_markup(true);
            label_prompt.set_alignment(0.0f, 0.5f);
            label_prompt.show();
            login_prompt.attach (label_prompt, 1, 2, 0, 1,
                                 Gtk.AttachOptions.FILL,
                                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                                 0, 0);

            entry_prompt = new Gtk.Entry();
            entry_prompt.can_focus = true;
            entry_prompt.show();
            login_prompt.attach (entry_prompt, 2, 3, 0, 1,
                                 Gtk.AttachOptions.FILL,
                                 Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                                 0, 0);

            label_message = new Gtk.Label("");
            label_message.set_use_markup(true);
            label_message.set_alignment(0.5f, 0.5f);
            box.pack_start(label_message, false, false, 0);

            button_box = new Gtk.HButtonBox();
            button_box.show();
            button_box.set_spacing(12);
            button_box.set_layout(Gtk.ButtonBoxStyle.END);
            box.pack_start(button_box, false, false, 0);

            var button = new Gtk.Button.with_label("Restart");
            button.can_focus = false;
            button.show();
            button.clicked.connect(on_restart_clicked);
            button_box.pack_start(button, false, false, 0);

            button = new Gtk.Button.with_label("Shutdown");
            button.can_focus = false;
            button.show();
            button.clicked.connect(on_shutdown_clicked);
            button_box.pack_start(button, false, false, 0);

            notebook.append_page(alignment, null);
        }

        private void
        construct_launch_session_page()
        {
            GLib.debug ("construct launch session page");

            var table = new Gtk.Table(1, 2, false);
            table.show();
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
                GLib.warning ("Error on loading throbber %s", err.message);
            }

            notebook.append_page(table, null);
        }

        private void
        construct_shutdown_page()
        {
            GLib.debug ("construct shutdown page");

            var table = new Gtk.Table(1, 2, false);
            table.show();
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
                GLib.warning ("error on loading throbber %s", err.message);
            }

            notebook.append_page(table, null);
        }

        private void
        on_phase_changed(int new_phase)
        {
            GLib.message ("phase changed current = %i, new = %i",
                          current_phase, new_phase);

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
            GLib.debug ("start pulse");

            if (id_pulse == 0)
            {
                id_pulse = GLib.Timeout.add(83, on_pulse);
            }
        }

        private void
        on_refresh_face_authentication (int num_frame)
        {
            if ((int)face_authentication_status == -1)
                ipc_start ();

            if ((int)face_authentication_status != -1)
            {
                switch (*face_authentication_status)
                {
                    case FaceAuthenticationStatus.STARTED:
                        face_authentication.queue_draw ();
                        break;
                    case FaceAuthenticationStatus.STOPPED:
                        GLib.Idle.add (() => { 
                            face_authentication_refresh.stop ();
                            face_authentication_refresh.rewind ();

                            Posix.shmdt (face_authentication_pixels);
                            Posix.shmdt (face_authentication_status);
                            face_authentication_pixels = null;
                            face_authentication_status = null;
                            return false;
                        });
                        break;
                    default:
                        break;
                }
            }
        }

        private void
        ipc_start ()
        {
            face_authentication_sem_pixels_id = Posix.semget (FACE_AUTHENTICATION_IPC_KEY_SEM_IMAGE, 
                                                              1, Posix.IPC_CREAT | 0666);

            face_authentication_pixels_id = Posix.shmget (FACE_AUTHENTICATION_IPC_KEY_IMAGE, 
                                                          FACE_AUTHENTICATION_IMAGE_SIZE,
                                                          Posix.IPC_CREAT | 0666);
            if ((int)face_authentication_pixels_id != -1)
            {
                face_authentication_pixels = Posix.shmat (face_authentication_pixels_id, null, 0);
                if ((int)face_authentication_pixels == -1)
                {
                    GLib.warning ("error on get face authentication pixels mem: %s", GLib.strerror (GLib.errno));
                }
            }

            face_authentication_status_id = Posix.shmget (FACE_AUTHENTICATION_IPC_KEY_STATUS, 
                                                           sizeof (int), Posix.IPC_CREAT | 0666);
            if ((int)face_authentication_status_id != -1)
            {
                face_authentication_status = Posix.shmat (face_authentication_status_id, null, 0);
                if ((int)face_authentication_status == -1)
                {
                    GLib.warning ("error on get face authentication status mem: %s", GLib.strerror (GLib.errno));
                }
            }
        }

        private Cairo.ImageSurface?
        get_face_authentication_surface ()
        {
            Cairo.ImageSurface? surface = null;

            if ((int)face_authentication_pixels == -1)
                ipc_start ();

            if ((int)face_authentication_status != -1 && 
                (int)face_authentication_pixels != -1 && 
                *face_authentication_status == FaceAuthenticationStatus.STARTED)
            {
                surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                                  FACE_AUTHENTICATION_IMAGE_WIDTH,
                                                  FACE_AUTHENTICATION_IMAGE_HEIGHT);

                unowned uchar* dst = surface.get_data ();
                unowned uchar* src = face_authentication_pixels;

                for (int i = 0; i < FACE_AUTHENTICATION_IMAGE_WIDTH; ++i)
                {
                    for (int j = 0; j < FACE_AUTHENTICATION_IMAGE_HEIGHT; ++j)
                    {
                        dst[0] = src[0];
                        dst[1] = src[1];
                        dst[2] = src[2];
                        dst[3] = 255;
                        src += 3;
                        dst += 4;
                    }
                }

                surface.mark_dirty ();
                surface.flush ();
            }

            return surface;
        }

        private bool
        on_face_authentication_expose_event (Gdk.EventExpose event)
        {
            if (face_authentication_pixels != null)
            {
                Cairo.Surface surface = get_face_authentication_surface ();
                if (surface != null)
                {
                    CairoContext ctx = new CairoContext.from_widget (face_authentication);
                    ctx.set_operator (Cairo.Operator.SOURCE);
                    ctx.set_source_surface (surface, 0, 0);
                    ctx.paint ();
                }
            }

            return true;
        }

        private void
        on_progress(int val)
        {
            GLib.debug ("progress = %i", val);

            if (id_pulse > 0) GLib.Source.remove(id_pulse);
            id_pulse = 0;
            progress.set_fraction((double)val / (double)100);
        }

        private void
        on_progress_orientation(Gtk.ProgressBarOrientation orientation)
        {
            GLib.debug ("progress orientation");
            progress.set_orientation(orientation);
        }

        private void
        on_selection_changed ()
        {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (user_treeview.get_selection ().get_selected (out model, out iter))
            {
                model.get (iter, 2, out username, -1);

                GLib.debug ("selected %s", username);

                user_treeview.set_sensitive (false);
                user_scrolled_window.set_size_request (-1, ICON_SIZE + 5);
                login_prompt.show ();
                entry_prompt.can_focus = true;
                set_focus (entry_prompt);
                if (username != null)
                {
                    if (user_list.get_iter_first (out iter))
                    {
                        do
                        {
                            string login;
                            user_list.get (iter, 2, out login, -1);
                            user_list.set (iter, 4, login == username, -1);
                        } while (user_list.iter_next (ref iter));
                    }
                    on_login_enter ();
                }
                else
                {
                    user_scrolled_window.hide ();
                }
                login_prompt.parent.resize_children ();
            }
            else
            {
                username = null;
                user_scrolled_window.show ();
                user_scrolled_window.set_size_request (-1, -1);
                user_treeview.set_sensitive (true);
                login_prompt.hide ();
                face_authentication.hide ();
                button_box.show ();
                if (user_list.get_iter_first (out iter))
                {
                    do
                    {
                        user_list.set (iter, 4, true, -1);
                    } while (user_list.iter_next (ref iter));
                }
                login_prompt.parent.resize_children ();
            }
        }

        private void
        on_login_enter()
        {
            if (username == null)
                username = entry_prompt.get_text();

            GLib.debug ("login enter user: %s", username);
            if (username.length > 0)
            {
                entry_prompt.set_sensitive (false);
                login(username);
            }
        }

        private void
        on_passwd_enter()
        {
            GLib.debug ("passwd enter user: %s", username);

            entry_prompt.set_sensitive(false);
            entry_prompt.activate.disconnect (on_passwd_enter);
            passwd (entry_prompt.get_text());
        }

        private void
        on_restart_clicked()
        {
            GLib.debug ("restart clicked");
            restart();
        }

        private void
        on_shutdown_clicked()
        {
            GLib.debug ("shutdown clicked");
            shutdown();
        }

        override void
        realize ()
        {
            GLib.debug ("realize");
            base.realize();

            if (!FileUtils.test(Config.PACKAGE_DATA_DIR + "/" + theme + "/background.png", FileTest.EXISTS))
            {
                GLib.debug ("%s not found set background color %s",
                            Config.PACKAGE_DATA_DIR + "/" + theme + "/background.png",
                            bg);
                Gdk.Color color;

                Gdk.Color.parse(bg, out color);
                modify_bg(Gtk.StateType.NORMAL, color);
                notebook.modify_bg(Gtk.StateType.NORMAL, color);

                var screen = get_window().get_screen();
                var root = screen.get_root_window();
                root.set_background(color);
            }
            else
            {
                try
                {
                    GLib.debug ("loading %s",
                                Config.PACKAGE_DATA_DIR + "/" + theme + "/background.png");

                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + theme + "/background.png");

                    Gdk.Pixmap pixmap = new Gdk.Pixmap(window, allocation.width, allocation.height, -1);
                    Gdk.Pixbuf scale = pixbuf.scale_simple(allocation.width, allocation.height, Gdk.InterpType.BILINEAR);

                    pixmap.draw_rectangle (style.bg_gc[Gtk.StateType.NORMAL], true, 0, 0,
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
                    GLib.warning ("Error on loading %s: %s",
                                  Config.PACKAGE_DATA_DIR + "/" + theme + "/background.png",
                                  err.message);
                }
            }
        }

        override void
        hide()
        {
            GLib.debug ("hide");

            throbber_session.finished();
            base.hide();
        }

        public void
        show_launch()
        {
            GLib.debug ("show launch");

            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);
            notebook.set_current_page(2);
            throbber_session.start();
        }

        public void
        show_shutdown()
        {
            GLib.debug ("show shutdown");

            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);
            notebook.set_current_page(3);
            progress.show();
            on_start_pulse();
            throbber_shutdown.start();
        }

        public void
        ask_for_login(int nb_users = -1)
        {
            GLib.debug ("ask for login");

            phase[2].finished();

            if (nb_users >= 0)
            {
                reload_user_list (nb_users);
            }

            var cursor = new Gdk.Cursor(Gdk.CursorType.LEFT_PTR);
            get_window().set_cursor(cursor);

            notebook.set_current_page(1);

            username = null;
            user_treeview.get_selection ().unselect_all ();

            label_prompt.set_markup("<span size='xx-large' color='" +
                                     text +"'>Login :</span>");
            entry_prompt.can_focus = true;
            set_focus (entry_prompt);
            entry_prompt.set_sensitive(true);
            entry_prompt.set_visibility(true);
            entry_prompt.set_text("");
            entry_prompt.activate.connect(on_login_enter);
            if (id_pulse > 0) GLib.Source.remove(id_pulse);
            id_pulse = 0;
            progress.hide();
        }

        public void
        ask_for_passwd()
        {
            GLib.debug ("ask for password");

            label_message.hide ();
            face_authentication.hide ();
            login_prompt.show ();
            entry_prompt.can_focus = true;
            set_focus (entry_prompt);
            button_box.hide ();
            entry_prompt.set_sensitive (true);
            entry_prompt.activate.disconnect (on_login_enter);
            entry_prompt.set_visibility(false);
            entry_prompt.set_text("");
            entry_prompt.activate.connect(on_passwd_enter);
            label_prompt.set_markup("<span size='xx-large' color='" +
                                    text +"'>Password :</span>");
        }

        public void
        ask_for_face_authentication()
        {
            GLib.debug ("ask for face authentication");

            ipc_start ();

            face_authentication_refresh.start ();

            login_prompt.hide ();
            face_authentication.show ();
        }

        public void
        login_message(string msg)
        {
            GLib.debug ("login message: %s", msg);

            label_message.set_markup("<span size='x-large' color='" +
                                     text +"'>" + msg + "</span>");
            label_message.show ();
        }
    }
}
