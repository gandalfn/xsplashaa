/* pam-face-authentification.vala
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
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

#define PAM_SM_AUTH
#define PAM_SM_ACCOUNT
#define PAM_SM_SESSION
#define PAM_SM_PASSWORD

#include <security/pam_modules.h>

int xsaa_sm_authenticate (pam_handle_t* inHandle, int inFlags, char** inArgs, int inArgs_length1);
int xsaa_sm_setcred (pam_handle_t* inHandle, int inFlags, char** inArgs, int inArgs_length1);
int xsaa_sm_acct_mgmt (pam_handle_t* inHandle, int inFlags, char** inArgs, int inArgs_length1);
int xsaa_sm_chauthtok (pam_handle_t* inHandle, int inFlags, char** inArgs, int inArgs_length1);
int xsaa_sm_open_session (pam_handle_t* inHandle, int inFlags, char** inArgs, int inArgs_length1);
int xsaa_sm_close_session (pam_handle_t* inHandle, int inFlags, char** inArgs, int inArgs_length1);

PAM_EXTERN int
pam_sm_authenticate (pam_handle_t* handle, int flags, int argc, const char** argv)
{
    return xsaa_sm_authenticate (handle, flags, (char**)argv, argc);
}

PAM_EXTERN int
pam_sm_setcred (pam_handle_t* handle, int flags, int argc, const char** argv)
{
    return xsaa_sm_setcred (handle, flags, (char**)argv, argc);
}


PAM_EXTERN int
pam_sm_acct_mgmt (pam_handle_t* handle, int flags, int argc, const char** argv)
{
    return xsaa_sm_acct_mgmt (handle, flags, (char**)argv, argc);
}


PAM_EXTERN int
pam_sm_chauthtok (pam_handle_t* handle, int flags, int argc, const char** argv)
{
    return xsaa_sm_chauthtok (handle, flags, (char**)argv, argc);
}


PAM_EXTERN int
pam_sm_open_session (pam_handle_t* handle, int flags, int argc, const char** argv)
{
    return xsaa_sm_open_session (handle, flags, (char**)argv, argc);
}


PAM_EXTERN int
pam_sm_close_session (pam_handle_t* handle, int flags, int argc, const char** argv)
{
    return xsaa_sm_close_session (handle, flags, (char**)argv, argc);
}

