[CCode (cheader_filename = "security/pam_appl.h", cprefix = "PAM_", lower_case_cprefix = "pam_")]
namespace Pam
{
    [Compact]
    [CCode (cname = "pam_handle_t", free_function="")]
    public class Handle {
        [CCode (cname = "pam_set_item", cheader_filename = "security/pam_modules.h", sentinel = "")]
        public int set_item(int type_item, ...);
        [CCode (cname = "pam_authenticate")]
        public int authenticate(int flags);
        [CCode (cname = "pam_acct_mgmt")]
        public int acct_mgmt(int flags);
        [CCode (cname = "pam_setcred")]
        public int setcred(int flags);
        [CCode (cname = "pam_open_session")]
        public int open_session(int flags);
        [CCode (cname = "pam_open_session")]
        public int close_session(int flags);
        [CCode (cname = "pam_getenvlist", array_length = false, array_null_terminated = true)]
        [NoArrayLength]
        public string[] getenvlist();
        [CCode (cname = "pam_end")]
        public int end(int status);

    }

    public int start(string service, string username, Conv conv, out Handle handle);
    [Compact]
    [CCode (cname = "struct pam_xauth_data", free_function="free")]
    class XauthData {
        public int namelen;
        public string name;
        public int datalen;
        public string data;
    }
    
    [Compact]
    [CCode (cname = "struct pam_message", free_function="free")]
    public class Message  {
        public int msg_style;
        public string msg;
    }

    [SimpleType]
    [CCode (cname = "struct pam_response", free_function="free")]
    public struct Response  {
        public void* resp;
        public int resp_retcode;
    }

    [Compact]
    [CCode (cname="struct pam_conv", free_function="free")]
    public class Conv {
        public void* conv;
        public void* appdata_ptr;
    }

    public const int SUCCESS;
    public const int OPEN_ERR;
    public const int SYMBOL_ERR;
    public const int SERVICE_ERR;
    public const int SYSTEM_ERR;
    public const int BUF_ERR;
    public const int PERM_DENIED;
    public const int AUTH_ERR;
    public const int CRED_INSUFFICIENT;
    public const int AUTHINFO_UNAVAIL;
    public const int USER_UNKNOWN;
    public const int MAXTRIES;
    public const int NEW_AUTHTOK_REQD;
    public const int ACCT_EXPIRED;
    public const int SESSION_ERR;
    public const int CRED_UNAVAIL;
    public const int CRED_EXPIRED;
    public const int CRED_ERR;
    public const int NO_MODULE_DATA;
    public const int CONV_ERR;
    public const int AUTHTOK_ERR;
    public const int AUTHTOK_RECOVERY_ERR;
    public const int AUTHTOK_LOCK_BUSY;
    public const int AUTHTOK_DISABLE_AGING;
    public const int TRY_AGAIN;
    public const int IGNORE;
    public const int ABORT;
    public const int AUTHTOK_EXPIRED;
    public const int MODULE_UNKNOWN;
    public const int BAD_ITEM;
    public const int CONV_AGAIN;
    public const int INCOMPLETE;

    public const int SERVICE;
    public const int USER;
    public const int TTY;
    public const int RHOST;
    public const int CONV;
    public const int AUTHTOK;
    public const int OLDAUTHTOK;
    public const int RUSER;
    public const int USER_PROMPT;
    public const int FAIL_DELAY;
    public const int XDISPLAY;
    public const int XAUTHDATA;

    public const int ESTABLISH_CRED;
    public const int DELETE_CRED;

    public const int PROMPT_ECHO_ON;
    public const int PROMPT_ECHO_OFF;
    public const int TEXT_INFO;
    public const int ERROR_MSG;
}
