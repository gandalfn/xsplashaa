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
        set_default_size (200, 200);

        m_Loader = new XSAA.EngineLoader ("aixplorer");
        m_Loader.engine.set_size_request (200, 200);
        m_Loader.engine.show ();
        m_Loader.engine.event_notify.connect (on_event);
        add (m_Loader.engine);
        destroy.connect (Gtk.main_quit);

        m_Loader.engine.process_event (new XSAA.EventPrompt.show_login ());
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
                        m_Loader.engine.process_event (new XSAA.EventPrompt.hide ());
                        m_AskPasword = false;
                    }
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

