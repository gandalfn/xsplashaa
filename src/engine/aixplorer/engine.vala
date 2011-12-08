/* engine.vala
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

namespace XSAA.Aixplorer
{
    /**
     * Aixplorer theme engine
     */
    public class Engine : Goo.Canvas, XSAA.EngineItem, XSAA.Engine
    {
        // types
        public class Animation : GLib.Object
        {
            // properties
            private Animator               m_Animator;
            private string                 m_Property;
            private double                 m_Start;
            private double                 m_End;
            private unowned Goo.CanvasItem m_Item;

            // signals
            public signal void finished ();

            // methods
            public Animation (Goo.CanvasItem inItem, string inProperty, double inStart, double inEnd)
            {
                m_Animator = new Animator (60, 400);
                m_Item = inItem;
                m_Property = inProperty;
                m_Start = inStart;
                m_End = inEnd;

                uint transition = m_Animator.add_transition (0.0, 1.0, XSAA.Animator.ProgressType.EASE_IN_EASE_OUT, null, on_finished);
                GLib.Value from = (double)m_Start;
                GLib.Value to = (double)m_End;
                m_Animator.add_transition_property (transition, m_Item, m_Property, from, to);
            }

            private void
            on_finished ()
            {
                finished ();
            }

            public void
            start ()
            {
                GLib.Value start = (double)m_Start;
                m_Item.set_property (m_Property, start);
                m_Item.visibility = Goo.CanvasItemVisibility.VISIBLE;

                m_Animator.start ();
            }

            public void
            stop ()
            {
                m_Animator.stop ();

                GLib.Value end = (double)m_End;
                m_Item.set_property (m_Property, end);
            }
        }

        // private
        private string                             m_Id;
        private int                                m_Layer = -1;
        private unowned Goo.CanvasItem?            m_Root;
        private GLib.HashTable<string, EngineItem> m_Childs;
        private GLib.Queue<Animation>              m_Animations;

        // accessors
        protected GLib.HashTable<string, EngineItem>? childs {
            get {
                if (m_Childs == null)
                    m_Childs = new GLib.HashTable<string, EngineItem> (GLib.str_hash, GLib.str_equal);
                return m_Childs;
            }
        }

        internal string node_name {
            get {
                return "engine";
            }
        }

        public string id {
            get {
                return m_Id;
            }
            set {
                m_Id = value;
            }
        }

        public int layer {
            get {
                return m_Layer;
            }
            set {
                m_Layer = value;
            }
        }

        // static methods
        static construct
        {
            EngineItem.register_item ("background", typeof (Background));
            EngineItem.register_item ("logo", typeof (Logo));
            EngineItem.register_item ("text", typeof (Text));
            EngineItem.register_item ("button", typeof (Button));
            EngineItem.register_item ("checkbutton", typeof (CheckButton));
            EngineItem.register_item ("entry", typeof (Entry));
            EngineItem.register_item ("throbber", typeof (Throbber));
            EngineItem.register_item ("table", typeof (Table));
            EngineItem.register_item ("notebook", typeof (Notebook));
            EngineItem.register_item ("progressbar", typeof (ProgressBar));
            EngineItem.register_item ("users", typeof (Users));
            EngineItem.register_item ("faceauth", typeof (FaceAuthentification));

            GLib.Value.register_transform_func (typeof (string), typeof (Goo.CanvasItemVisibility),
                                                (ValueTransform)string_to_canvas_item_visibility);
            GLib.Value.register_transform_func (typeof (Goo.CanvasItemVisibility), typeof (string),
                                                (ValueTransform)canvas_item_visibility_to_string);
        }

        private static void
        canvas_item_visibility_to_string (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (Goo.CanvasItemVisibility)))
        {
            Goo.CanvasItemVisibility val = (Goo.CanvasItemVisibility)inSrc;

            outDest = val.to_string ();
        }

        private static void
        string_to_canvas_item_visibility (GLib.Value inSrc, out GLib.Value outDest)
            requires (inSrc.holds (typeof (string)))
            requires ((string)inSrc != null)
        {
            string val = (string)inSrc;

            outDest = (Goo.CanvasItemVisibility)int.parse (val);
        }

        // methods
        construct
        {
            m_Animations = new GLib.Queue<Animation> ();
        }

        /**
         * Create a new Aixplorer theme engine
         */
        public Engine ()
        {
            m_Root = get_root_item ();
        }

        private void
        process_prompt_event (EventPrompt inEvent)
        {
            unowned Notebook notebook = (Notebook)find ("main-notebook");
            unowned Notebook users_notebook = (Notebook)find ("users-notebook");
            unowned Text prompt_label = (Text)find ("prompt-label");
            unowned Text message = (Text)find ("prompt-message");
            unowned Entry prompt = (Entry)find ("prompt");
            unowned Users users = (Users)find ("users");
            unowned FaceAuthentification face_authentification = (FaceAuthentification)find ("face-auth");

            if (prompt == null || prompt_label == null || notebook == null ||
                users_notebook == null || users == null || message == null ||
                face_authentification == null)
            {
                Log.critical ("Error does not find prompt items");
                return;
            }

            switch (inEvent.args.event_type)
            {
                case EventPrompt.Type.SHOW_LOGIN:
                    prompt_label.text = "Login:";
                    prompt.text = "";
                    prompt.grab_focus ();
                    prompt.entry_visibility = true;
                    face_authentification.stop ();
                    users_notebook.current_page = 0;
                    notebook.current_page = 1;
                    break;

                case EventPrompt.Type.SHOW_PASSWORD:
                    prompt_label.text = "Password:";
                    prompt.text = "";
                    prompt.grab_focus ();
                    prompt.entry_visibility = false;
                    face_authentification.stop ();
                    users_notebook.current_page = 1;
                    notebook.current_page = 1;
                    break;

                case EventPrompt.Type.SHOW_FACE_AUTHENTIFICATION:
                    message.text = "";
                    face_authentification.start ();
                    users_notebook.current_page = 2;
                    notebook.current_page = 1;
                    break;

                case EventPrompt.Type.MESSAGE:
                    message.text = inEvent.args.msg;
                    break;
            }
        }

        private void
        process_boot_event (EventBoot inEvent)
        {
            unowned Notebook notebook = (Notebook)find ("main-notebook");
            unowned Throbber loading = (Throbber)find ("loading-throbber");
            unowned Throbber check_filesystem = (Throbber)find ("checking-filesystem-throbber");
            unowned Throbber starting = (Throbber)find ("starting-throbber");
            unowned Throbber check_device = (Throbber)find ("checking-device-throbber");
            unowned Throbber shutdown = (Throbber)find ("shutdown-throbber");

            if (loading == null || check_filesystem == null || starting == null || check_device == null || notebook == null)
            {
                Log.critical ("Error does not find boot items");
                return;
            }

            switch (inEvent.args.event_type)
            {
                case EventBoot.Type.LOADING:
                    notebook.current_page = 0;
                    if (!inEvent.args.completed)
                        loading.start ();
                    else
                        loading.finished ();
                    break;

                case EventBoot.Type.CHECK_FILESYSTEM:
                    notebook.current_page = 0;
                    if (!inEvent.args.completed)
                    {
                        unowned Table check_filesystem_table = (Table)find ("checking-filesystem");
                        Animation animation = new Animation (check_filesystem_table, "x", allocation.width, check_filesystem_table.x);
                        m_Animations.push_tail (animation);
                        animation.finished.connect (() => {
                            m_Animations.pop_tail ().ref ();
                            if (!m_Animations.is_empty ())
                                m_Animations.peek_head ().start ();
                        });
                        if (m_Animations.length == 1)
                            animation.start ();

                        check_filesystem.start ();
                    }
                    else
                        check_filesystem.finished ();
                    break;

                case EventBoot.Type.STARTING:
                    notebook.current_page = 0;
                    if (!inEvent.args.completed)
                    {
                        unowned Table starting_table = (Table)find ("starting");
                        Animation animation = new Animation (starting_table, "x", allocation.width, starting_table.x);
                        m_Animations.push_tail (animation);
                        animation.finished.connect (() => {
                            m_Animations.pop_tail ().ref ();
                            if (!m_Animations.is_empty ())
                                m_Animations.peek_head ().start ();
                        });
                        if (m_Animations.length == 1)
                            animation.start ();

                        starting.start ();
                    }
                    else
                        starting.finished ();
                    break;

                case EventBoot.Type.CHECK_DEVICE:
                    notebook.current_page = 0;
                    if (!inEvent.args.completed)
                    {
                        unowned Table check_device_table = (Table)find ("checking-device");
                        Animation animation = new Animation (check_device_table, "x", allocation.width, check_device_table.x);
                        m_Animations.push_tail (animation);
                        animation.finished.connect (() => {
                            m_Animations.pop_tail ().ref ();
                            if (!m_Animations.is_empty ())
                                m_Animations.peek_head ().start ();
                        });
                        if (m_Animations.length == 1)
                            animation.start ();

                        check_device.start ();
                    }
                    else
                        check_device.finished ();
                    break;

                case EventBoot.Type.SHUTDOWN:
                    notebook.current_page = 2;
                    if (!inEvent.args.completed)
                        shutdown.start ();
                    else
                        shutdown.finished ();
                    break;
            }
        }

        private void
        process_progress_event (EventProgress inEvent)
        {
            unowned ProgressBar progress = (ProgressBar)find ("progress-bar");

            if (progress == null)
            {
                Log.critical ("Error does not find progress items");
                return;
            }

            switch (inEvent.args.event_type)
            {
                case EventProgress.Type.PULSE:
                    progress.pulse ();
                    break;

                case EventProgress.Type.PROGRESS:
                    progress.percent = inEvent.args.progress_val;
                    break;
            }
        }

        private void
        process_session_event (EventSession inEvent)
        {
            unowned Notebook notebook = (Notebook)find ("main-notebook");
            unowned Throbber session = (Throbber)find ("launch-sesion-throbber");

            if (session == null || notebook == null)
            {
                Log.critical ("Error does not find boot items");
                return;
            }

            switch (inEvent.args.event_type)
            {
                case EventSession.Type.LOADING:
                    notebook.current_page = 0;
                    if (!inEvent.args.completed)
                    {
                        unowned Table session_table = (Table)find ("session");
                        Animation animation = new Animation (session_table, "x", allocation.width, session_table.x);
                        m_Animations.push_tail (animation);
                        animation.finished.connect (() => {
                            m_Animations.pop_tail ().ref ();
                            if (!m_Animations.is_empty ())
                                m_Animations.peek_head ().start ();
                        });
                        if (m_Animations.length == 1)
                            animation.start ();

                        session.start ();
                    }
                    else
                        session.finished ();
                    break;
            }
        }

        private void
        process_user_event (EventUser inEvent)
        {
            unowned Users users = (Users)find ("users");

            if (users == null)
            {
                Log.critical ("Error does not find users items");
                return;
            }

            switch (inEvent.args.event_type)
            {
                case EventUser.Type.ADD_USER:
                    users.add_user (inEvent.args.shm_id_pixbuf, inEvent.args.login, inEvent.args.real_name, inEvent.args.frequency);
                    break;

                case EventUser.Type.CLEAR:
                    users.clear ();
                    break;
            }
        }

        public void
        append_child (EngineItem inChild)
        {
            if (inChild is Goo.CanvasItemSimple)
            {
                childs.insert (inChild.id, inChild);
                m_Root.add_child ((Goo.CanvasItemSimple)inChild, inChild.layer);
            }
        }

        public override void
        realize ()
        {
            base.realize ();

            unowned Entry? prompt = (Entry?)find ("prompt");
            unowned Text message = (Text)find ("prompt-message");
            unowned CheckButton? face_authentification = (CheckButton?)find ("face-authentification");
            if (prompt != null)
            {
                prompt.edited.connect ((s) => {
                    Log.debug ("prompt: %s", s);
                    message.text = "";
                    event_notify (new EventPrompt.edited (s, face_authentification.active));
                });
            }

            unowned Users? users = (Users?)find ("users");
            if (users != null)
            {
                users.selected.connect ((s) => {
                    Log.debug ("prompt: %s", s);
                    if (s != null)
                    {
                        message.text = "";
                        event_notify (new EventPrompt.edited (s, face_authentification.active));
                    }
                    else
                    {
                        unowned Notebook users_notebook = (Notebook)find ("users-notebook");
                        if (users_notebook != null)
                        {
                            users_notebook.current_page = 1;
                        }
                    }
                });
            }

            unowned Button? button_restart = (Button?)find ("button-restart");
            if (button_restart != null)
            {
                button_restart.clicked.connect (() => {
                    event_notify (new EventSystem.reboot ());
                });
            }

            unowned Button? button_shutdown = (Button?)find ("button-shutdown");
            if (button_shutdown != null)
            {
                button_shutdown.clicked.connect (() => {
                    event_notify (new EventSystem.halt ());
                });
            }
        }

        public override void
        size_allocate (Gdk.Rectangle inAllocation)
        {
            Gtk.Allocation old = allocation;

            base.size_allocate (inAllocation);

            if (old.width != inAllocation.width || old.height != inAllocation.height)
            {
                set_bounds (0, 0, inAllocation.width, inAllocation.height);

                foreach (unowned EngineItem item in this)
                {
                    if (item is Item)
                    {
                        unowned ItemPackOptions? pack_options = (ItemPackOptions?)item;
                        if (pack_options.expand)
                        {
                            unowned Item? i = (Item?)item;
                            i.width = inAllocation.width;
                            i.height = inAllocation.height;
                        }
                    }
                    else if (item is Table)
                    {
                        unowned ItemPackOptions? pack_options = (ItemPackOptions?)item;
                        if (pack_options.expand)
                        {
                            unowned Table? i = (Table?)item;
                            i.width = inAllocation.width;
                            i.height = inAllocation.height;
                        }
                    }
                }
            }
        }

        public void
        process_event (Event inEvent)
        {
            if (inEvent is EventPrompt)
            {
                process_prompt_event ((EventPrompt)inEvent);
            }
            else if (inEvent is EventBoot)
            {
                process_boot_event ((EventBoot)inEvent);
            }
            else if (inEvent is EventProgress)
            {
                process_progress_event ((EventProgress)inEvent);
            }
            else if (inEvent is EventSession)
            {
                process_session_event ((EventSession)inEvent);
            }
            else if (inEvent is EventUser)
            {
                process_user_event ((EventUser)inEvent);
            }
        }
    }
}

public XSAA.Engine? plugin_init ()
{
    return new XSAA.Aixplorer.Engine ();
}

