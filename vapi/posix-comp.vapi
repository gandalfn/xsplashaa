[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix
{
    [CCode (cheader_filename = "math.h")]
    public const double M_PI;

    [CCode (cheader_filename = "asm/ioctls.h")]
    public const int TIOCNOTTY;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int PF_UNIX;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SOL_SOCKET;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SO_REUSEADDR;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SO_PEERCRED;

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int getsockopt(int fd, int level, int optname, ...);

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int setsockopt(int fd, int level, int optname, ...);

    [CCode (cheader_filename = "sys/un.h", cname = "struct sockaddr_un", destroy_function="")]
    public struct SockAddrUn : Posix.SockAddr {
        public int sun_family;
        public char sun_path[108];
    }

    [SimpleType]
    [CCode (cheader_filename = "features.h,sys/socket.h", cname = "struct ucred", destroy_function="")]
    public struct UCred {
        public pid_t pid;
        public uid_t uid;
        public gid_t gid;
    }

    [CCode (cheader_filename = "stdlib.h")]
    public int putenv(string env);

    [CCode (cheader_filename = "stdlib.h")]
    public int unsetenv(string name);

    [CCode (cheader_filename = "stdlib.h")]
    public int setenv(string name, string val, int overwrite);

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

    [SimpleType]
    [CCode (cheader_filename = "setjmp.h")]
    public struct jmp_buf
    {
    }

    [CCode (cheader_filename = "setjmp.h")]
    public int setjmp(jmp_buf env);

    [CCode (cheader_filename = "setjmp.h")]
    public void longjmp(jmp_buf env, int val);

    [CCode (cheader_filename = "sys/ipc.h,sys/shm.h")]
    int shmget(key_t key, size_t size, int shmflg);

    [CCode (cheader_filename = "sys/types.h,sys/shm.h")]
    public void *shmat(int shmid, void *shmaddr, int shmflg);

    [CCode (cheader_filename = "sys/types.h,sys/shm.h")]
    public int shmdt(void *shmaddr);

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_CREAT;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_EXCL;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_NOWAIT;
}


