using GLib;
using X;

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace X
{
    [CCode (cheader_filename = "X11/Xauth.h", cname="Xauth", type_id = "XAuth", free_function="XauDisposeAuth", destroy_function="")]
    public struct Auth {
        public ushort family;
        [CCode (array_length_cname = "address_length")]
        public char[] address;
        [CCode (array_length_cname = "number_length")]
        public char[] number;
        [CCode (array_length_cname = "name_length")]
        public char[] name;
        [CCode (array_length_cname = "data_length")]
        public char[] data;

        [CCode (cheader_filename = "X11/Xauth.h", cname="XauReadAuth")]
        public static unowned Auth? read(FileStream f);
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauWriteAuth", instance_pos=-1)]
        public int write(FileStream f);
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauDisposeAuth")]
        public void dispose();
        [CCode (cheader_filename = "X11/Xauth.h", cname="XauUnlockAuth")]
        public static int unlock_auth(string filename);
    }

    [CCode (cheader_filename = "X11/Xauth.h", cname="FamilyLocal")]
    public const ushort FamilyLocal;

    [CCode (has_target = false)]
    public delegate int IOErrorHandler(X.Display display);

    [CCode (cheader_filename = "X11/X.h", cname="XSetIOErrorHandler")]
    public static int set_io_error_handler(IOErrorHandler handler);

    public const X.Atom XA_INTEGER;

    [CCode (cname = "InputOnly")]
    public const int InputOnly;
}
