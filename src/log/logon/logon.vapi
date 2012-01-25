[CCode (cheader_filename="logon-glue.h")]
namespace logon
{
    [CCode (cname = "logon_init")]
    public static void init ();

    [CCode (cname = "logon_release")]
    public static void release ();

    [Compact]
    public class LogonEngine
    {
        [CCode (cname = "logon_engine_create")]
        public static void create (string inFilename, string inName, uint inSession, GLib.Pid inPid, string inHostname = "127.0.0.1", uint inPort = 9898, bool inResolveHost = false);
    }

    [Compact]
    public class Logon
    {
        [CCode (cname = "logon_debug")]
        public static void debug (string inModule, string inCategory, string inMessage, ...);

        [CCode (cname = "logon_notice")]
        public static void notice (string inModule, string inCategory, string inMessage, ...);

        [CCode (cname = "logon_info")]
        public static void info (string inModule, string inCategory, string inMessage, ...);

        [CCode (cname = "logon_warning")]
        public static void warning (string inModule, string inCategory, string inMessage, ...);

        [CCode (cname = "logon_error")]
        public static void error (string inModule, string inCategory, string inMessage, ...);
    }
}

