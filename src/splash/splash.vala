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
    public class Splash : Gtk.Window
    {
        // types
        public enum Phase
        {
            LOADING,
            CHECK_FILESYSTEM,
            STARTING,
            CHECK_DEVICE,
            SESSION
        }

        // properties
        private Server          m_Socket;
        private DBus.Connection m_Connection;
        private int             m_CurrentPhase = 0;
        private string          m_Username;
        private bool            m_UseCompositing = true;
        private Gtk.EventBox    m_Box;
        private XSAA.Animator   m_Animator;
        private EngineLoader    m_EngineLoader;

        // accessors
        public Phase current_phase {
            get {
                return (Phase)m_CurrentPhase;
            }
        }
        public uint main_width { get; private set; default = 0; }
        public uint main_height { get; private set; default = 0; }
        public uint touchscreen_width { get; private set; default = 0; }
        public uint touchscreen_height { get; private set; default = 0; }
        public double percent { get; set; default = 1.0; }

        // signals
        public signal void login(string username, bool face_authentication);
        public signal void passwd(string passwd);
        public signal void restart();
        public signal void shutdown();
        public signal void question_response (EventMessage.Response inResult);

        // methods
        construct
        {
            m_UseCompositing = Gdk.Display.get_default ().supports_composite ();

            load_config();

            Gdk.Screen screen = Gdk.Screen.get_default();
            screen.composited_changed.connect (on_composite_changed);
            Gdk.Rectangle geometry;
            screen.get_monitor_geometry(0, out geometry);

            set_app_paintable(true);
            set_default_size(geometry.width, geometry.height);
            set_colormap (screen.get_rgba_colormap ());
            set_decorated (false);

            Log.debug ("splash window geometry (%i,%i)", geometry.width, geometry.height);
            fullscreen();
            destroy.connect(Gtk.main_quit);

            m_Box = new Gtk.EventBox ();
            m_Box.set_above_child (false);
            m_Box.set_visible_window (m_UseCompositing);
            if (m_UseCompositing)
            {
                m_Box.set_app_paintable (true);
                m_Box.realize.connect ((b) => { b.window.set_composited(true); });
                m_Box.expose_event.connect ((e) => {
                    var cr = Gdk.cairo_create (m_Box.window);
                    cr.set_operator (Cairo.Operator.CLEAR);
                    cr.paint ();
                    return false;
                });
            }
            m_Box.show ();
            add (m_Box);

            m_Animator = new XSAA.Animator(30, 1000);
            uint transition = m_Animator.add_transition (0, 1, XSAA.Animator.ProgressType.SINUSOIDAL, () => {
                queue_draw ();
                return false;
            }, () => {
                base.hide ();

                m_EngineLoader.engine.process_event (new EventPrompt.show_login ());
            });

            GLib.Value from = (double)0;
            GLib.Value to = (double)1;
            m_Animator.add_transition_property (transition, this, "percent", from, to);

            if (m_EngineLoader != null)
            {
                m_EngineLoader.engine.event_notify.connect (on_event_notify);
                m_EngineLoader.engine.show ();
                m_Box.add (m_EngineLoader.engine);

                m_EngineLoader.engine.process_event (new EventProgress.pulse ());
                set_phase_status (Phase.LOADING, EventBoot.Status.PENDING);
            }
        }

        public Splash(Server inServer)
        {
            Log.debug ("create splash window");

            m_Socket = inServer;
            m_Socket.phase.connect(on_phase_changed);
            m_Socket.pulse.connect(on_start_pulse);
            m_Socket.progress.connect(progress);
            m_Socket.message.connect (message);
            m_Socket.error.connect (error);
        }

        private void
        load_config()
        {
            Log.debug ("load config %s", Config.PACKAGE_CONFIG_FILE);

            if (FileUtils.test(Config.PACKAGE_CONFIG_FILE, FileTest.EXISTS))
            {
                try
                {
                    KeyFile config = new KeyFile();
                    config.load_from_file(Config.PACKAGE_CONFIG_FILE, KeyFileFlags.NONE);
                    string name = config.get_string("splash", "theme");
                    m_EngineLoader = new EngineLoader (name);
                }
                catch (GLib.Error err)
                {
                    Log.warning ("error on read %s: %s",
                                  Config.PACKAGE_CONFIG_FILE, err.message);
                }
            }
            else
            {
                Log.warning ("unable to find %s", Config.PACKAGE_CONFIG_FILE);
            }
        }

        private void
        on_composite_changed ()
        {
            if (window != null && window.is_visible () && !window.get_screen ().is_composited ())
            {
                Log.debug ("Composite changed and window is visible");
                Gdk.Display display = Gdk.Display.get_default ();
                for (int cpt = 0; cpt < display.get_n_screens (); ++cpt)
                {
                    Gdk.Screen screen = display.get_screen(cpt);
                    Gdk.Window root = screen.get_root_window ();
                    Gdk.property_delete (root, Gdk.Atom.intern ("_XROOTPMAP_ID", true));
                    Gdk.property_delete (root, Gdk.Atom.intern ("ESETROOT_PMAP_ID", true));
                }
                window.hide ();
                display.flush ();
                window.show ();
                window.focus (Gdk.CURRENT_TIME);
                display.flush ();
            }
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
                    Log.warning ("Error on connect to dbus system: %s", err.message);
                }
            }

            m_EngineLoader.engine.process_event (new EventUser.clear ());

            for (int cpt = 0; cpt < inNbUsers; ++cpt)
            {
                XSAA.User user = (XSAA.User)m_Connection.get_object ("fr.supersonicimagine.XSAA.Manager",
                                                                     "/fr/supersonicimagine/XSAA/Manager/User/%i".printf (cpt),
                                                                     "fr.supersonicimagine.XSAA.Manager.User");

                if (user != null && m_EngineLoader != null)
                {
                    string login = user.login;
                    Log.debug ("add user %s in list", login);

                    m_EngineLoader.engine.process_event (new EventUser.add_user (user.face_icon_shm_id, user.real_name, user.login, (int)user.frequency));
                }
            }
        }

        private void
        on_event_notify (Event inEvent)
        {
            if (inEvent is EventPrompt)
            {
                unowned EventPrompt? event_prompt = (EventPrompt?)inEvent;
                switch (event_prompt.args.event_type)
                {
                    case EventPrompt.Type.EDITED:
                        if (m_Username == null)
                        {
                            m_Username = event_prompt.args.text;
                            if (m_Username.length > 0)
                            {
                                Log.debug ("login enter user: %s", m_Username);
                                login (m_Username, event_prompt.args.face_authentification);
                            }
                            else
                            {
                                m_Username = null;
                            }
                        }
                        else
                        {
                            passwd (event_prompt.args.text);
                        }
                        break;
                }
            }
            else if (inEvent is EventSystem)
            {
                unowned EventSystem? event_system = (EventSystem?)inEvent;
                switch (event_system.args.event_type)
                {
                    case EventSystem.Type.REBOOT:
                        restart ();
                        break;

                    case EventSystem.Type.HALT:
                        shutdown ();
                        break;

                    case EventSystem.Type.MONITOR:
                        main_width = event_system.args.main_width;
                        main_height = event_system.args.main_height;
                        touchscreen_width = event_system.args.touchscreen_width;
                        touchscreen_height = event_system.args.touchscreen_height;
                        break;
                }
            }
            else if (inEvent is EventMessage)
            {
                unowned EventMessage? event_message = (EventMessage?)inEvent;
                switch (event_message.args.event_type)
                {
                    case EventMessage.Type.RESULT:
                        question_response (event_message.args.result);
                        break;
                }
            }
        }

        private void
        on_start_pulse ()
        {
            Log.debug ("start pulse");

            m_EngineLoader.engine.process_event (new EventProgress.pulse ());
        }

        private void
        on_phase_changed(int inNewPhase)
        {
            Log.info ("phase changed current = %i, new = %i", m_CurrentPhase, inNewPhase);

            if (m_CurrentPhase != inNewPhase)
            {
                set_phase_status ((Phase)m_CurrentPhase, EventBoot.Status.FINISHED);
                set_phase_status ((Phase)inNewPhase, EventBoot.Status.PENDING);
                m_CurrentPhase = inNewPhase;
            }
        }

        internal override bool
        expose_event (Gdk.EventExpose inEvent)
        {
            if (m_UseCompositing)
            {
                double x = allocation.width / 2.0;
                double y = allocation.height / 2.0;
                double radial = (double)int.max (allocation.width, allocation.height);

                var ctx = Gdk.cairo_create (window);

                Gdk.cairo_region (ctx, inEvent.region);
                ctx.clip ();

                ctx.set_operator (Cairo.Operator.CLEAR);
                ctx.paint ();

                if (main_width > 0 && main_height > 0)
                {
                    x = main_width / 2.0;
                    y = main_height / 2.0;
                    radial = (double)uint.max (main_width, main_height + touchscreen_height);
                }

                var mask = new Cairo.Pattern.radial (x, y, 0, x, y, radial);
                if (percent < 1 )
                {
                    mask.add_color_stop_rgba (1, 0, 0, 0, 1);
                    mask.add_color_stop_rgba (percent + 0.01, 0, 0, 0, 1);
                    mask.add_color_stop_rgba (percent, 0, 0, 0, 0);
                    mask.add_color_stop_rgba (0, 0, 0, 0, 0);
                }
                ctx.set_operator (Cairo.Operator.OVER);
                var box_ctx = Gdk.cairo_create (m_Box.window);
                ctx.set_source_surface (box_ctx.get_target (), 0, 0);
                if (percent < 1 )
                {
                    ctx.mask (mask);
                }
                else
                {
                    ctx.paint ();
                }
            }

            return m_UseCompositing;
        }

        internal override void
        hide()
        {
            Log.debug ("hide");

            m_Animator.start ();
        }

        public void
        set_phase_status (Phase inPhase, EventBoot.Status inStatus)
        {
            switch (inPhase)
            {
                case Phase.LOADING:
                    m_EngineLoader.engine.process_event (new EventBoot.loading (inStatus));
                    break;
                case Phase.CHECK_FILESYSTEM:
                    m_EngineLoader.engine.process_event (new EventBoot.check_filesystem (inStatus));
                    break;
                case Phase.STARTING:
                    m_EngineLoader.engine.process_event (new EventBoot.starting (inStatus));
                    break;
                case Phase.CHECK_DEVICE:
                    m_EngineLoader.engine.process_event (new EventBoot.check_device (inStatus));
                    break;
                case Phase.SESSION:
                    m_EngineLoader.engine.process_event (new EventSession.loading ((EventSession.Status)inStatus));
                    break;
            }
        }

        public void
        progress(int inVal)
        {
            Log.debug ("progress = %i", inVal);

            m_EngineLoader.engine.process_event (new EventProgress.progress ((double)inVal / 100.0));
        }

        public void
        show_shutdown()
        {
            Log.debug ("show shutdown");

            var cursor = new Gdk.Cursor(Gdk.CursorType.BLANK_CURSOR);
            get_window().set_cursor(cursor);

            m_EngineLoader.engine.process_event (new EventProgress.pulse ());
            m_EngineLoader.engine.process_event (new EventBoot.shutdown (EventBoot.Status.PENDING));
        }

        public void
        ask_for_login(int inNbUsers = -1)
        {
            Log.debug ("ask for login");

            var cursor = new Gdk.Cursor(Gdk.CursorType.LEFT_PTR);
            get_window().set_cursor(cursor);

            m_Username = null;

            if (inNbUsers >= 0)
            {
                reload_user_list (inNbUsers);
            }

            m_EngineLoader.engine.process_event (new EventPrompt.show_login ());
        }

        public void
        ask_for_passwd ()
        {
            Log.debug ("ask for password");

            m_EngineLoader.engine.process_event (new EventPrompt.show_password ());
        }

        public void
        ask_for_face_authentication()
        {
            Log.debug ("ask for face authentication");

            m_EngineLoader.engine.process_event (new EventPrompt.show_face_authentification ());
        }

        public void
        login_message (string inMsg)
        {
            Log.debug ("login message: %s", inMsg);

            m_EngineLoader.engine.process_event (new EventPrompt.message (inMsg));
        }

        public void
        message (string inMessage)
        {
            Log.debug ("message = %s", inMessage);

            m_EngineLoader.engine.process_event (new EventMessage.message (inMessage));
        }

        public void
        error (string inMessage)
        {
            Log.debug ("error = %s", inMessage);

            m_EngineLoader.engine.process_event (new EventMessage.error (inMessage));
        }

        public void
        question (string inMessage)
        {
            Log.debug ("question = %s", inMessage);

            m_EngineLoader.engine.process_event (new EventMessage.question (inMessage));
        }
    }
}

