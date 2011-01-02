/* xsaa-client.vala
 *
 * Copyright (C) 2009-2010  Nicolas Bruguier
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
        public Client(string socket_name) throws SocketError
        {
            GLib.debug ("Create client on %s", socket_name);

            base(socket_name);

            Posix.fcntl(fd, Posix.O_NONBLOCK);

            if (Posix.connect(fd, &saddr, 110) != 0)
            {
                throw new SocketError.CREATE("error on connect %s", 
                                             socket_name);
            }
        }
    }


    const OptionEntry[] option_entries = 
    {
        { "ping", 'p', 0, OptionArg.NONE, ref ping, "Ping", null },
        { "pulse", 'u', 0, OptionArg.NONE, ref pulse, "Pulse", null },
        { "dbus", 'd', 0, OptionArg.NONE, ref dbus, "DBus ready", null },
        { "session", 's', 0, OptionArg.NONE, ref session, "Session ready", null },
        { "phase", 'a', 0, OptionArg.INT, ref phase, null, "PHASE" },
        { "progress", 'r', 0, OptionArg.INT, ref progress, null, "PROGRESS" },
        { "left-to-right", 'l', 0, OptionArg.NONE, ref left_to_right, "Left to Right", null },
        { "right-to-left", 'i', 0, OptionArg.NONE, ref right_to_left, "Right to Left", null },
        { "quit", 'q', 0, OptionArg.NONE, ref quit, "Quit", null },
        { "close-session", 'c', 0, OptionArg.NONE, ref close_session, "Close session", null },
        { "socket", 0, 0, OptionArg.STRING, ref socket_name, null, "SOCKET" },
        { null }
    };

    static bool quit = false;
    static bool close_session = false;
    static bool ping = false;
    static bool pulse = false;
    static bool dbus = false;
    static bool session = false;
    static int phase = 0;
    static int progress = 0;
    static bool right_to_left = false;
    static bool left_to_right = false;
    static string socket_name;
    static Client client;

    static int
    handle_quit()
    {
        GLib.debug ("send quit");

        client.send("quit");

        return 0;
    }

    static void
    on_pong()
    {
        GLib.debug ("pong received");

        string message;
        if (client.recv(out message))
        {
            Posix.exit(0);
        }
    }

    static int
    handle_dbus()
    {
        GLib.debug ("send dbus message");

        client.send("dbus");

        return 0;
    }

    static int
    handle_session()
    {
        GLib.debug ("send session message");

        client.send("session");

        return 0;
    }

    static int
    handle_ping()
    {
        MainLoop loop = new MainLoop(null, false);

        client.in.connect(on_pong);
        client.send("ping");
        loop.run();

        return 0;
    }


    static int
    handle_phase()
    {
        GLib.debug ("send phase %i message", phase);

        client.send("phase=" + (phase - 1).to_string());

        return 0;
    }

    static int
    handle_progress()
    {
        GLib.debug ("send progress %i message", progress);

        client.send("progress=" + progress.to_string());

        return 0;
    }

    static int
    handle_right_to_left()
    {
        GLib.debug ("send right to left message");

        client.send("right-to-left");

        return 0;
    }

    static int
    handle_left_to_right()
    {
        GLib.debug ("send left to right message");

        client.send("left-to-right");

        return 0;
    }

    static int
    handle_pulse()
    {
        GLib.debug ("send pulse message");

        client.send("pulse");

        return 0;
    }

    static int
    handle_close_session()
    {
        GLib.debug ("send close session message");

        client.send("close-session");

        return 0;
    }

    static int 
    main (string[] args) 
    {
        GLib.Log.set_default_handler (Log.syslog_log_handler);

        socket_name = "/tmp/xsplashaa-socket";
        try 
        {
            var opt_context = new OptionContext("- Xsplashaa client");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(option_entries, "xsplasaa");
            opt_context.parse(ref args);
        } 
        catch (OptionError err) 
        {
            GLib.warning ("option parsing failed: %s", err.message);
            return -1;
        }

        try
        {
            client = new Client (socket_name);
        }
        catch (SocketError err)
        {
            return -1;
        }

        if (quit) 
            return handle_quit();
        else if (ping) 
            return handle_ping();
        else if (dbus) 
            return handle_dbus();
        else if (session) 
            return handle_session();
        else if (phase > 0)
            return handle_phase();
        else if (pulse)
            return handle_pulse();
        else if (progress > 0)
            return handle_progress();
        else if (right_to_left)
            return handle_right_to_left();
        else if (left_to_right)
            return handle_left_to_right();
        else if (close_session)
            return handle_close_session();

        return -1;
    }
}
