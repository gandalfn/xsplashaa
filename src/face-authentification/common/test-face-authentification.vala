public class Test : Gtk.Window
{
    const int SCAN_COUNT = 20;

    XSAA.FaceAuthentification.Webcam   m_Webcam;
    XSAA.FaceAuthentification.Detector m_Detector;
    XSAA.FaceAuthentification.Verifier m_Verifier;
    XSAA.Timeline                      m_Timeline;
    Gtk.DrawingArea                    m_Area;
    uint                               m_Count;
    uint                               m_Matches;
    double                             m_Average;
    uint                               m_CountScan;
    OpenCV.IPL.Image                   m_Sets[13];
    uint                               m_CurrentSet = 0;

    public Test ()
    {
        set_app_paintable (true);

        set_default_size (XSAA.FaceAuthentification.Image.WIDTH * 2, XSAA.FaceAuthentification.Image.HEIGHT * 2);

        destroy.connect (Gtk.main_quit);

        m_Webcam = new XSAA.FaceAuthentification.Webcam ();
        m_Detector = new XSAA.FaceAuthentification.Detector ();
        m_Verifier = new XSAA.FaceAuthentification.Verifier ();

        m_Timeline = new XSAA.Timeline (20, 20);
        m_Timeline.loop = true;
        m_Timeline.new_frame.connect (on_new_frame);

        m_Area = new Gtk.DrawingArea ();
        m_Area.show ();
        add (m_Area);

        m_Area.expose_event.connect (on_expose_event);
    }

    ~Test ()
    {
        m_Webcam.stop ();
    }

    private OpenCV.IPL.Image?
    query ()
    {
        OpenCV.IPL.Image? image = m_Webcam.query_frame ();
        if (image != null)
        {
            m_Detector.run (image);
        }

        return image;
    }

    private void
    on_new_frame (int inNumframe)
    {
        m_Area.queue_draw ();
        if (inNumframe > m_Count)
        {
            m_Count++;
        }
        else
        {
            m_Average = (double)m_Matches / (double)m_Count;
            m_Matches = 0;
            m_Count = 0;
        }
    }

    private bool
    on_expose_event (Gdk.EventExpose inEvent)
    {
        OpenCV.IPL.Image? image = query ();
        if (image != null)
        {
            Cairo.Surface surface;

            XSAA.CairoContext ctx = new XSAA.CairoContext.from_widget (m_Area);
            surface = m_Webcam.frame_to_cairo_surface (image);

            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.translate (m_Area.allocation.width, 0);
            ctx.scale (-((double)m_Area.allocation.width / (double)XSAA.FaceAuthentification.Image.WIDTH),
                       (double)m_Area.allocation.height / (double)XSAA.FaceAuthentification.Image.HEIGHT);
            ctx.set_source_surface (surface, 0, 0);
            ctx.paint ();

            ctx.set_operator (Cairo.Operator.OVER);
            if (m_Detector.face_detected)
            {
                Cairo.ImageSurface mask = new Cairo.ImageSurface (Cairo.Format.A1,
                                                                  XSAA.FaceAuthentification.Image.WIDTH,
                                                                  XSAA.FaceAuthentification.Image.HEIGHT);
                XSAA.CairoContext ctx_mask = new XSAA.CairoContext (mask);
                ctx_mask.set_source_rgba (1, 1, 1, 1);
                ctx_mask.paint ();
                ctx_mask.set_operator (Cairo.Operator.CLEAR);
                ctx_mask.set_source_rgba (1, 1, 1, 0);
                ctx_mask.rounded_rectangle (m_Detector.face_information.lt.x, m_Detector.face_information.lt.y,
                                            m_Detector.face_information.width, m_Detector.face_information.height,
                                            10, XSAA.CairoCorner.ALL);
                ctx_mask.fill ();

                ctx.set_source_rgba (0, 0, 0, 0.8);
                ctx.mask_surface (mask, 0, 0);

                ctx.set_source_rgb (1, 1, 1);
                ctx.rounded_rectangle (m_Detector.face_information.lt.x, m_Detector.face_information.lt.y,
                                       m_Detector.face_information.width, m_Detector.face_information.height,
                                       10, XSAA.CairoCorner.ALL);
                ctx.stroke ();

                if (m_Detector.eyes_detected)
                {
                    XSAA.FaceAuthentification.Eyes eyes = m_Detector.eyes_information;

                    m_CountScan++;
                    if (m_CountScan > SCAN_COUNT)
                        m_CountScan = 0;

                    Cairo.Pattern pattern = new Cairo.Pattern.linear (eyes.le.x - 10, eyes.le.y - 10,
                                                                      eyes.le.x - 10, eyes.le.y + 20);
                    double progress = 0.0;
                    if (((double)m_CountScan / (double)SCAN_COUNT) <= 0.5)
                        progress = ((double)m_CountScan / (double)SCAN_COUNT) * 2;
                    else
                        progress = (1 - ((double)m_CountScan / (double)SCAN_COUNT)) * 2;
                    pattern.add_color_stop_rgba (0, 0, 0, 1, 0.0);
                    pattern.add_color_stop_rgba (double.max (progress - 0.2, 0.0), 0, 1, 0.5, 0.0);
                    pattern.add_color_stop_rgba (double.max (progress - 0.05, 0.0), 0, 1, 0.5, 0.6);
                    pattern.add_color_stop_rgba (progress, 0, 1, 0.5, 0.7);
                    pattern.add_color_stop_rgba (double.min (progress + 0.05, 1.0), 0, 1, 0.5, 0.6);
                    pattern.add_color_stop_rgba (double.min (progress + 0.2, 1.0), 0, 1, 0.5, 0.0);
                    pattern.add_color_stop_rgba (1, 0, 0, 1, 0.0);
                    ctx.set_source (pattern);
                    ctx.rounded_rectangle (eyes.le.x - 10, eyes.le.y - 10,
                                           (eyes.re.x - eyes.le.x) + 20, (eyes.re.y - eyes.le.y) + 20,
                                           5, XSAA.CairoCorner.ALL);
                    ctx.fill ();
//                    if (eyes.le.x > 0 && eyes.le.y > 0)
//                    {
//                        ctx.arc (eyes.le.x, eyes.le.y, 5, 0, 2 * GLib.Math.PI);
//                        ctx.fill ();
//                    }
//                    if (eyes.re.x > 0 && eyes.re.y > 0)
//                    {
//                        ctx.arc (eyes.re.x, eyes.re.y, 5, 0, 2 * GLib.Math.PI);
//                        ctx.fill ();
//                    }
                    m_Matches++;
                }
            }

//            if (m_Detector.status == XSAA.FaceAuthentification.Detector.Status.TRACKING)
//            {
//                if (m_CurrentSet < m_Sets.length)
//                {
//                    m_Sets[m_CurrentSet] = m_Detector.clip_face(image);
//                    m_CurrentSet++;
//                }
//                if (m_CurrentSet >= m_Sets.length)
//                {
//                    m_Verifier.add_face_set (m_Sets);
//                    Posix.exit (0);
//                }
//            }
            ctx.translate (XSAA.FaceAuthentification.Image.WIDTH, 0);
            ctx.scale (-1, 1);
            ctx.move_to (0, 0);

            XSAA.FaceAuthentification.VerifyStatus status = 0;
            if (m_Detector.status == XSAA.FaceAuthentification.Detector.Status.TRACKING)
            {
                OpenCV.IPL.Image? im = m_Detector.clip_face (image);
                if (im != null)
                {
                    m_Webcam.frame_to_cairo_surface (im).write_to_png ("out.png");
                    status = m_Verifier.verify_face (im);
                }
            }

            Pango.Layout layout = Pango.cairo_create_layout (ctx);
            string msg = "Detector status = %i\nMatches = %i %%\nVerifier status = %i".printf (m_Detector.status,
                                                                                               (int)(m_Average * 100.0),
                                                                                               status);
            layout.set_text (msg, (int)msg.length);

            Pango.FontDescription desc = Pango.FontDescription.from_string ("Sans Bold 10");
            layout.set_font_description (desc);

            ctx.set_source_rgb (1, 1, 1);
            Pango.cairo_update_layout (ctx, layout);
            Pango.cairo_show_layout (ctx, layout);
        }

        return false;
    }

    public override void
    realize ()
    {
        base.realize ();

        m_Webcam.start ();
        m_Timeline.start ();
    }
}

static int
main (string[] inArgs)
{
    Gtk.init (ref inArgs);

    Test test = new Test ();
    test.show ();

    Gtk.main ();

    return 0;
}
