/* xsaa-client.vala
 *
 * Copyright (C) 2009-2011  Nicolas Bruguier
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA
{
    public class Client : Socket
    {
        // methods
        public Client(string inSocketName) throws SocketError
        {
            GLib.debug ("Create client on %s", inSocketName);

            base(inSocketName);

            Os.fcntl(m_Fd, Os.O_NONBLOCK);

            if (Os.connect(m_Fd, &m_SAddr, 110) != 0)
            {
                throw new SocketError.CREATE("error on connect %s",
                                             inSocketName);
            }
        }
    }


    const OptionEntry[] cOptionEntries =
    {
        { "ping", 'p', 0, OptionArg.NONE, ref sPing, "Ping", null },
        { "pulse", 'u', 0, OptionArg.NONE, ref sPulse, "Pulse", null },
        { "dbus", 'd', 0, OptionArg.NONE, ref sDBus, "DBus ready", null },
        { "session", 's', 0, OptionArg.NONE, ref sSession, "Session ready", null },
        { "phase", 'a', 0, OptionArg.INT, ref sPhase, null, "PHASE" },
        { "progress", 'r', 0, OptionArg.INT, ref sProgress, null, "PROGRESS" },
        { "left-to-right", 'l', 0, OptionArg.NONE, ref sLeftToRight, "Left to Right", null },
        { "right-to-left", 'i', 0, OptionArg.NONE, ref sRightToLeft, "Right to Left", null },
        { "quit", 'q', 0, OptionArg.NONE, ref sQuit, "Quit", null },
        { "close-session", 'c', 0, OptionArg.NONE, ref sCloseSession, "Close session", null },
        { "socket", 0, 0, OptionArg.STRING, ref sSocketName, null, "SOCKET" },
        { null }
    };

    static bool   sQuit = false;
    static bool   sCloseSession = false;
    static bool   sPing = false;
    static bool   sPulse = false;
    static bool   sDBus = false;
    static bool   sSession = false;
    static int    sPhase = 0;
    static int    sProgress = 0;
    static bool   sRightToLeft = false;
    static bool   sLeftToRight = false;
    static string sSocketName;
    static Client sClient;

    static int
    handle_quit()
    {
        GLib.debug ("send quit");

        sClient.send("quit");

        return 0;
    }

    static void
    on_pong()
    {
        GLib.debug ("pong received");

        string message;
        if (sClient.recv(out message))
        {
            Os.exit(0);
        }
    }

    static int
    handle_dbus()
    {
        GLib.debug ("send dbus message");

        sClient.send("dbus");

        return 0;
    }

    static int
    handle_session()
    {
        GLib.debug ("send session message");

        sClient.send("session");

        return 0;
    }

    static int
    handle_ping()
    {
        MainLoop loop = new MainLoop(null, false);

        sClient.in.connect(on_pong);
        sClient.send("ping");
        loop.run();

        return 0;
    }


    static int
    handle_phase()
    {
        GLib.debug ("send phase %i message", sPhase);

        sClient.send("phase=" + (sPhase - 1).to_string());

        return 0;
    }

    static int
    handle_progress()
    {
        GLib.debug ("send progress %i message", sProgress);

        sClient.send("progress=" + sProgress.to_string());

        return 0;
    }

    static int
    handle_right_to_left()
    {
        GLib.debug ("send right to left message");

        sClient.send("right-to-left");

        return 0;
    }

    static int
    handle_left_to_right()
    {
        GLib.debug ("send left to right message");

        sClient.send("left-to-right");

        return 0;
    }

    static int
    handle_pulse()
    {
        GLib.debug ("send pulse message");

        sClient.send("pulse");

        return 0;
    }

    static int
    handle_close_session()
    {
        GLib.debug ("send close session message");

        sClient.send("close-session");

        return 0;
    }

    static int
    main (string[] args)
    {
        XSAA.Log.set_default_logger (new XSAA.Log.Syslog (XSAA.Log.Level.DEBUG, "xsaa-client"));

        sSocketName = "/tmp/xsplashaa-socket";
        try
        {
            var opt_context = new OptionContext("- Xsplashaa client");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(cOptionEntries, "xsplasaa");
            opt_context.parse(ref args);
        }
        catch (OptionError err)
        {
            GLib.warning ("option parsing failed: %s", err.message);
            return -1;
        }

        try
        {
            sClient = new Client (sSocketName);
        }
        catch (SocketError err)
        {
            return -1;
        }

        if (sQuit)
            return handle_quit();
        else if (sPing)
            return handle_ping();
        else if (sDBus)
            return handle_dbus();
        else if (sSession)
            return handle_session();
        else if (sPhase > 0)
            return handle_phase();
        else if (sPulse)
            return handle_pulse();
        else if (sProgress > 0)
            return handle_progress();
        else if (sRightToLeft)
            return handle_right_to_left();
        else if (sLeftToRight)
            return handle_left_to_right();
        else if (sCloseSession)
            return handle_close_session();

        return -1;
    }
}
