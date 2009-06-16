[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix
{
    [CCode (cheader_filename = "asm/ioctls.h")]
    public const int TIOCNOTTY;

    [CCode (cheader_filename = "sys/socket.h")]
	public const int PF_UNIX;
	
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SOL_SOCKET;
	
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SO_REUSEADDR;
	
	[CCode (cheader_filename = "sys/socket.h")]
    public int setsockopt(int fd, int level, int optname, void* optval, size_t optlen);
	
	[Compact]
    [CCode (cheader_filename = "sys/socket.h", cname = "struct sockaddr", free_function="g_free")]
	public class sockaddr {
	}
	
    [Compact]
    [CCode (cheader_filename = "sys/un.h", cname = "struct sockaddr_un", free_function="g_free")]
	public class sockaddr_un : sockaddr {
	    public int sun_family;
	    public char[108] sun_path;
	}

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
	public int accept (int sockfd, ...);

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
	public int connect (int sockfd, ...);

    [CCode (cheader_filename = "sys/socket.h")]
	public int listen (int sockfd, int backlog);

    [CCode (cheader_filename = "signal.h")]
    public sighandler_t SIG_IGN;

    [CCode (cheader_filename = "stdlib.h")]
    public int putenv(string env);
    
    [CCode (cheader_filename = "stdlib.h")]
    public int setenv(string name, string val, int overwrite);
    
    [CCode (cheader_filename = "pwd.h")]
	public unowned Passwd? getpwnam (string user);

    [CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setsid ();

    [CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setegid (gid_t rgid);
    
	[CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int seteuid (uid_t ruid);

    [CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setregid (gid_t rgid, gid_t egid);
    
	[CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setreuid (uid_t ruid, uid_t euid);

    [CCode (cheader_filename = "grp.h,sys/types.h")]
    public int initgroups(string user, gid_t group);

    [CCode (cheader_filename = "unistd.h")]
	public int daemon (int nochdir, int noclose);

    [CCode (cheader_filename = "linux/kd.h")]
	public const int KDSETMODE;

    [CCode (cheader_filename = "linux/kd.h")]
	public const int KDSKBMODE;

    [CCode (cheader_filename = "linux/kd.h")]
	public const int KD_GRAPHICS;

    [CCode (cheader_filename = "linux/kd.h")]
	public const int K_RAW;

    [CCode (cheader_filename = "linux/kd.h")]
	public const int KDGKBMODE;

    [CCode (cheader_filename = "linux/vt.h")]
	public const int VT_ACTIVATE;
    
    [CCode (cheader_filename = "linux/vt.h")]
	public const int VT_WAITACTIVE;
}


