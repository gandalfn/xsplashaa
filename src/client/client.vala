/* client.vala
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
    const OptionEntry[] cOptionEntries =
    {
        { "ping", 'p', 0, OptionArg.NONE, ref sPing, "Ping", null },
        { "pulse", 'u', 0, OptionArg.NONE, ref sPulse, "Pulse", null },
        { "dbus", 'd', 0, OptionArg.NONE, ref sDBus, "DBus ready", null },
        { "session", 's', 0, OptionArg.NONE, ref sSession, "Session ready", null },
        { "phase", 'a', 0, OptionArg.INT, ref sPhase, null, "PHASE" },
        { "progress", 'r', 0, OptionArg.INT, ref sProgress, null, "PROGRESS" },
        { "quit", 'q', 0, OptionArg.NONE, ref sQuit, "Quit", null },
        { "close-session", 'c', 0, OptionArg.NONE, ref sCloseSession, "Close session", null },
        { "message", 0, 0, OptionArg.STRING, ref sMessage, null, "Message" },
        { "error", 0, 0, OptionArg.STRING, ref sError, null, "Error message" },
        { "question", 0, 0, OptionArg.STRING, ref sQuestion, null, "Question message" },
        { "fatal-error", 0, 0, OptionArg.STRING, ref sFatalError, null, "Fatal error message" },
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
    static string sMessage = null;
    static string sError = null;
    static string sQuestion = null;
    static string sFatalError = null;
    static string sSocketName;

    static int
    main (string[] args)
    {
        XSAA.Log.set_default_logger (new XSAA.Log.Syslog (XSAA.Log.Level.INFO, "xsaa-client"));

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

        Client client = null;
        try
        {
            client = new Client (sSocketName);
        }
        catch (SocketError err)
        {
            return -1;
        }

        if (sQuit)
            client.quit ();
        else if (sPing)
            client.ping ();
        else if (sDBus)
            client.dbus ();
        else if (sSession)
            client.session ();
        else if (sPhase > 0)
            client.phase (sPhase);
        else if (sPulse)
            client.pulse();
        else if (sProgress > 0)
            client.progress (sProgress);
        else if (sCloseSession)
            client.close_session ();
        else if (sMessage != null)
            client.message (sMessage.substring (0, int.min (sMessage.length, 1000)).replace ("|", "-"));
        else if (sError != null)
            client.error (sError.substring (0, int.min (sError.length, 1000)).replace ("|", "-"));
        else if (sQuestion != null)
            return !client.question (sQuestion.substring (0, int.min (sQuestion.length, 1000)).replace ("|", "-")) ? 1 : 0;
        else if (sFatalError != null)
            client.fatal_error (sFatalError.substring (0, int.min (sFatalError.length, 1000)).replace ("|", "-"));
        else
            return -1;

        return 0;
    }
}

