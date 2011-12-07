public class TestWindow : Gtk.Window
{
    // properties
    private XSAA.EngineLoader m_Loader;
    private bool              m_AskPasword = false;

    // methods
    public TestWindow ()
    {
        Gdk.Screen screen = Gdk.Screen.get_default();
        set_app_paintable(true);
        set_colormap (screen.get_rgba_colormap ());
        //set_default_size (1000, 600);
        fullscreen ();

        m_Loader = new XSAA.EngineLoader ("aixplorer");
        m_Loader.engine.set_size_request (200, 200);
        m_Loader.engine.show ();
        m_Loader.engine.event_notify.connect (on_event);
        add (m_Loader.engine);
        destroy.connect (Gtk.main_quit);

        m_Loader.engine.process_event (new XSAA.EventBoot.loading (false));
        m_Loader.engine.process_event (new XSAA.EventProgress.pulse ());
        m_Loader.engine.process_event (new XSAA.EventUser.add_user (new Gdk.Pixbuf.from_file ("/home/gandalfn/.face"),
                                                                    "Nicolas Bruguier", "gandalfn", 1));

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
                        m_Loader.engine.process_event (new XSAA.EventPrompt.show_password ());
                        m_AskPasword = true;
                    }
                    else
                    {
                        XSAA.Log.info ("Password %s", event_prompt.args.text);
                        m_AskPasword = false;
                        m_Loader.engine.process_event (new XSAA.EventSession.loading (false));
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
        return false;
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
