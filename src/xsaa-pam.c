/* xsaa-pam.vala
 *
 * Copyright (C) 2009  Nicolas Bruguier
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

#include <glib.h>
#include <glib-object.h>
#include <security/pam_appl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gee.h>
#include <security/pam_modules.h>
#include <X11/Xauth.h>
#include <pwd.h>
#include <unistd.h>
#include <sys/types.h>
#include <grp.h>


#define XSAA_TYPE_PAM_SESSION (xsaa_pam_session_get_type ())
#define XSAA_PAM_SESSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_PAM_SESSION, XSAAPamSession))
#define XSAA_PAM_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_PAM_SESSION, XSAAPamSessionClass))
#define XSAA_IS_PAM_SESSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_PAM_SESSION))
#define XSAA_IS_PAM_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_PAM_SESSION))
#define XSAA_PAM_SESSION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_PAM_SESSION, XSAAPamSessionClass))

typedef struct _XSAAPamSession XSAAPamSession;
typedef struct _XSAAPamSessionClass XSAAPamSessionClass;
typedef struct _XSAAPamSessionPrivate XSAAPamSessionPrivate;

typedef enum  {
	XSAA_PAM_ERROR_START,
	XSAA_PAM_ERROR_AUTHENTICATE,
	XSAA_PAM_ERROR_AUTHORIZE,
	XSAA_PAM_ERROR_CREDENTIALS,
	XSAA_PAM_ERROR_OPEN_SESSION
} XSAAPamError;
#define XSAA_PAM_ERROR xsaa_pam_error_quark ()
struct _XSAAPamSession {
	GObject parent_instance;
	XSAAPamSessionPrivate * priv;
	GeeMap* envs;
};

struct _XSAAPamSessionClass {
	GObjectClass parent_class;
};

struct _XSAAPamSessionPrivate {
	char* user;
	gboolean accredited;
	gboolean openned;
	pam_handle_t* pam_handle;
	struct pam_conv* conv;
};



GQuark xsaa_pam_error_quark (void);
GType xsaa_pam_session_get_type (void);
gint xsaa_on_pam_conversation (gint num_msg, struct pam_message** messages, struct pam_response** resp, void* appdata_ptr);
#define XSAA_PAM_SESSION_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_PAM_SESSION, XSAAPamSessionPrivate))
enum  {
	XSAA_PAM_SESSION_DUMMY_PROPERTY
};
XSAAPamSession* xsaa_pam_session_new (const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error);
XSAAPamSession* xsaa_pam_session_construct (GType object_type, const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error);
XSAAPamSession* xsaa_pam_session_new (const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error);
void xsaa_pam_session_open_session (XSAAPamSession* self, GError** error);
void xsaa_pam_session_set_env (XSAAPamSession* self);
static gpointer xsaa_pam_session_parent_class = NULL;
static void xsaa_pam_session_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);
static gint _vala_array_length (gpointer array);


static void g_cclosure_user_marshal_STRING__VOID (GClosure * closure, GValue * return_value, guint n_param_values, const GValue * param_values, gpointer invocation_hint, gpointer marshal_data);

GQuark xsaa_pam_error_quark (void) {
	return g_quark_from_static_string ("xsaa_pam_error-quark");
}


gint xsaa_on_pam_conversation (gint num_msg, struct pam_message** messages, struct pam_response** resp, void* appdata_ptr) {
	XSAAPamSession* pam;
	pam = XSAA_PAM_SESSION (appdata_ptr);
	(*resp) = (struct pam_response*) g_malloc (sizeof (struct pam_response) * num_msg);
	{
		gint i;
		i = 0;
		for (; i < num_msg; i++) {
			struct pam_message* msg;
			msg = messages[i];
			switch (msg->msg_style) {
				case PAM_PROMPT_ECHO_ON:
				{
					fprintf (stderr, "Echo on message : %s\n", msg->msg);
					break;
				}
				case PAM_PROMPT_ECHO_OFF:
				{
					char* _tmp0_;
					char* passwd;
					fprintf (stderr, "Echo off message : %s\n", msg->msg);
					_tmp0_ = NULL;
					passwd = (g_signal_emit_by_name (pam, "passwd", &_tmp0_), _tmp0_);
					fprintf (stderr, "Passwd : %s\n", passwd);
					(*resp)[i].resp = g_memdup (passwd, (guint) g_utf8_strlen (passwd, -1));
					(*resp)[i].resp_retcode = PAM_SUCCESS;
					passwd = (g_free (passwd), NULL);
					break;
				}
				case PAM_TEXT_INFO:
				{
					fprintf (stderr, "Text info message : %s", msg->msg);
					g_signal_emit_by_name (pam, "info", msg->msg);
					break;
				}
				case PAM_ERROR_MSG:
				{
					fprintf (stderr, "Error message : %s", msg->msg);
					g_signal_emit_by_name (pam, "error-msg", msg->msg);
					break;
				}
				default:
				{
					fprintf (stderr, "unkown message");
					break;
				}
			}
		}
	}
	return PAM_SUCCESS;
}


XSAAPamSession* xsaa_pam_session_construct (GType object_type, const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error) {
	GError * _inner_error_;
	XSAAPamSession * self;
	char* _tmp1_;
	const char* _tmp0_;
	struct pam_conv* _tmp2_;
	pam_handle_t* _tmp5_;
	gint _tmp4_;
	pam_handle_t* _tmp3_;
	char* _tmp7_;
	char* _tmp6_;
	gboolean _tmp8_;
	FILE* f;
	Xauth* auth;
	struct passwd* passwd;
	GeeMap* _tmp13_;
	g_return_val_if_fail (service != NULL, NULL);
	g_return_val_if_fail (username != NULL, NULL);
	g_return_val_if_fail (xauth_file != NULL, NULL);
	g_return_val_if_fail (device != NULL, NULL);
	_inner_error_ = NULL;
	self = g_object_newv (object_type, 0, NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->user = (_tmp1_ = (_tmp0_ = username, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_)), self->priv->user = (g_free (self->priv->user), NULL), _tmp1_);
	_tmp2_ = NULL;
	self->priv->conv = (_tmp2_ = g_new0 (struct pam_conv, 1), (self->priv->conv == NULL) ? NULL : (self->priv->conv = (free (self->priv->conv), NULL)), _tmp2_);
	self->priv->conv->conv = (void*) xsaa_on_pam_conversation;
	self->priv->conv->appdata_ptr = self;
	_tmp5_ = NULL;
	_tmp3_ = NULL;
	if ((_tmp4_ = pam_start (service, username, self->priv->conv, &_tmp3_), self->priv->pam_handle = (_tmp5_ = _tmp3_, (self->priv->pam_handle == NULL) ? NULL : (self->priv->pam_handle = ( (self->priv->pam_handle), NULL)), _tmp5_), _tmp4_) != PAM_SUCCESS) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_START, "Error on pam start");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return NULL;
			}
		}
	}
	if (pam_set_item (self->priv->pam_handle, PAM_TTY, device) != PAM_SUCCESS) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_START, "Error on set tty");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return NULL;
			}
		}
	}
	if (pam_set_item (self->priv->pam_handle, PAM_RHOST, "localhost") != PAM_SUCCESS) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_START, "Error on set rhost");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return NULL;
			}
		}
	}
	_tmp7_ = NULL;
	_tmp6_ = NULL;
	if ((_tmp8_ = pam_set_item (self->priv->pam_handle, PAM_XDISPLAY, _tmp7_ = g_strconcat (":", _tmp6_ = g_strdup_printf ("%i", display), NULL)) != PAM_SUCCESS, _tmp7_ = (g_free (_tmp7_), NULL), _tmp6_ = (g_free (_tmp6_), NULL), _tmp8_)) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_START, "Error on set display");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return NULL;
			}
		}
	}
	f = fopen (xauth_file, "r");
	auth = XauReadAuth (f);
	if (auth != NULL) {
		struct pam_xauth_data* pam_xauth;
		char* _tmp10_;
		const char* _tmp9_;
		char* _tmp12_;
		const char* _tmp11_;
		pam_xauth = g_new0 (struct pam_xauth_data, 1);
		pam_xauth->namelen = (gint) auth->name_length;
		_tmp10_ = NULL;
		_tmp9_ = NULL;
		pam_xauth->name = (_tmp10_ = (_tmp9_ = auth->name, (_tmp9_ == NULL) ? NULL : g_strdup (_tmp9_)), pam_xauth->name = (g_free (pam_xauth->name), NULL), _tmp10_);
		pam_xauth->datalen = (gint) auth->data_length;
		_tmp12_ = NULL;
		_tmp11_ = NULL;
		pam_xauth->data = (_tmp12_ = (_tmp11_ = auth->data, (_tmp11_ == NULL) ? NULL : g_strdup (_tmp11_)), pam_xauth->data = (g_free (pam_xauth->data), NULL), _tmp12_);
		if (pam_set_item (self->priv->pam_handle, PAM_XAUTHDATA, pam_xauth) != PAM_SUCCESS) {
			g_object_unref ((GObject*) self);
			_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_START, "Error on set xauth");
			if (_inner_error_ != NULL) {
				if (_inner_error_->domain == XSAA_PAM_ERROR) {
					g_propagate_error (error, _inner_error_);
					(pam_xauth == NULL) ? NULL : (pam_xauth = (free (pam_xauth), NULL));
					(f == NULL) ? NULL : (f = (fclose (f), NULL));
					(auth == NULL) ? NULL : (auth = (XauDisposeAuth (auth), NULL));
					return;
				} else {
					(pam_xauth == NULL) ? NULL : (pam_xauth = (free (pam_xauth), NULL));
					(f == NULL) ? NULL : (f = (fclose (f), NULL));
					(auth == NULL) ? NULL : (auth = (XauDisposeAuth (auth), NULL));
					g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
					g_clear_error (&_inner_error_);
					return NULL;
				}
			}
		}
		(pam_xauth == NULL) ? NULL : (pam_xauth = (free (pam_xauth), NULL));
	}
	passwd = getpwnam (self->priv->user);
	_tmp13_ = NULL;
	self->envs = (_tmp13_ = (GeeMap*) gee_hash_map_new (G_TYPE_STRING, (GBoxedCopyFunc) g_strdup, g_free, G_TYPE_STRING, (GBoxedCopyFunc) g_strdup, g_free, g_str_hash, g_str_equal, g_direct_equal), (self->envs == NULL) ? NULL : (self->envs = (gee_collection_object_unref (self->envs), NULL)), _tmp13_);
	gee_map_set (self->envs, "USER", passwd->pw_name);
	gee_map_set (self->envs, "USERNAME", passwd->pw_name);
	gee_map_set (self->envs, "LOGNAME", passwd->pw_name);
	gee_map_set (self->envs, "HOME", passwd->pw_dir);
	gee_map_set (self->envs, "SHELL", passwd->pw_shell);
	(f == NULL) ? NULL : (f = (fclose (f), NULL));
	(auth == NULL) ? NULL : (auth = (XauDisposeAuth (auth), NULL));
	return self;
}


XSAAPamSession* xsaa_pam_session_new (const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error) {
	return xsaa_pam_session_construct (XSAA_TYPE_PAM_SESSION, service, username, display, xauth_file, device, error);
}


void xsaa_pam_session_open_session (XSAAPamSession* self, GError** error) {
	GError * _inner_error_;
	struct passwd* passwd;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	if (pam_authenticate (self->priv->pam_handle, 0) != PAM_SUCCESS) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_AUTHENTICATE, "Error on authenticate");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	passwd = getpwnam (self->priv->user);
	if (passwd == NULL) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_AUTHORIZE, "User is not authorized to log in");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	if (pam_acct_mgmt (self->priv->pam_handle, 0) != PAM_SUCCESS) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_AUTHORIZE, "User is not authorized to log in");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	if (pam_open_session (self->priv->pam_handle, 0) != PAM_SUCCESS) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_OPEN_SESSION, "Error on pam open session");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	self->priv->openned = TRUE;
	if (pam_setcred (self->priv->pam_handle, PAM_ESTABLISH_CRED) != PAM_SUCCESS) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_CREDENTIALS, "User is not authorized to log in");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	self->priv->accredited = TRUE;
	if (setgid (passwd->pw_gid) < 0) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_CREDENTIALS, "User is not authorized to log in");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	if (initgroups (self->priv->user, passwd->pw_gid) < 0) {
		_inner_error_ = g_error_new_literal (XSAA_PAM_ERROR, XSAA_PAM_ERROR_CREDENTIALS, "User is not authorized to log in");
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	setenv ("USER", passwd->pw_name, 1);
	setenv ("USERNAME", passwd->pw_name, 1);
	setenv ("LOGNAME", passwd->pw_name, 1);
	setenv ("HOME", passwd->pw_dir, 1);
	setenv ("SHELL", passwd->pw_shell, 1);
	{
		char** _tmp0_;
		char** env_collection;
		int env_collection_length1;
		int env_it;
		_tmp0_ = NULL;
		env_collection = _tmp0_ = pam_getenvlist (self->priv->pam_handle);
		env_collection_length1 = _vala_array_length (_tmp0_);
		for (env_it = 0; env_it < _vala_array_length (_tmp0_); env_it = env_it + 1) {
			const char* _tmp3_;
			char* env;
			_tmp3_ = NULL;
			env = (_tmp3_ = env_collection[env_it], (_tmp3_ == NULL) ? NULL : g_strdup (_tmp3_));
			{
				char** _tmp2_;
				gint e_size;
				gint e_length1;
				char** _tmp1_;
				char** e;
				_tmp2_ = NULL;
				_tmp1_ = NULL;
				e = (_tmp2_ = _tmp1_ = g_strsplit (env, "=", 0), e_length1 = _vala_array_length (_tmp1_), e_size = e_length1, _tmp2_);
				gee_map_set (self->envs, e[0], e[1]);
				fprintf (stderr, "Pam env %s=%s\n", e[0], e[1]);
				env = (g_free (env), NULL);
				e = (_vala_array_free (e, e_length1, (GDestroyNotify) g_free), NULL);
			}
		}
		env_collection = (_vala_array_free (env_collection, env_collection_length1, (GDestroyNotify) g_free), NULL);
	}
}


void xsaa_pam_session_set_env (XSAAPamSession* self) {
	g_return_if_fail (self != NULL);
	{
		GeeSet* _tmp0_;
		GeeIterator* _tmp1_;
		GeeIterator* _key_it;
		_tmp0_ = NULL;
		_tmp1_ = NULL;
		_key_it = (_tmp1_ = gee_iterable_iterator ((GeeIterable*) (_tmp0_ = gee_map_get_keys (self->envs))), (_tmp0_ == NULL) ? NULL : (_tmp0_ = (gee_collection_object_unref (_tmp0_), NULL)), _tmp1_);
		while (gee_iterator_next (_key_it)) {
			char* key;
			char* _tmp2_;
			char* _tmp3_;
			key = (char*) gee_iterator_get (_key_it);
			_tmp2_ = NULL;
			setenv (key, _tmp2_ = (char*) gee_map_get (self->envs, key), 1);
			_tmp2_ = (g_free (_tmp2_), NULL);
			_tmp3_ = NULL;
			fprintf (stderr, "Pam env %s=%s\n", key, _tmp3_ = (char*) gee_map_get (self->envs, key));
			_tmp3_ = (g_free (_tmp3_), NULL);
			key = (g_free (key), NULL);
		}
		(_key_it == NULL) ? NULL : (_key_it = (gee_collection_object_unref (_key_it), NULL));
	}
}


static void xsaa_pam_session_class_init (XSAAPamSessionClass * klass) {
	xsaa_pam_session_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAAPamSessionPrivate));
	G_OBJECT_CLASS (klass)->finalize = xsaa_pam_session_finalize;
	g_signal_new ("passwd", XSAA_TYPE_PAM_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_user_marshal_STRING__VOID, G_TYPE_STRING, 0);
	g_signal_new ("info", XSAA_TYPE_PAM_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__STRING, G_TYPE_NONE, 1, G_TYPE_STRING);
	g_signal_new ("error_msg", XSAA_TYPE_PAM_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__STRING, G_TYPE_NONE, 1, G_TYPE_STRING);
}


static void xsaa_pam_session_instance_init (XSAAPamSession * self) {
	self->priv = XSAA_PAM_SESSION_GET_PRIVATE (self);
	self->priv->accredited = FALSE;
	self->priv->openned = FALSE;
	self->priv->pam_handle = NULL;
}


static void xsaa_pam_session_finalize (GObject* obj) {
	XSAAPamSession * self;
	self = XSAA_PAM_SESSION (obj);
	{
		if (self->priv->openned) {
			pam_open_session (self->priv->pam_handle, 0);
		}
		if (self->priv->accredited) {
			pam_setcred (self->priv->pam_handle, PAM_DELETE_CRED);
		}
		pam_end (self->priv->pam_handle, PAM_SUCCESS);
		fprintf (stderr, "Close pam session\n");
	}
	self->priv->user = (g_free (self->priv->user), NULL);
	(self->priv->pam_handle == NULL) ? NULL : (self->priv->pam_handle = ( (self->priv->pam_handle), NULL));
	(self->priv->conv == NULL) ? NULL : (self->priv->conv = (free (self->priv->conv), NULL));
	(self->envs == NULL) ? NULL : (self->envs = (gee_collection_object_unref (self->envs), NULL));
	G_OBJECT_CLASS (xsaa_pam_session_parent_class)->finalize (obj);
}


GType xsaa_pam_session_get_type (void) {
	static GType xsaa_pam_session_type_id = 0;
	if (xsaa_pam_session_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAAPamSessionClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_pam_session_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAAPamSession), 0, (GInstanceInitFunc) xsaa_pam_session_instance_init, NULL };
		xsaa_pam_session_type_id = g_type_register_static (G_TYPE_OBJECT, "XSAAPamSession", &g_define_type_info, 0);
	}
	return xsaa_pam_session_type_id;
}


static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func) {
	if ((array != NULL) && (destroy_func != NULL)) {
		int i;
		for (i = 0; i < array_length; i = i + 1) {
			if (((gpointer*) array)[i] != NULL) {
				destroy_func (((gpointer*) array)[i]);
			}
		}
	}
}


static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func) {
	_vala_array_destroy (array, array_length, destroy_func);
	g_free (array);
}


static gint _vala_array_length (gpointer array) {
	int length;
	length = 0;
	if (array) {
		while (((gpointer*) array)[length]) {
			length++;
		}
	}
	return length;
}



static void g_cclosure_user_marshal_STRING__VOID (GClosure * closure, GValue * return_value, guint n_param_values, const GValue * param_values, gpointer invocation_hint, gpointer marshal_data) {
	typedef const char* (*GMarshalFunc_STRING__VOID) (gpointer data1, gpointer data2);
	register GMarshalFunc_STRING__VOID callback;
	register GCClosure * cc;
	register gpointer data1, data2;
	const char* v_return;
	cc = (GCClosure *) closure;
	g_return_if_fail (return_value != NULL);
	g_return_if_fail (n_param_values == 1);
	if (G_CCLOSURE_SWAP_DATA (closure)) {
		data1 = closure->data;
		data2 = param_values->data[0].v_pointer;
	} else {
		data1 = param_values->data[0].v_pointer;
		data2 = closure->data;
	}
	callback = (GMarshalFunc_STRING__VOID) (marshal_data ? marshal_data : cc->callback);
	v_return = callback (data1, data2);
	g_value_take_string (return_value, v_return);
}



