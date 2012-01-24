public class Test : Gtk.Window
{
    XSAA.FaceAuthentification.Webcam m_Webcam;
    XSAA.FaceAuthentification.Detector m_Detector;
    XSAA.Timeline                    m_Timeline;
    uchar[]                          m_Image;
    Cairo.Surface                    m_Surface;

    public Test ()
    {
        set_app_paintable (true);

        set_default_size (XSAA.FaceAuthentification.Image.WIDTH, XSAA.FaceAuthentification.Image.HEIGHT);

        destroy.connect (Gtk.main_quit);

        m_Webcam = new XSAA.FaceAuthentification.Webcam ();
        m_Detector = new XSAA.FaceAuthentification.Detector ();

        m_Image = new uint8[XSAA.FaceAuthentification.Image.SIZE];
        m_Surface = new Cairo.ImageSurface.for_data (m_Image, Cairo.Format.ARGB32,
                                                     XSAA.FaceAuthentification.Image.WIDTH,
                                                     XSAA.FaceAuthentification.Image.HEIGHT,
                                                     Cairo.Format.ARGB32.stride_for_width (XSAA.FaceAuthentification.Image.WIDTH));

        m_Timeline = new XSAA.Timeline (20, 20);
        m_Timeline.loop = true;
        m_Timeline.new_frame.connect (on_new_frame);
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
        OpenCV.IPL.Image? image = query ();
        if (image != null)
        {
            unowned uchar* dst = m_Image;

            for (int n = 0; n < XSAA.FaceAuthentification.Image.HEIGHT; ++n)
            {
                for (int m = 0; m < XSAA.FaceAuthentification.Image.WIDTH; ++m)
                {
                    OpenCV.Scalar s = OpenCV.Scalar.get_2D (image, n, m);
                    dst[0] = (uchar)s.val[0];
                    dst[1] = (uchar)s.val[1];
                    dst[2] = (uchar)s.val[2];
                    dst[3] = 0xFF;
                    dst += 4;
                }
            }
            m_Surface.mark_dirty ();
            m_Surface.flush ();

            XSAA.CairoContext ctx = new XSAA.CairoContext.from_window (window);
            ctx.set_source_surface (m_Surface, 0, 0);
            ctx.paint ();

            if (m_Detector.face_detected)
            {
                ctx.set_source_rgb (1, 1, 1);
                ctx.rectangle (m_Detector.face_information.lt.x, m_Detector.face_information.lt.y,
                               m_Detector.face_information.width, m_Detector.face_information.height);
                ctx.stroke ();

                XSAA.FaceAuthentification.Eyes eyes = m_Detector.eyes_information;
                if (eyes.le.x > 0 && eyes.le.y > 0)
                {
                    ctx.arc (eyes.le.x, eyes.le.y, 5, 0, 2 * GLib.Math.PI);
                    ctx.fill ();
                }
                if (eyes.re.x > 0 && eyes.re.y > 0)
                {
                    ctx.arc (eyes.re.x, eyes.re.y, 5, 0, 2 * GLib.Math.PI);
                    ctx.fill ();
                }
            }
        }
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
