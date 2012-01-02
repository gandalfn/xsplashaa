[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Os
{
    [CCode (cheader_filename = "asm/ioctls.h")]
    public const int TIOCNOTTY;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int PF_UNIX;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SOL_SOCKET;

    [CCode (cheader_filename = "asm/types.h,sys/socket.h,linux/netlink.h")]
    public const int SO_SNDBUF;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SO_RCVBUF;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SO_REUSEADDR;

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SO_PEERCRED;

    [CCode (cheader_filename = "fcntl.h")]
    public const int O_WRONLY;
    [CCode (cheader_filename = "fcntl.h")]
    public const int O_RDWR;
    [CCode (cheader_filename = "fcntl.h")]
    public const int O_RDONLY;
    [CCode (cheader_filename = "fcntl.h")]
    public const int O_TRUNC;
    [CCode (cheader_filename = "fcntl.h")]
    public const int O_CREAT;

    [CCode (cheader_filename = "fcntl.h")]
    public const int F_SETFD;
    [CCode (cheader_filename = "fcntl.h")]
    public const int FD_CLOEXEC;

    [CCode (cheader_filename = "sys/types.h,sys/socket.h")]
    public size_t recvmsg(int sockfd, MsgHdr msg, int flags);

    [CCode (cheader_filename = "sys/types.h,sys/socket.h")]
    public size_t sendmsg(int sockfd, MsgHdr msg, int flags);

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int getsockopt(int fd, int level, int optname, ...);

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int getsockname(int fd, ...);

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int setsockopt(int fd, int level, int optname, ...);

    [CCode (cheader_filename = "linux/netlink.h")]
    public uint32 NLMSG_ALIGN (uint32 len);

    [CCode (cheader_filename = "linux/netlink.h")]
    public uint32 RTA_ALIGN (uint32 len);

    [CCode (cheader_filename = "linux/rtnetlink.h")]
    public int RTA_PAYLOAD (void* rta);

    [CCode (cname = "struct sockaddr_nl", has_type_id = false, cheader_filename = "sys/socket.h,linux/netlink.h", destroy_function = "")]
    public struct SockAddrNl : SockAddr {
        public int nl_family;
        public ushort nl_pad;
        public uint32 nl_pid;
        public uint32 nl_groups;
    }

    [CCode (cname = "struct msghdr", has_type_id = false, cheader_filename = "sys/socket.h", destroy_function = "")]
    public struct MsgHdr
    {
        public void*                     msg_name;
        public Posix.socklen_t           msg_namelen;

        [CCode (array_length_cname = "msg_iovlen")]
        public unowned Posix.iovector[]? msg_iov;

        public void*                     msg_control;
        public size_t                    msg_controllen;
        public int                       msg_flags;
    }

    [CCode (cname = "struct nlmsghdr", has_copy_function = false, has_type_id = false, cheader_filename = "linux/netlink.h", destroy_function = "")]
    public struct NlMsgHdr
    {
        public uint32 nlmsg_len;
        public uint16 nlmsg_type;
        public uint16 nlmsg_flags;
        public uint32 nlmsg_seq;
        public uint32 nlmsg_pid;
    }

    [CCode (cheader_filename = "linux/netlink.h")]
    public void* NLMSG_DATA (NlMsgHdr nlh);

    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_PID;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_CONS;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_ODELAY;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_NDELAY;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_NOWAIT;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_EMERG;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_ALERT;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_CRIT;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_ERR;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_WARNING;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_NOTICE;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_INFO;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_DEBUG;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_KERN;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_USER;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_MAIL;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_DAEMON;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_SYSLOG;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LPR;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_NEWS;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_UUCP;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_CRON;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_AUTHPRIV;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_FTP;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL0;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL1;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL2;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL3;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL4;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL5;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL6;
    [CCode (cheader_filename = "syslog.h")]
    public const int LOG_LOCAL7;

    [SimpleType]
    [IntegerType (rank = 6)]
    [CCode (cname = "pid_t", default_value = "0", cheader_filename = "sys/types.h")]
    public struct pid_t {
    }

    [SimpleType]
    [IntegerType (rank = 9)]
    [CCode (cheader_filename = "sys/types.h")]
    public struct uid_t {
    }

    [SimpleType]
    [IntegerType (rank = 9)]
    [CCode (cheader_filename = "sys/types.h")]
    public struct gid_t {
    }

    [CCode (cname = "struct sockaddr", cheader_filename = "sys/un.h,sys/types.h,sys/socket.h", has_type_id = false, free_function = "")]
    public struct SockAddr {
    }

    [CCode (cheader_filename = "sys/un.h,sys/types.h,sys/socket.h", cname = "struct sockaddr_un", has_type_id = false, free_function="")]
    public struct SockAddrUn : SockAddr {
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

    [SimpleType]
    [IntegerType (rank = 9)]
    [CCode (cheader_filename = "sys/types.h", cname = "key_t")]
    public struct key_t {
    }

    [SimpleType]
    [IntegerType (rank = 9)]
    [CCode (cname = "mode_t", cheader_filename = "sys/types.h")]
    public struct mode_t {
    }

    [CCode (cheader_filename = "sys/socket.h")]
    public const int SOCK_DGRAM;
    [CCode (cheader_filename = "sys/socket.h")]
    public const int SOCK_RAW;
    [CCode (cheader_filename = "sys/socket.h")]
    public const int SOCK_SEQPACKET;
    [CCode (cheader_filename = "sys/socket.h")]
    public const int SOCK_STREAM;
    [CCode (cheader_filename = "sys/socket.h")]
    public const int AF_INET;
    [CCode (cheader_filename = "sys/socket.h")]
    public const int AF_INET6;
    [CCode (cheader_filename = "sys/socket.h")]
    public const int AF_UNIX;

    [CCode (cheader_filename = "fcntl.h")]
    public const int O_NONBLOCK;

    [CCode (cheader_filename = "fcntl.h")]
    public int fcntl (int fd, int cmd, ...);

    [CCode (cheader_filename = "sys/socket.h")]
    public int socket (int domain, int type, int protocol);

    [CCode (cheader_filename = "sys/socket.h",  sentinel = "")]
    public int connect(int sfd, ... );

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int accept (int sfd, ... );

    [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
    public int bind (int sockfd, ...);

    [CCode (cheader_filename = "sys/socket.h")]
    public int listen (int sfd, int backlog);

    [CCode (cheader_filename = "syslog.h")]
    public void syslog (int priority, string format, ... );

    [CCode (cheader_filename = "syslog.h")]
    public void closelog ();

    [CCode (cheader_filename = "fcntl.h")]
    public int open (string path, int oflag, mode_t mode=0);

    [CCode (cheader_filename = "unistd.h")]
    public int close (int fd);

    [CCode (cheader_filename = "unistd.h")]
    public int dup2 (int fd1, int fd2);

    [CCode (cheader_filename = "unistd.h")]
    public ssize_t write (int fd, void* buf, size_t count);

    [CCode (cheader_filename = "unistd.h")]
    public int link (string from, string to);

    [CCode (cheader_filename = "sys/ioctl.h", sentinel = "")]
    public int ioctl (int fildes, int request, ...);

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
    public int shmctl(int id, int cmd, void* buf);

    [CCode (cheader_filename = "sys/ipc.h,sys/shm.h")]
    public int shmget(key_t key, size_t size, int shmflg);

    [CCode (cheader_filename = "sys/ipc.h,sys/sem.h")]
    public int semget(key_t key, int nsems, int semflg);

    [CCode (cheader_filename = "sys/types.h,sys/shm.h")]
    public void *shmat(int shmid, void *shmaddr, int shmflg);

    [CCode (cheader_filename = "sys/types.h,sys/shm.h")]
    public int shmdt(void *shmaddr);

    [CCode (cheader_filename = "sys/types.h,sys/ipc.h,sys/sem.h", cname = "struct sembuf")]
    public struct Sembuf
    {
        public ushort sem_num;
        public short sem_op;
        public short sem_flg;
    }

    [CCode (cheader_filename = "sys/types.h,sys/ipc.h,sys/sem.h")]
    public int semop(int semid, ref Sembuf sops, uint nsops);

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_CREAT;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_RMID;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_EXCL;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const int IPC_NOWAIT;

    [CCode (cheader_filename = "sys/ipc.h")]
    public const short SEM_UNDO;

    [SimpleType]
    [CCode (cname = "cc_t", cheader_filename = "termios.h")]
    [IntegerType (rank = 3, min = 0, max = 255)]
    public struct cc_t {
    }

    [SimpleType]
    [CCode (cname = "speed_t", cheader_filename = "termios.h")]
    [IntegerType (rank = 7)]
    public struct speed_t {
    }

    [SimpleType]
    [CCode (cname = "tcflag_t", cheader_filename = "termios.h")]
    [IntegerType (rank = 7)]
    public struct tcflag_t {
    }

    [CCode (cname="struct termios", cheader_filename = "termios.h")]
    public struct termios
    {
        public tcflag_t c_iflag;
        public tcflag_t c_oflag;
        public tcflag_t c_cflag;
        public tcflag_t c_lflag;
        public cc_t c_line;
        public cc_t c_cc[32];
        public speed_t c_ispeed;
        public speed_t c_ospeed;
    }

    [CCode (cheader_filename = "termios.h")]
    public int tcgetattr (int fd, termios termios_p);
    [CCode (cheader_filename = "termios.h")]
    public int tcsetattr (int fd, int optional_actions, termios termios_p);
    [CCode (cheader_filename = "termios.h")]
    public int tcsendbreak (int fd, int duration);
    [CCode (cheader_filename = "termios.h")]
    public int tcdrain (int fd);
    [CCode (cheader_filename = "termios.h")]
    public int tcflush (int fd, int queue_selector);
    [CCode (cheader_filename = "termios.h")]
    public int tcflow (int fd, int action);
    [CCode (cheader_filename = "termios.h")]
    public void cfmakeraw (termios termios_p);
    [CCode (cheader_filename = "termios.h")]
    public speed_t cfgetispeed (termios termios_p);
    [CCode (cheader_filename = "termios.h")]
    public speed_t cfgetospeed (termios termios_p);
    [CCode (cheader_filename = "termios.h")]
    public int cfsetispeed (termios termios_p, speed_t speed);
    [CCode (cheader_filename = "termios.h")]
    public int cfsetospeed (termios termios_p, speed_t speed);
    [CCode (cheader_filename = "termios.h")]
    public int cfsetspeed (termios termios, speed_t speed);

    //c_iflag
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IGNBRK;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t BRKINT;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IGNPAR;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t PARMRK;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t INPCK;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ISTRIP;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t INLCR;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IGNCR;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IXON;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IXANY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IXOFF;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ICRNL;

    //c_oflag
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t OPOST;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ONLCR;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t OCRNL;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ONOCR;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ONLRET;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t OFILL;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t NLDLY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t NL0;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t NL1;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CRDLY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CR0;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CR1;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CR2;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CR3;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t TABDLY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t TAB0;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t TAB1;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t TAB2;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t TAB3;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t BSDLY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t BS0;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t BS1;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t VTDLY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t VT0;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t VT1;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t FFDLY;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t FF0;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t FF1;

    //c_cflag
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CSIZE;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CS5;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CS6;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CS7;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CS8;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CSTOPB;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CREAD;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t PARENB;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t PARODD;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t HUPCL;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t CLOCAL;

    //c_lflag
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ISIG;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ICANON;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ECHO;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ECHOE;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ECHOK;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t ECHONL;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t NOFLSH;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t TOSTOP;
    [CCode (cheader_filename = "termios.h")]
    public const tcflag_t IEXTEN;

    //c_cc indexes
    [CCode (cheader_filename = "termios.h")]
    public const int VINTR;
    [CCode (cheader_filename = "termios.h")]
    public const int VQUIT;
    [CCode (cheader_filename = "termios.h")]
    public const int VERASE;
    [CCode (cheader_filename = "termios.h")]
    public const int VKILL;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOF;
    [CCode (cheader_filename = "termios.h")]
    public const int VMIN;
    [CCode (cheader_filename = "termios.h")]
    public const int VEOL;
    [CCode (cheader_filename = "termios.h")]
    public const int VTIME;
    [CCode (cheader_filename = "termios.h")]
    public const int VSTART;
    [CCode (cheader_filename = "termios.h")]
    public const int VSTOP;
    [CCode (cheader_filename = "termios.h")]
    public const int VSUSP;

    //optional_actions
    [CCode (cheader_filename = "termios.h")]
    public const int TCSANOW;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSADRAIN;
    [CCode (cheader_filename = "termios.h")]
    public const int TCSAFLUSH;

    //queue_selector
    [CCode (cheader_filename = "termios.h")]
    public const int TCIFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOFLUSH;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIOFLUSH;

    //action
    [CCode (cheader_filename = "termios.h")]
    public const int TCOOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int TCOON;
    [CCode (cheader_filename = "termios.h")]
    public const int TCIOFF;
    [CCode (cheader_filename = "termios.h")]
    public const int TCION;

    //speed
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B0;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B50;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B75;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B110;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B134;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B150;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B200;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B300;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B600;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B1200;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B1800;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B2400;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B4800;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B9600;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B19200;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B38400;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B57600;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B115200;
    [CCode (cheader_filename = "termios.h")]
    public const speed_t B230400;

    [CCode (cheader_filename = "stdlib.h")]
    public void exit (int status);

    [Compact]
    [CCode (cname = "struct passwd", cheader_filename = "pwd.h")]
    public class Passwd {
        public string pw_name;
        public string pw_passwd;
        public uid_t pw_uid;
        public gid_t pw_gid;
        public string pw_gecos;
        public string pw_dir;
        public string pw_shell;
    }

    [CCode (cheader_filename = "pwd.h")]
    public void endpwent ();
    public unowned Passwd? getpwent ();
    public void setpwent ();
    [CCode (cheader_filename = "pwd.h")]
    public unowned Passwd? getpwnam (string name);
    [CCode (cheader_filename = "pwd.h")]
    public unowned Passwd? getpwuid (uid_t uid);


    [CCode (cheader_filename = "unistd.h")]
    public int chown (string filename, uid_t owner, gid_t group);

    [CCode (cheader_filename = "signal.h")]
    public const int SIGABRT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGALRM;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGBUS;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGCHLD;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGCONT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGFPE;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGHUP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGILL;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGINT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGKILL;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPIPE;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGQUIT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSEGV;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSTOP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTERM;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTSTP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTTIN;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTTOU;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGUSR1;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGUSR2;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPOLL;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGPROF;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSYS;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGTRAP;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGURG;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGVTALRM;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGXCPU;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGXFSZ;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGIOT;
    [CCode (cheader_filename = "signal.h")]
    public const int SIGSTKFLT;

    [CCode (has_target = false, cheader_filename = "signal.h")]
    public delegate void sighandler_t (int signal);

    [CCode (cheader_filename = "signal.h")]
    public sighandler_t SIG_DFL;

    [CCode (cheader_filename = "signal.h")]
    public sighandler_t SIG_ERR;

    [CCode (cheader_filename = "signal.h")]
    public sighandler_t SIG_IGN;

    [CCode (cheader_filename = "signal.h")]
    public sighandler_t signal (int signum, sighandler_t? handler);

    [CCode (cheader_filename = "signal.h")]
    public int kill (pid_t pid, int signum);

    [CCode (cheader_filename = "unistd.h,sys/types.h")]
    public int setgid (gid_t gid);
    [CCode (cheader_filename = "unistd.h,sys/types.h")]
    public int setuid (uid_t uid);
    [CCode (cheader_filename = "unistd.h")]
    public pid_t getpid ();
    [CCode (cheader_filename = "unistd.h")]
    public pid_t getppid ();
    [CCode (cheader_filename = "unistd.h")]
    public pid_t getpgid (pid_t pid);
    [CCode (cheader_filename = "unistd.h")]
    public pid_t setsid ();
    [CCode (cheader_filename = "unistd.h")]
    public int setpgid (pid_t pid, pid_t pgid);

    [CCode (cheader_filename = "fcntl.h")]
    public const int O_NOCTTY;

    [CCode (cheader_filename = "unistd.h")]
    public pid_t fork ();
    [CCode (cheader_filename = "unistd.h")]
    public int nice (int inc);
    [CCode (cheader_filename = "sys/wait.h")]
    public pid_t wait (out int status);

    [CCode (cprefix = "RB_", has_type_id = false, cheader_filename = "unistd.h,sys/reboot.h")]
    public enum RebootCommands {
         AUTOBOOT,
         HALT_SYSTEM,
         ENABLE_CAD,
         DISABLE_CAD,
         POWER_OFF
    }

    [CCode (cheader_filename = "unistd.h,sys/reboot.h")]
    public int reboot (RebootCommands cmd);
}
