using GLib;
using X;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace X
{
    [Compact]
    [CCode (cheader_filename = "X11/Xauth.h", cname="Xauth", free_function="XauDisposeAuth")]
    public class Auth {
        public ushort family;
        public ushort address_length;
        public string address;
        public ushort number_length;
        public string number;
        public ushort name_length;
        public string name;
        public ushort data_length;
        public string data;
        
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauReadAuth")]
        public static Auth? ReadAuth(FileStream f);
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauWriteAuth")]
        public static int WriteAuth(FileStream f, Auth auth);
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauUnlockAuth")]
        public static int UnlockAuth(string filename);
    }
    
    [CCode (cheader_filename = "X11/Xauth.h", cname="FamilyLocal")]
    public const ushort FamilyLocal;

    public static delegate int IOErrorHandler(X.Display display);

    [CCode (cheader_filename = "X11/X.h", cname="XSetIOErrorHandler")]
    public static int set_io_error_handler(IOErrorHandler handler);
}

