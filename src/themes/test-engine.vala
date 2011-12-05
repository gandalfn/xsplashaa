public class TestWindow : Gtk.Window
{
    // properties
    private XSAA.EngineLoader m_Loader;

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
        add (m_Loader.engine);
        destroy.connect (Gtk.main_quit);
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
