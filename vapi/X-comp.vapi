using GLib;
using X;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace X
{
    [CCode (cheader_filename = "X11/Xauth.h", cname="Xauth", type_id = "XAuth", free_function="XauDisposeAuth", destroy_function="")]
    public struct Auth {
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
        public static weak Auth? read(FileStream f);
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauWriteAuth", instance_pos=-1)]
        public int write(FileStream f);
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauDisposeAuth")]
        public void dispose();
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauUnlockAuth")]
        public static int unlock_auth(string filename);
    }
    
    [CCode (cheader_filename = "X11/Xauth.h", cname="FamilyLocal")]
    public const ushort FamilyLocal;

    public static delegate int IOErrorHandler(X.Display display);

    [CCode (cheader_filename = "X11/X.h", cname="XSetIOErrorHandler")]
    public static int set_io_error_handler(IOErrorHandler handler);
}

