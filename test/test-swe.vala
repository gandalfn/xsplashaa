// types
public enum ProgressType
{
    LINEAR,
    SINUSOIDAL,
    EXPONENTIAL,
    EASE_IN_EASE_OUT;

    internal double
    calculate_progress (double inValue)
    {
        double progress = inValue;

        switch (this)
        {
            case LINEAR:
                break;

            case SINUSOIDAL:
                progress = GLib.Math.sin ((progress * GLib.Math.PI) / 2);
                break;

            case EXPONENTIAL:
                progress *= progress;
                break;

            case EASE_IN_EASE_OUT:
                progress *= 2;
                if (progress < 1)
                    progress = GLib.Math.pow (progress, 3) / 2;
                else
                    progress = (GLib.Math.pow (progress - 2, 3) + 2) / 2;
                break;
        }

        return progress;
    }
}

public class Item : GLib.Object
{

}

public class Bounce
{
    double m_X;
    double m_Y;
    double m_Radius;
    Gdk.Color m_Bg;
    Gdk.Color m_Fg;
    Cairo.Context m_Ctx;

    public Bounce (Cairo.Context inCtx, double inX, double inY, double inRadius, Gdk.Color inFg, Gdk.Color inBg)
    {

        m_X = inX;
        m_Y = inY;
        m_Radius = inRadius;
        m_Fg = inFg;
        m_Bg = inBg;
    }

    public void
    draw (Cairo.Context inCtx, double inProgress)
    {
        inCtx.arc (m_X, m_Y, m_Radius, 0.0, GLib.Math.PI * 2.0);
        Cairo.Pattern pattern =  new Cairo.Pattern.radial (m_X, m_Y, 0, m_X, m_Y, m_Radius);
        pattern.add_color_stop_rgba (0.0, m_Fg.red / 65535.0, m_Fg.green / 65535.0, m_Fg.blue / 65535.0, 0.0);
        pattern.add_color_stop_rgba (inProgress - 0.2, m_Fg.red / 65535.0, m_Fg.green / 65535.0, m_Fg.blue / 65535.0, 0.0);
        pattern.add_color_stop_rgba (inProgress - 0.1, m_Fg.red / 65535.0, m_Fg.green / 65535.0, m_Fg.blue / 65535.0, 1 - inProgress);
        pattern.add_color_stop_rgba (inProgress, m_Fg.red / 65535.0, m_Fg.green / 65535.0, m_Fg.blue / 65535.0, 0.0);
        pattern.add_color_stop_rgba (1.0, m_Fg.red / 65535.0, m_Fg.green / 65535.0, m_Fg.blue / 65535.0, 0.0);
        inCtx.set_source (pattern);
        inCtx.fill ();
    }
}
public class WindowSWE : Gtk.Window
{
    Bounce             m_Bounce;
    int                m_NbFrames = 60;
    int                m_NumFrame;

    public WindowSWE ()
    {
        set_default_size (400, 400);

        m_Bounce = new Bounce (200, 200, 100, style.bg[Gtk.StateType.SELECTED], style.fg[Gtk.StateType.NORMAL]);

        GLib.Timeout.add (20, () => {
            m_NumFrame++;
            if (m_NumFrame > m_NbFrames) m_NumFrame = 0;
            queue_draw ();
            return true;
        });
    }

    public override bool
    expose_event (Gdk.EventExpose inEvent)
    {
        var ctx = Gdk.cairo_create (window);

        m_Bounce.draw (ctx, ProgressType.EASE_IN_EASE_OUT.calculate_progress((double)m_NumFrame / (double)m_NbFrames));

        return true;
    }
}

static int
main (string[] inArgs)
{
    Gtk.init (ref inArgs);

    WindowSWE window = new WindowSWE ();
    window.show ();

    Gtk.main ();

    return 0;
}
