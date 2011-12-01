/* splash.vala
 *
 * Copyright (C) 2009-2011  Nicolas Bruguier
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
        INPROGRESS      = 35,

        STOPPED         = 28,
        STARTED         = 21,

        CANCEL          = 14,
        AUTHENTICATE    = 7,
        DISPLAY_ERROR   = 1,
        EXIT_GUI        = 2
    }

    public class Splash : Gtk.Window
    {
        // constants
        const int ICON_SIZE = 90;

        const Os.key_t FACE_AUTHENTICATION_IPC_KEY_SEM_IMAGE = 567816;
        const Os.key_t FACE_AUTHENTICATION_IPC_KEY_IMAGE = 567814;
        const Os.key_t FACE_AUTHENTICATION_IPC_KEY_STATUS = 567813;
        const int     FACE_AUTHENTICATION_IMAGE_WIDTH = 320;
        const int     FACE_AUTHENTICATION_IMAGE_HEIGHT = 240;
        const int     FACE_AUTHENTICATION_IMAGE_SIZE = 307200;

        // properties
        private Server              m_Socket;
        private DBus.Connection     m_Connection;
        private Throbber[]          m_Phase = new Throbber[3];
        private Throbber            m_ThrobberSession;
        private Throbber            m_ThrobberShutdown;
        private int                 m_CurrentPhase = 0;
        private Gtk.ProgressBar     m_Progress;
        private SlideNotebook       m_Notebook;
        private Gtk.ScrolledWindow  m_UserScrolledWindow;
        private Gtk.ListStore       m_UserList;
        private Gtk.TreeView        m_UserTreeview;
        private Gtk.Table           m_LoginPrompt;
        private Gtk.Label           m_LabelPrompt;
        private Gtk.Entry           m_EntryPrompt;
        private Gtk.HBox            m_ButtonBox;
        private string              m_Username;
        private Gtk.Label           m_LabelMessage;
        private uint                m_IdPulse = 0;

        private Gtk.CheckButton     m_FaceAuthenticationCheckButton;
        private Gtk.DrawingArea     m_FaceAuthentication;
        private Timeline            m_FaceAuthenticationRefresh;
        private int                 m_FaceAuthenticationSemPixelsId = 0;
        private int                 m_FaceAuthenticationPixelsId = 0;
        private int                 m_FaceAuthenticationStatusId = 0;
        private unowned uchar*      m_FaceAuthenticationPixels = null;
        private int*                m_FaceAuthenticationStatus = null;

        private string              m_Theme = "chicken-curie";
        private string              m_Layout = "horizontal";
        private string              m_Bg = "#1B242D";
        private string              m_Text = "#7BC4F5";
        private float               m_YPosition = 0.5f;

        // signals
        public signal void login(string username, bool face_authentication);
        public signal void passwd(string passwd);
        public signal void restart();
        public signal void shutdown();

        // methods
        construct
        {
            load_config();

            if (m_Theme != null)
            {
                string gtkrc = Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/gtkrc";
                if (GLib.FileUtils.test (gtkrc, FileTest.EXISTS))
                {
                    GLib.debug ("Load theme %s", gtkrc);
                    Gtk.rc_add_default_file (gtkrc);
                    Gtk.rc_parse (gtkrc);
                    Gtk.rc_reparse_all ();
                    Gtk.rc_reset_styles (Gtk.Settings.get_default ());
                }
            }

            m_UserList = new Gtk.ListStore (5, typeof (Gdk.Pixbuf),
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

            var alignment = new Gtk.Alignment(0.5f, m_YPosition, 0, 0);
            alignment.show();
            add(alignment);

            var vbox = new Gtk.VBox(false, 75);
            vbox.set_border_width(25);
            vbox.show();
            alignment.add(vbox);

            Gtk.Box box = null;
            GLib.debug ("layout: %s", m_Layout);
            if (m_Layout == "horizontal")
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
                GLib.debug ("load %s", Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/distrib-logo.png");

                Gdk.Pixbuf dl = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/distrib-logo.png");

                int width_dl, height_dl;

                if (m_Layout == "horizontal")
                {
                    width_dl = geometry.width / 3 > dl.get_width() ? dl.get_width() : geometry.width / 3;
                    height_dl = (int)((double)width_dl * ((double)dl.get_height() / (double)dl.get_width()));
                }
                else
                {
                    width_dl = geometry.width / 1.5 > dl.get_width() ? dl.get_width() : (int)(geometry.width / 1.5);
                    height_dl = (int)((double)width_dl * ((double)dl.get_height() / (double)dl.get_width()));
                }

                Gtk.Image image_dl = new Gtk.Image.from_pixbuf(dl.scale_simple(width_dl, height_dl, Gdk.InterpType.BILINEAR));
                image_dl.show();
                box.pack_start(image_dl, false, false, m_Layout == "horizontal" ? 0 : 36);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading %s: %s",
                              Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/distrib-logo.png",
                              err.message);
            }

            Gtk.Box box_info;
            if (m_Layout == "horizontal")
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
                GLib.debug ("load %s", Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/logo.png");

                Gdk.Pixbuf l = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/logo.png");
                int width_l, height_l;

                if (m_Layout == "horizontal")
                {
                    width_l = geometry.width / 3 > l.get_width() ? l.get_width() : geometry.width / 3;
                    height_l = (int)((double)width_l * ((double)l.get_height() / (double)l.get_width()));
                }
                else
                {
                    width_l = l.get_width() > geometry.width  ? geometry.width : l.get_width();
                    height_l = (int)((double)width_l * ((double)l.get_height() / (double)l.get_width()));
                }
                Gtk.Image image_l = new Gtk.Image.from_pixbuf(l.scale_simple(width_l, height_l, Gdk.InterpType.BILINEAR));
                image_l.show();
                box_info.pack_start(image_l, true, true, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading %s: %s",
                              Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/logo.png",
                              err.message);
            }

            alignment = new Gtk.Alignment(0.5f, 0.5f, 0, 0);
            alignment.show();
            box_info.pack_start(alignment, true, true, 0);

            m_Notebook = new SlideNotebook();
            m_Notebook.show();
            alignment.add(m_Notebook);
            m_Notebook.set_show_tabs(false);
            m_Notebook.set_show_border(false);

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

            m_Progress = new Gtk.ProgressBar();
            m_Progress.show();
            table_progress.attach(m_Progress, 2, 3, 0, 1, Gtk.AttachOptions.EXPAND | Gtk.AttachOptions.FILL,
                                  0, 0, 0);

            on_start_pulse();
        }

        public Splash(Server inServer)
        {
            GLib.debug ("create splash window");
            m_Socket = inServer;
            m_Socket.phase.connect(on_phase_changed);
            m_Socket.pulse.connect(on_start_pulse);
            m_Socket.progress.connect(on_progress);
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
                    m_Theme = config.get_string("splash", "theme");
                    m_Layout = config.get_string("splash", "layout");
                    m_Bg = config.get_string("splash", "background");
                    m_Text = config.get_string("splash", "text");
                    m_YPosition = (float)config.get_double("splash", "yposition");
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
        get_face_pixbuf (int inShmId)
        {
            unowned uchar* src = (uchar*)Os.shmat(inShmId, null, 0);
            uchar[] dst = new uchar [ICON_SIZE * ICON_SIZE * 4];
            GLib.Memory.copy (dst, src, ICON_SIZE * ICON_SIZE * 4);
            Os.shmdt (src);

            Cairo.ImageSurface surface = new Cairo.ImageSurface.for_data (dst,
                                                                          Cairo.Format.ARGB32,
                                                                          ICON_SIZE, ICON_SIZE,
                                                                          Cairo.Format.ARGB32.stride_for_width (ICON_SIZE));
            CairoContext ctx = new CairoContext (surface);
            return ctx.to_pixbuf ();
        }

        private void
        reload_user_list (int inNbUsers)
        {
            if (m_Connection == null)
            {
                try
                {
                    m_Connection = DBus.Bus.get (DBus.BusType.SYSTEM);
                }
                catch (DBus.Error err)
                {
                    GLib.warning ("Error on connect to dbus system: %s", err.message);
                }
            }

            m_UserList.clear ();

            for (int cpt = 0; cpt < inNbUsers; ++cpt)
            {
                XSAA.User user = (XSAA.User)m_Connection.get_object ("fr.supersonicimagine.XSAA.Manager",
                                                                     "/fr/supersonicimagine/XSAA/Manager/User/%i".printf (cpt),
                                                                     "fr.supersonicimagine.XSAA.Manager.User");

                Gdk.Pixbuf pixbuf = get_face_pixbuf (user.face_icon_shm_id);

                string login = user.login;
                GLib.debug ("add user %s in list", login);

                Gtk.TreeIter iter;
                m_UserList.append (out iter);
                m_UserList.set (iter, 0, pixbuf, 1, "<span size='x-large'>" + user.real_name + "</span>",
                                      2, login, 3, user.frequency, 4, true);
            }

            Gtk.TreeIter iter;
            m_UserList.append (out iter);
            m_UserList.set (iter, 0, null, 1, "<span size='x-large'>Other...</span>",
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
                                      m_Text +"'>Loading...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach(label, 0, 1, 0, 1,
                         Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                         Gtk.AttachOptions.FILL,
                         0, 0);

            try
            {
                m_Phase[0] = new Throbber(m_Theme, 83);
                m_Phase[0].show();
                m_Phase[0].start();
                table.attach(m_Phase[0], 1, 2, 0, 1,
                             Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                             Gtk.AttachOptions.FILL,
                             0, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            label = new Gtk.Label("<span size='xx-large' color='" +
                                  m_Text +"'>Checking filesystem...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach(label, 0, 1, 1, 2,
                         Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                         Gtk.AttachOptions.FILL,
                         0, 0);

            try
            {
                m_Phase[1] = new Throbber(m_Theme, 83);
                m_Phase[1].show();
                table.attach(m_Phase[1], 1, 2, 1, 2,
                             Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                             Gtk.AttachOptions.FILL,
                             0, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            label = new Gtk.Label("<span size='xx-large' color='" +
                                  m_Text +"'>Starting...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach(label, 0, 1, 2, 3,
                         Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                         Gtk.AttachOptions.FILL,
                         0, 0);

            try
            {
                m_Phase[2] = new Throbber(m_Theme, 83);
                m_Phase[2].show();
                table.attach(m_Phase[2], 1, 2, 2, 3,
                             Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                             Gtk.AttachOptions.FILL,
                             0, 0);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            m_Notebook.append_page(table, null);
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

            m_UserScrolledWindow = new Gtk.ScrolledWindow (null, null);
            m_UserScrolledWindow.hscrollbar_policy = Gtk.PolicyType.NEVER;
            m_UserScrolledWindow.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            m_UserScrolledWindow.set_size_request (-1, ICON_SIZE + 5);
            m_UserScrolledWindow.set_shadow_type (Gtk.ShadowType.IN);
            m_UserScrolledWindow.show ();
            box.pack_start (m_UserScrolledWindow, true, true, 12);

            var model = new Gtk.TreeModelFilter (m_UserList, null);
            model.set_visible_column (4);
            m_UserTreeview = new Gtk.TreeView.with_model (model);
            m_UserTreeview.can_focus = false;
            m_UserTreeview.headers_visible = false;
            m_UserTreeview.insert_column_with_attributes (-1, "", new Gtk.CellRendererPixbuf (), "pixbuf", 0);
            m_UserTreeview.insert_column_with_attributes (-1, "", new Gtk.CellRendererText (), "markup", 1);
            m_UserTreeview.get_selection ().changed.connect (on_selection_changed);
            m_UserTreeview.show ();
            m_UserScrolledWindow.add (m_UserTreeview);

            m_FaceAuthenticationRefresh = new Timeline(60, 60);
            m_FaceAuthenticationRefresh.loop = true;
            m_FaceAuthenticationRefresh.new_frame.connect (on_refresh_face_authentication);

            m_FaceAuthentication = new Gtk.DrawingArea ();
            m_FaceAuthentication.set_size_request (320, 240);
            m_FaceAuthentication.expose_event.connect (on_face_authentication_expose_event);
            box.pack_start(m_FaceAuthentication, false, false, 0);

            m_LoginPrompt = new Gtk.Table(1, 3, false);
            m_LoginPrompt.set_border_width(12);
            m_LoginPrompt.set_col_spacings(12);
            m_LoginPrompt.set_row_spacings(12);
            box.pack_start(m_LoginPrompt, true, true, 0);

            m_LabelPrompt = new Gtk.Label("<span size='xx-large' color='" +
                                         m_Text +"'>Login :</span>");
            m_LabelPrompt.set_use_markup(true);
            m_LabelPrompt.set_alignment(0.0f, 0.5f);
            m_LabelPrompt.show();
            m_LoginPrompt.attach (m_LabelPrompt, 1, 2, 0, 1,
                                  Gtk.AttachOptions.FILL,
                                  Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                                  0, 0);

            m_EntryPrompt = new Gtk.Entry();
            m_EntryPrompt.can_focus = true;
            m_EntryPrompt.show();
            m_LoginPrompt.attach (m_EntryPrompt, 2, 3, 0, 1,
                                  Gtk.AttachOptions.FILL,
                                  Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                                  0, 0);

            m_LabelMessage = new Gtk.Label("");
            m_LabelMessage.set_use_markup(true);
            m_LabelMessage.set_alignment(0.5f, 0.5f);
            box.pack_start(m_LabelMessage, false, false, 0);

            m_ButtonBox = new Gtk.HBox (false, 5);
            m_ButtonBox.show ();
            box.pack_start(m_ButtonBox, false, false, 0);

            m_FaceAuthenticationCheckButton = new Gtk.CheckButton ();
            m_FaceAuthenticationCheckButton.show ();
            m_ButtonBox.pack_start (m_FaceAuthenticationCheckButton, false, false, 0);
            var face_authentication_label = new Gtk.Label (null);
            face_authentication_label.show ();
            face_authentication_label.set_markup ("<span color='" +
                                                  m_Text +"'><b>Face authentification</b></span>");
            m_ButtonBox.pack_start (face_authentication_label, false, false, 0);

            Gtk.HButtonBox system_button_box = new Gtk.HButtonBox();
            system_button_box.show();
            system_button_box.set_spacing(12);
            system_button_box.set_layout(Gtk.ButtonBoxStyle.END);
            m_ButtonBox.pack_start(system_button_box, true, true, 0);

            var button = new Gtk.Button.with_label("Restart");
            button.can_focus = false;
            button.show();
            button.clicked.connect(on_restart_clicked);
            m_ButtonBox.pack_start(button, false, false, 0);

            button = new Gtk.Button.with_label("Shutdown");
            button.can_focus = false;
            button.show();
            button.clicked.connect(on_shutdown_clicked);
            m_ButtonBox.pack_start(button, false, false, 0);

            m_Notebook.append_page(alignment, null);
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
                                       m_Text +"'>Launching session...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 0, 1);

            try
            {
                m_ThrobberSession = new Throbber(m_Theme, 83);
                m_ThrobberSession.show();
                table.attach_defaults(m_ThrobberSession, 1, 2, 0, 1);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("Error on loading throbber %s", err.message);
            }

            m_Notebook.append_page(table, null);
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
                                       m_Text +"'>Shutdown in progress...</span>");
            label.set_use_markup(true);
            label.set_alignment(0.0f, 0.5f);
            label.show();
            table.attach_defaults(label, 0, 1, 0, 1);

            try
            {
                m_ThrobberShutdown = new Throbber(m_Theme, 83);
                m_ThrobberShutdown.show();
                table.attach_defaults(m_ThrobberShutdown, 1, 2, 0, 1);
            }
            catch (GLib.Error err)
            {
                GLib.warning ("error on loading throbber %s", err.message);
            }

            m_Notebook.append_page(table, null);
        }

        private void
        on_phase_changed(int inNewPhase)
        {
            GLib.message ("phase changed current = %i, new = %i",
                          m_CurrentPhase, inNewPhase);

            if (m_CurrentPhase != inNewPhase)
            {
                if (m_CurrentPhase < 3 && m_CurrentPhase >= 0)
                    m_Phase[m_CurrentPhase].finished();
                if (inNewPhase < 3 && inNewPhase >= 0)
                    m_Phase[inNewPhase].start();
                m_CurrentPhase = inNewPhase;
            }
        }

        private bool
        on_pulse()
        {
            m_Progress.pulse();
            return true;
        }

        private void
        on_start_pulse()
        {
            GLib.debug ("start pulse");

            if (m_IdPulse == 0)
            {
                m_IdPulse = GLib.Timeout.add(83, on_pulse);
            }
        }

        private void
        on_refresh_face_authentication (int inNumFrame)
        {
            if ((int)m_FaceAuthenticationStatus == -1)
                ipc_start ();

            if ((int)m_FaceAuthenticationStatus != -1)
            {
                switch (*m_FaceAuthenticationStatus)
                {
                    case FaceAuthenticationStatus.STARTED:
                        m_FaceAuthentication.queue_draw ();
                        break;
                    case FaceAuthenticationStatus.STOPPED:
                        GLib.Idle.add (() => {
                            m_FaceAuthenticationRefresh.stop ();
                            m_FaceAuthenticationRefresh.rewind ();

                            Os.shmdt (m_FaceAuthenticationPixels);
                            Os.shmdt (m_FaceAuthenticationStatus);
                            m_FaceAuthenticationPixels = null;
                            m_FaceAuthenticationStatus = null;
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
            m_FaceAuthenticationSemPixelsId = Os.semget (FACE_AUTHENTICATION_IPC_KEY_SEM_IMAGE,
                                                         1, Os.IPC_CREAT | 0666);

            m_FaceAuthenticationPixelsId = Os.shmget (FACE_AUTHENTICATION_IPC_KEY_IMAGE,
                                                       FACE_AUTHENTICATION_IMAGE_SIZE,
                                                       Os.IPC_CREAT | 0666);
            if ((int)m_FaceAuthenticationPixelsId != -1)
            {
                m_FaceAuthenticationPixels = Os.shmat (m_FaceAuthenticationPixelsId, null, 0);
                if ((int)m_FaceAuthenticationPixels == -1)
                {
                    GLib.warning ("error on get face authentication pixels mem: %s", GLib.strerror (GLib.errno));
                }
            }

            m_FaceAuthenticationStatusId = Os.shmget (FACE_AUTHENTICATION_IPC_KEY_STATUS,
                                                      sizeof (int), Os.IPC_CREAT | 0666);
            if ((int)m_FaceAuthenticationStatusId != -1)
            {
                m_FaceAuthenticationStatus = Os.shmat (m_FaceAuthenticationStatusId, null, 0);
                if ((int)m_FaceAuthenticationStatus == -1)
                {
                    GLib.warning ("error on get face authentication status mem: %s", GLib.strerror (GLib.errno));
                }
            }
        }

        private Cairo.ImageSurface?
        get_face_authentication_surface ()
        {
            Cairo.ImageSurface? surface = null;

            if ((int)m_FaceAuthenticationPixels == -1)
                ipc_start ();

            if ((int)m_FaceAuthenticationStatus != -1 &&
                (int)m_FaceAuthenticationPixels != -1 &&
                *m_FaceAuthenticationStatus == FaceAuthenticationStatus.STARTED)
            {
                surface = new Cairo.ImageSurface (Cairo.Format.ARGB32,
                                                  FACE_AUTHENTICATION_IMAGE_WIDTH,
                                                  FACE_AUTHENTICATION_IMAGE_HEIGHT);

                unowned uchar* dst = surface.get_data ();
                unowned uchar* src = m_FaceAuthenticationPixels;

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
        on_face_authentication_expose_event (Gdk.EventExpose inEvent)
        {
            if (m_FaceAuthenticationPixels != null)
            {
                Cairo.Surface surface = get_face_authentication_surface ();
                if (surface != null)
                {
                    CairoContext ctx = new CairoContext.from_widget (m_FaceAuthentication);
                    ctx.set_operator (Cairo.Operator.CLEAR);
                    ctx.paint ();

                    ctx.set_operator (Cairo.Operator.OVER);
                    ctx.rounded_rectangle ((m_FaceAuthentication.parent.allocation.width - 320) / 2,
                                           0,
                                           320, 240, 10, CairoCorner.ALL);
                    ctx.clip ();
                    ctx.set_source_surface (surface,
                                            (m_FaceAuthentication.parent.allocation.width - 320) / 2,
                                            0);
                    ctx.paint ();
                }
            }

            return true;
        }

        private void
        on_progress(int inVal)
        {
            GLib.debug ("progress = %i", inVal);

            if (m_IdPulse > 0) GLib.Source.remove(m_IdPulse);
            m_IdPulse = 0;
            m_Progress.set_fraction((double)inVal / (double)100);
        }

        private void
        on_selection_changed ()
        {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (m_UserTreeview.get_selection ().get_selected (out model, out iter))
            {
                model.get (iter, 2, out m_Username, -1);

                GLib.debug ("selected %s", m_Username);

                m_UserTreeview.set_sensitive (false);
                m_UserScrolledWindow.set_size_request (-1, ICON_SIZE + 5);
                m_LoginPrompt.show ();
                m_EntryPrompt.can_focus = true;
                set_focus (m_EntryPrompt);
                if (m_Username != null)
                {
                    if (m_UserList.get_iter_first (out iter))
                    {
                        do
                        {
                            string login;
                            m_UserList.get (iter, 2, out login, -1);
                            m_UserList.set (iter, 4, login == m_Username, -1);
                        } while (m_UserList.iter_next (ref iter));
                    }
                    on_login_enter ();
                }
                else
                {
                    m_UserScrolledWindow.hide ();
                }
                m_LoginPrompt.parent.resize_children ();
            }
            else
            {
                m_Username = null;
                m_UserScrolledWindow.show ();
                m_UserScrolledWindow.set_size_request (-1, -1);
                m_UserTreeview.set_sensitive (true);
                m_LoginPrompt.hide ();
                m_FaceAuthentication.hide ();
                m_ButtonBox.show ();
                if (m_UserList.get_iter_first (out iter))
                {
                    do
                    {
                        m_UserList.set (iter, 4, true, -1);
                    } while (m_UserList.iter_next (ref iter));
                }
                m_LoginPrompt.parent.resize_children ();
            }
        }

        private void
        on_login_enter()
        {
            if (m_Username == null)
                m_Username = m_EntryPrompt.get_text();

            GLib.debug ("login enter user: %s", m_Username);
            if (m_Username.length > 0)
            {
                m_EntryPrompt.set_sensitive (false);
                login(m_Username, m_FaceAuthenticationCheckButton.active);
            }
        }

        private void
        on_passwd_enter()
        {
            GLib.debug ("passwd enter user: %s", m_Username);

            m_EntryPrompt.set_sensitive(false);
            m_EntryPrompt.activate.disconnect (on_passwd_enter);
            passwd (m_EntryPrompt.get_text());
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

        internal override void
        realize ()
        {
            GLib.debug ("realize");
            base.realize();

            if (!FileUtils.test(Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/background.png", FileTest.EXISTS))
            {
                GLib.debug ("%s not found set background color %s",
                            Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/background.png",
                            m_Bg);
                Gdk.Color color;

                Gdk.Color.parse(m_Bg, out color);
                modify_bg(Gtk.StateType.NORMAL, color);
                m_Notebook.modify_bg(Gtk.StateType.NORMAL, color);

                var screen = get_window().get_screen();
                var root = screen.get_root_window();
                root.set_background(color);
            }
            else
            {
                try
                {
                    GLib.debug ("loading %s",
                                Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/background.png");

                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file(Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/background.png");

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
                                  Config.PACKAGE_DATA_DIR + "/" + m_Theme + "/background.png",
                                  err.message);
                }
            }
        }

        internal override void
        hide()
        {
            GLib.debug ("hide");

            m_FaceAuthenticationRefresh.stop ();
            m_ThrobberSession.finished();
            base.hide();
        }

        public void
        show_launch()
        {
            GLib.debug ("show launch");

            m_FaceAuthentication.hide ();
            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);
            m_Notebook.set_current_page(2);
            m_ThrobberSession.start();
        }

        public void
        show_shutdown()
        {
            GLib.debug ("show shutdown");

            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);
            m_Notebook.set_current_page(3);
            m_Progress.show();
            on_start_pulse();
            m_ThrobberShutdown.start();
        }

        public void
        ask_for_login(int inNbUsers = -1)
        {
            GLib.debug ("ask for login");

            m_Phase[2].finished();

            if (inNbUsers >= 0)
            {
                reload_user_list (inNbUsers);
            }

            var cursor = new Gdk.Cursor(Gdk.CursorType.LEFT_PTR);
            get_window().set_cursor(cursor);

            m_Notebook.set_current_page(1);

            m_Username = null;
            m_UserTreeview.get_selection ().unselect_all ();

            m_LabelPrompt.set_markup("<span size='xx-large' color='" +
                                     m_Text +"'>Login :</span>");
            m_EntryPrompt.can_focus = true;
            set_focus (m_EntryPrompt);
            m_EntryPrompt.set_sensitive(true);
            m_EntryPrompt.set_visibility(true);
            m_EntryPrompt.set_text("");
            m_EntryPrompt.activate.connect(on_login_enter);
            if (m_IdPulse > 0) GLib.Source.remove(m_IdPulse);
            m_IdPulse = 0;
            m_Progress.hide();
        }

        public void
        ask_for_passwd()
        {
            GLib.debug ("ask for password");

            m_LabelMessage.hide ();
            m_FaceAuthentication.hide ();
            m_LoginPrompt.show ();
            m_EntryPrompt.can_focus = true;
            set_focus (m_EntryPrompt);
            m_ButtonBox.hide ();
            m_EntryPrompt.set_sensitive (true);
            m_EntryPrompt.activate.disconnect (on_login_enter);
            m_EntryPrompt.set_visibility(false);
            m_EntryPrompt.set_text("");
            m_EntryPrompt.activate.connect(on_passwd_enter);
            m_LabelPrompt.set_markup("<span size='xx-large' color='" +
                                     m_Text +"'>Password :</span>");
        }

        public void
        ask_for_face_authentication()
        {
            GLib.debug ("ask for face authentication");

            ipc_start ();

            m_FaceAuthenticationRefresh.start ();

            m_ButtonBox.hide ();
            m_LoginPrompt.hide ();
            m_FaceAuthentication.show ();
        }

        public void
        login_message(string inMsg)
        {
            GLib.debug ("login message: %s", inMsg);

            m_LabelMessage.set_markup("<span size='x-large' color='" +
                                       m_Text +"'>" + inMsg + "</span>");
            m_LabelMessage.show ();
        }
    }
}

