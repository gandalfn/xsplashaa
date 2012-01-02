static int
main (string[] inArgs)
{
    XSAA.Log.set_default_logger (new XSAA.Log.Stderr (XSAA.Log.Level.DEBUG, "test-netlink"));

    XSAA.Input.EventWatch watch[2];
    watch[0] = XSAA.Input.EventWatch.POWER_BUTTON;
    watch[1] = XSAA.Input.EventWatch.F12_BUTTON;

    XSAA.Input.Event evt = new XSAA.Input.Event (watch);
    evt.event.connect ((w, v) => {
        if (w == XSAA.Input.EventWatch.POWER_BUTTON)
            XSAA.Log.info ("power button %u", v);
        if (w == XSAA.Input.EventWatch.F12_BUTTON)
            XSAA.Log.info ("F12 button %u", v);
    });

    var loop = new GLib.MainLoop(null, false);
    loop.run ();

    return 0;
}
