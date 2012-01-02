static int
main (string[] inArgs)
{
    XSAA.Log.set_default_logger (new XSAA.Log.Stderr (XSAA.Log.Level.DEBUG, "test-netlink"));

    try
    {
        XSAA.Netlink.Socket socket = new XSAA.Netlink.Socket (XSAA.Netlink.Socket.group (XSAA.Netlink.Message.acpi_group ()));
        socket.in.connect (() => {
                XSAA.Log.debug ("received acpi event");
                try
                {
                    XSAA.Netlink.Message<XSAA.Netlink.Message.HeaderGenlAcpi> recv = new XSAA.Netlink.Message<XSAA.Netlink.Message.HeaderGenlAcpi>.raw (16384);
                    socket.recv (ref recv);
                    foreach (XSAA.Netlink.Message.HeaderGenlAcpi msg in recv)
                    {
                        XSAA.Log.info ("%s %s %lu %lu", msg.event_device_class, msg.event_bus_id, msg.event_type, msg.event_data);
                    }
                }
                catch (XSAA.Netlink.SocketError e)
                {
                    XSAA.Log.error ("error on parse acpi event");
                }
        });

        var loop = new GLib.MainLoop(null, false);
        loop.run ();
    }
    catch (GLib.Error err)
    {
        XSAA.Log.error ("error: %s", err.message);
    }

    return 0;
}
