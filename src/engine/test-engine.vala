public class TestWindow : Gtk.Window
{
    // properties
    private XSAA.EngineLoader m_Loader;
    private bool              m_AskPasword = false;
    private Gtk.EventBox      m_Box;
    private XSAA.Animator     m_Animator;

    public double percent { get; set; default = 1.0; }

    // methods
    public TestWindow ()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();
        set_app_paintable(true);
        set_colormap (screen.get_rgba_colormap ());
        //set_default_size (1000, 600);
        fullscreen ();

        m_Box = new Gtk.EventBox ();
        m_Box.set_above_child (false);
        m_Box.set_visible_window (true);
        m_Box.set_app_paintable (true);
        m_Box.realize.connect ((b) => { b.window.set_composited(true); });
        m_Box.expose_event.connect ((e) => {
            var cr = Gdk.cairo_create (m_Box.window);
            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            return false;
        });
        m_Box.show ();
        add (m_Box);

        m_Animator = new XSAA.Animator(60, 2000);
        uint transition = m_Animator.add_transition (0, 1, XSAA.Animator.ProgressType.LINEAR, () => {
            queue_draw ();
            return false;
        }, Gtk.main_quit);
        GLib.Value from = (double)0;
        GLib.Value to = (double)1;
        m_Animator.add_transition_property (transition, this, "percent", from, to);
        m_Loader = new XSAA.EngineLoader ("debian");
        m_Loader.engine.set_size_request (200, 200);
        m_Loader.engine.show ();
        m_Loader.engine.event_notify.connect (on_event);
        m_Box.add (m_Loader.engine);
        destroy.connect (Gtk.main_quit);

        m_Loader.engine.process_event (new XSAA.EventBoot.loading (false));
        m_Loader.engine.process_event (new XSAA.EventProgress.pulse ());
        m_Loader.engine.process_event (new XSAA.EventUser.add_user (32769, "Nicolas Bruguier", "nicolas", 1));

        GLib.Timeout.add_seconds(5, () => {
            m_Loader.engine.process_event (new XSAA.EventBoot.loading (true));
            m_Loader.engine.process_event (new XSAA.EventBoot.check_filesystem (false));
            m_Loader.engine.process_event (new XSAA.EventProgress.progress (0.33));
            return false;
        });

        GLib.Timeout.add_seconds(10, () => {
            m_Loader.engine.process_event (new XSAA.EventBoot.check_filesystem (true));
            m_Loader.engine.process_event (new XSAA.EventBoot.starting (false));
            m_Loader.engine.process_event (new XSAA.EventProgress.progress (0.66));
            return false;
        });

        GLib.Timeout.add_seconds(15, () => {
            m_Loader.engine.process_event (new XSAA.EventBoot.starting (true));
            m_Loader.engine.process_event (new XSAA.EventBoot.check_device (false));
            m_Loader.engine.process_event (new XSAA.EventProgress.progress (1.0));
            return false;
        });

        GLib.Timeout.add_seconds(20, () => {
            m_Loader.engine.process_event (new XSAA.EventBoot.check_device (true));
            m_Loader.engine.process_event (new XSAA.EventPrompt.show_login ());
            m_Loader.engine.process_event (new XSAA.EventProgress.progress (1.0));
            return false;
        });
    }

    private void
    on_event (XSAA.Event inEvent)
    {
        if (inEvent is XSAA.EventPrompt)
        {
            unowned XSAA.EventPrompt event_prompt = (XSAA.EventPrompt)inEvent;
            switch (event_prompt.args.event_type)
            {
                case XSAA.EventPrompt.Type.EDITED:
                    if (!m_AskPasword)
                    {
                        XSAA.Log.info ("Login %s", event_prompt.args.text);
                        if (event_prompt.args.face_authentification)
                        {
                            XSAA.Log.debug ("show face authentication");
                            m_Loader.engine.process_event (new XSAA.EventPrompt.show_face_authentification ());
                        }
                        else
                        {
                            m_Loader.engine.process_event (new XSAA.EventPrompt.show_password ());
                            m_Loader.engine.process_event (new XSAA.EventPrompt.message ("Please enter password"));
                        }
                        m_AskPasword = true;
                    }
                    else
                    {
                        XSAA.Log.info ("Password %s", event_prompt.args.text);
                        m_AskPasword = false;
                        m_Loader.engine.process_event (new XSAA.EventSession.loading (false));
                        GLib.Timeout.add_seconds(5, () => {
                            m_Loader.engine.process_event (new XSAA.EventSession.loading (true));
                            m_Animator.start ();
                            return false;
                        });
                    }
                    break;
            }
        }
        else if (inEvent is XSAA.EventSystem)
        {
            unowned XSAA.EventSystem event_system = (XSAA.EventSystem)inEvent;
            switch (event_system.args.event_type)
            {
                case XSAA.EventSystem.Type.REBOOT:
                    XSAA.Log.info ("reboot");
                    break;

                case XSAA.EventSystem.Type.HALT:
                    XSAA.Log.info ("halt");
                    break;
            }
        }
    }

    public override bool
    expose_event (Gdk.EventExpose inEvent)
    {
        var ctx = Gdk.cairo_create (window);
        ctx.set_operator (Cairo.Operator.CLEAR);
        ctx.paint ();

        var mask = new Cairo.Pattern.radial (allocation.width / 2, allocation.height / 2, 0, allocation.width / 2, allocation.height / 2, int.max (allocation.width, allocation.height));
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

        return true;
    }
}

static int
main (string[] inArgs)
{
    XSAA.Log.set_default_logger (new XSAA.Log.Stderr (XSAA.Log.Level.DEBUG, "xsplashaa"));

    Gtk.init (ref inArgs);

    TestWindow window = new TestWindow ();
    window.show ();
    Gtk.main ();

    return 0;
}

