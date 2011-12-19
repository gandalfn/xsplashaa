static int
main (string[] inArgs)
{
    Gtk.init (ref inArgs);

    XSAA.FaceAuthentification.Webcam webcam = new XSAA.FaceAuthentification.Webcam ();

    webcam.start_camera ();

    Gtk.main ();

    webcam.stop_camera ();

    return 0;
}
