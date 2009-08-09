/* xsaa-session.vala
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
#include <stdlib.h>
#include <string.h>
#include <dbus/dbus-glib-lowlevel.h>
#include <dbus/dbus-glib.h>
#include <pwd.h>
#include <glib/gstdio.h>
#include <stdio.h>
#include <X11/Xauth.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <signal.h>
#include <dbus/dbus.h>


#define CONSOLE_KIT_TYPE_SESSION_PARAMETER (console_kit_session_parameter_get_type ())
typedef struct _ConsoleKitSessionParameter ConsoleKitSessionParameter;

#define XSAA_TYPE_SESSION (xsaa_session_get_type ())
#define XSAA_SESSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SESSION, XSAASession))
#define XSAA_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SESSION, XSAASessionClass))
#define XSAA_IS_SESSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SESSION))
#define XSAA_IS_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SESSION))
#define XSAA_SESSION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SESSION, XSAASessionClass))

typedef struct _XSAASession XSAASession;
typedef struct _XSAASessionClass XSAASessionClass;
typedef struct _XSAASessionPrivate XSAASessionPrivate;

#define CONSOLE_KIT_TYPE_MANAGER (console_kit_manager_get_type ())
#define CONSOLE_KIT_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), CONSOLE_KIT_TYPE_MANAGER, ConsoleKitManager))
#define CONSOLE_KIT_IS_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CONSOLE_KIT_TYPE_MANAGER))
#define CONSOLE_KIT_MANAGER_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), CONSOLE_KIT_TYPE_MANAGER, ConsoleKitManagerIface))

typedef struct _ConsoleKitManager ConsoleKitManager;
typedef struct _ConsoleKitManagerIface ConsoleKitManagerIface;

#define XSAA_TYPE_PAM_SESSION (xsaa_pam_session_get_type ())
#define XSAA_PAM_SESSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_PAM_SESSION, XSAAPamSession))
#define XSAA_PAM_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_PAM_SESSION, XSAAPamSessionClass))
#define XSAA_IS_PAM_SESSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_PAM_SESSION))
#define XSAA_IS_PAM_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_PAM_SESSION))
#define XSAA_PAM_SESSION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_PAM_SESSION, XSAAPamSessionClass))

typedef struct _XSAAPamSession XSAAPamSession;
typedef struct _XSAAPamSessionClass XSAAPamSessionClass;
typedef struct _DBusObjectVTable _DBusObjectVTable;

struct _ConsoleKitSessionParameter {
	char* key;
	GValue* value;
};

typedef enum  {
	XSAA_SESSION_ERROR_COMMAND,
	XSAA_SESSION_ERROR_LAUNCH,
	XSAA_SESSION_ERROR_USER,
	XSAA_SESSION_ERROR_XAUTH
} XSAASessionError;
#define XSAA_SESSION_ERROR xsaa_session_error_quark ()
struct _XSAASession {
	GObject parent_instance;
	XSAASessionPrivate * priv;
};

struct _XSAASessionClass {
	GObjectClass parent_class;
};

struct _ConsoleKitManagerIface {
	GTypeInterface parent_iface;
	char* (*open_session_with_parameters) (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1);
	gint (*close_session) (ConsoleKitManager* self, const char* cookie);
	char* (*get_session_for_cookie) (ConsoleKitManager* self, const char* cookie);
	void (*restart) (ConsoleKitManager* self);
	void (*stop) (ConsoleKitManager* self);
};

struct _XSAASessionPrivate {
	ConsoleKitManager* ck_manager;
	char* cookie;
	char* display_num;
	char* device_num;
	GPid pid;
	struct passwd* passwd;
	char* pass;
	XSAAPamSession* pam;
	char* xauth_file;
};

typedef enum  {
	XSAA_PAM_ERROR_START,
	XSAA_PAM_ERROR_AUTHENTICATE,
	XSAA_PAM_ERROR_AUTHORIZE,
	XSAA_PAM_ERROR_CREDENTIALS,
	XSAA_PAM_ERROR_OPEN_SESSION
} XSAAPamError;
#define XSAA_PAM_ERROR xsaa_pam_error_quark ()
struct _DBusObjectVTable {
	void (*register_object) (DBusConnection*, const char*, void*);
};


static gpointer xsaa_session_parent_class = NULL;

GType console_kit_session_parameter_get_type (void);
ConsoleKitSessionParameter* console_kit_session_parameter_dup (const ConsoleKitSessionParameter* self);
void console_kit_session_parameter_free (ConsoleKitSessionParameter* self);
void console_kit_session_parameter_copy (const ConsoleKitSessionParameter* self, ConsoleKitSessionParameter* dest);
void console_kit_session_parameter_destroy (ConsoleKitSessionParameter* self);
static GValue* _g_value_dup (GValue* self);
void console_kit_session_parameter_init (ConsoleKitSessionParameter *self, const char* a, const GValue* b);
GQuark xsaa_session_error_quark (void);
GType xsaa_session_get_type (void);
GType console_kit_manager_get_type (void);
GType xsaa_pam_session_get_type (void);
#define XSAA_SESSION_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_SESSION, XSAASessionPrivate))
enum  {
	XSAA_SESSION_DUMMY_PROPERTY
};
static void xsaa_session_generate_xauth (XSAASession* self, const char* user, gint display, GError** error);
GQuark xsaa_pam_error_quark (void);
XSAAPamSession* xsaa_pam_session_new (const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error);
XSAAPamSession* xsaa_pam_session_construct (GType object_type, const char* service, const char* username, gint display, const char* xauth_file, const char* device, GError** error);
static char* xsaa_session_on_ask_passwd (XSAASession* self);
static char* _xsaa_session_on_ask_passwd_xsaa_pam_session_passwd (XSAAPamSession* _sender, gpointer self);
static void xsaa_session_on_info (XSAASession* self, const char* text);
static void _xsaa_session_on_info_xsaa_pam_session_info (XSAAPamSession* _sender, const char* text, gpointer self);
static void xsaa_session_on_error_msg (XSAASession* self, const char* text);
static void _xsaa_session_on_error_msg_xsaa_pam_session_error_msg (XSAAPamSession* _sender, const char* text, gpointer self);
XSAASession* xsaa_session_new (DBusGConnection* conn, ConsoleKitManager* manager, const char* service, const char* user, gint display, const char* device, GError** error);
XSAASession* xsaa_session_construct (GType object_type, DBusGConnection* conn, ConsoleKitManager* manager, const char* service, const char* user, gint display, const char* device, GError** error);
#define PACKAGE_XAUTH_DIR "/tmp/xsplashaa-xauth"
char* console_kit_manager_open_session_with_parameters (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1);
static void _vala_ConsoleKitSessionParameter_array_free (ConsoleKitSessionParameter* array, gint array_length);
static void xsaa_session_register (XSAASession* self);
void xsaa_pam_session_open_session (XSAAPamSession* self, GError** error);
void xsaa_pam_session_set_env (XSAAPamSession* self);
static void xsaa_session_on_child_setup (XSAASession* self);
static void xsaa_session_on_child_watch (XSAASession* self, GPid pid, gint status);
void xsaa_session_set_passwd (XSAASession* self, const char* pass);
void xsaa_session_authenticate (XSAASession* self);
static void _xsaa_session_on_child_setup_gspawn_child_setup_func (gpointer self);
static void _xsaa_session_on_child_watch_gchild_watch_func (GPid pid, gint status, gpointer self);
void xsaa_session_launch (XSAASession* self, const char* cmd, GError** error);
gint console_kit_manager_close_session (ConsoleKitManager* self, const char* cookie);
void xsaa_session_dbus_register_object (DBusConnection* connection, const char* path, void* object);
void _xsaa_session_dbus_unregister (DBusConnection* connection, void* user_data);
DBusHandlerResult xsaa_session_dbus_message (DBusConnection* connection, DBusMessage* message, void* object);
static DBusMessage* _dbus_xsaa_session_introspect (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_property_get_all (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_set_passwd (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_authenticate (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_launch (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static void _dbus_xsaa_session_died (GObject* _sender, DBusConnection* _connection);
static void _dbus_xsaa_session_exited (GObject* _sender, DBusConnection* _connection);
static void _dbus_xsaa_session_authenticated (GObject* _sender, DBusConnection* _connection);
static void _dbus_xsaa_session_info (GObject* _sender, const char* msg, DBusConnection* _connection);
static void _dbus_xsaa_session_error_msg (GObject* _sender, const char* msg, DBusConnection* _connection);
static void xsaa_session_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_dbus_register_object (DBusConnection* connection, const char* path, void* object);
static void _vala_dbus_unregister_object (gpointer connection, GObject* object);

static const DBusObjectPathVTable _xsaa_session_dbus_path_vtable = {_xsaa_session_dbus_unregister, xsaa_session_dbus_message};
static const _DBusObjectVTable _xsaa_session_dbus_vtable = {xsaa_session_dbus_register_object};


static GValue* _g_value_dup (GValue* self) {
	return g_boxed_copy (G_TYPE_VALUE, self);
}


void console_kit_session_parameter_init (ConsoleKitSessionParameter *self, const char* a, const GValue* b) {
	char* _tmp1_;
	const char* _tmp0_;
	GValue* _tmp3_;
	GValue* _tmp2_;
	g_return_if_fail (a != NULL);
	memset (self, 0, sizeof (ConsoleKitSessionParameter));
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	(*self).key = (_tmp1_ = (_tmp0_ = a, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_)), (*self).key = (g_free ((*self).key), NULL), _tmp1_);
	_tmp3_ = NULL;
	_tmp2_ = NULL;
	(*self).value = (_tmp3_ = (_tmp2_ = b, (_tmp2_ == NULL) ? NULL : _g_value_dup (_tmp2_)), ((*self).value == NULL) ? NULL : ((*self).value = (g_free ((*self).value), NULL)), _tmp3_);
}


void console_kit_session_parameter_copy (const ConsoleKitSessionParameter* self, ConsoleKitSessionParameter* dest) {
	GValue* _tmp1_;
	const char* _tmp0_;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	dest->key = (_tmp0_ = self->key, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_));
	dest->value = (_tmp1_ = self->value, (_tmp1_ == NULL) ? NULL : _g_value_dup (_tmp1_));
}


void console_kit_session_parameter_destroy (ConsoleKitSessionParameter* self) {
	self->key = (g_free (self->key), NULL);
	(self->value == NULL) ? NULL : (self->value = (g_free (self->value), NULL));
}


ConsoleKitSessionParameter* console_kit_session_parameter_dup (const ConsoleKitSessionParameter* self) {
	ConsoleKitSessionParameter* dup;
	dup = g_new0 (ConsoleKitSessionParameter, 1);
	console_kit_session_parameter_copy (self, dup);
	return dup;
}


void console_kit_session_parameter_free (ConsoleKitSessionParameter* self) {
	console_kit_session_parameter_destroy (self);
	g_free (self);
}


GType console_kit_session_parameter_get_type (void) {
	static GType console_kit_session_parameter_type_id = 0;
	if (console_kit_session_parameter_type_id == 0) {
		console_kit_session_parameter_type_id = g_boxed_type_register_static ("ConsoleKitSessionParameter", (GBoxedCopyFunc) console_kit_session_parameter_dup, (GBoxedFreeFunc) console_kit_session_parameter_free);
	}
	return console_kit_session_parameter_type_id;
}


GQuark xsaa_session_error_quark (void) {
	return g_quark_from_static_string ("xsaa_session_error-quark");
}


static char* _xsaa_session_on_ask_passwd_xsaa_pam_session_passwd (XSAAPamSession* _sender, gpointer self) {
	return xsaa_session_on_ask_passwd (self);
}


static void _xsaa_session_on_info_xsaa_pam_session_info (XSAAPamSession* _sender, const char* text, gpointer self) {
	xsaa_session_on_info (self, text);
}


static void _xsaa_session_on_error_msg_xsaa_pam_session_error_msg (XSAAPamSession* _sender, const char* text, gpointer self) {
	xsaa_session_on_error_msg (self, text);
}


XSAASession* xsaa_session_construct (GType object_type, DBusGConnection* conn, ConsoleKitManager* manager, const char* service, const char* user, gint display, const char* device, GError** error) {
	GError * _inner_error_;
	XSAASession * self;
	ConsoleKitManager* _tmp1_;
	ConsoleKitManager* _tmp0_;
	char* _tmp5_;
	char* _tmp4_;
	char* _tmp7_;
	const char* _tmp6_;
	g_return_val_if_fail (conn != NULL, NULL);
	g_return_val_if_fail (manager != NULL, NULL);
	g_return_val_if_fail (service != NULL, NULL);
	g_return_val_if_fail (user != NULL, NULL);
	g_return_val_if_fail (device != NULL, NULL);
	_inner_error_ = NULL;
	self = g_object_newv (object_type, 0, NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->ck_manager = (_tmp1_ = (_tmp0_ = manager, (_tmp0_ == NULL) ? NULL : g_object_ref (_tmp0_)), (self->priv->ck_manager == NULL) ? NULL : (self->priv->ck_manager = (g_object_unref (self->priv->ck_manager), NULL)), _tmp1_);
	self->priv->passwd = getpwnam (user);
	if (self->priv->passwd == NULL) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new (XSAA_SESSION_ERROR, XSAA_SESSION_ERROR_USER, "%s doesn't exist!", user);
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_SESSION_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return NULL;
			}
		}
	}
	xsaa_session_generate_xauth (self, user, display, &_inner_error_);
	if (_inner_error_ != NULL) {
		if (_inner_error_->domain == XSAA_SESSION_ERROR) {
			g_propagate_error (error, _inner_error_);
			return;
		} else {
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return NULL;
		}
	}
	{
		XSAAPamSession* _tmp2_;
		XSAAPamSession* _tmp3_;
		_tmp2_ = xsaa_pam_session_new (service, user, display, self->priv->xauth_file, device, &_inner_error_);
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_PAM_ERROR) {
				goto __catch0_xsaa_pam_error;
			}
			goto __finally0;
		}
		_tmp3_ = NULL;
		self->priv->pam = (_tmp3_ = _tmp2_, (self->priv->pam == NULL) ? NULL : (self->priv->pam = (g_object_unref (self->priv->pam), NULL)), _tmp3_);
		g_signal_connect_object (self->priv->pam, "passwd", (GCallback) _xsaa_session_on_ask_passwd_xsaa_pam_session_passwd, self, 0);
		g_signal_connect_object (self->priv->pam, "info", (GCallback) _xsaa_session_on_info_xsaa_pam_session_info, self, 0);
		g_signal_connect_object (self->priv->pam, "error-msg", (GCallback) _xsaa_session_on_error_msg_xsaa_pam_session_error_msg, self, 0);
	}
	goto __finally0;
	__catch0_xsaa_pam_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			g_object_unref ((GObject*) self);
			_inner_error_ = g_error_new_literal (XSAA_SESSION_ERROR, XSAA_SESSION_ERROR_USER, "Error on create pam session");
			if (_inner_error_ != NULL) {
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
				goto __finally0;
			}
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally0:
	if (_inner_error_ != NULL) {
		if (_inner_error_->domain == XSAA_SESSION_ERROR) {
			g_propagate_error (error, _inner_error_);
			return;
		} else {
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return NULL;
		}
	}
	_tmp5_ = NULL;
	_tmp4_ = NULL;
	self->priv->display_num = (_tmp5_ = g_strconcat (":", _tmp4_ = g_strdup_printf ("%i", display), NULL), self->priv->display_num = (g_free (self->priv->display_num), NULL), _tmp5_);
	_tmp4_ = (g_free (_tmp4_), NULL);
	_tmp7_ = NULL;
	_tmp6_ = NULL;
	self->priv->device_num = (_tmp7_ = (_tmp6_ = device, (_tmp6_ == NULL) ? NULL : g_strdup (_tmp6_)), self->priv->device_num = (g_free (self->priv->device_num), NULL), _tmp7_);
	return self;
}


XSAASession* xsaa_session_new (DBusGConnection* conn, ConsoleKitManager* manager, const char* service, const char* user, gint display, const char* device, GError** error) {
	return xsaa_session_construct (XSAA_TYPE_SESSION, conn, manager, service, user, display, device, error);
}


static void xsaa_session_generate_xauth (XSAASession* self, const char* user, gint display, GError** error) {
	GError * _inner_error_;
	char* _tmp3_;
	char* _tmp2_;
	char* _tmp1_;
	char* _tmp0_;
	FILE* f;
	Xauth* auth;
	char* _tmp4_;
	char* _tmp5_;
	char* _tmp6_;
	char* _tmp7_;
	char* _tmp8_;
	gchar* _tmp9_;
	gint data_size;
	gint data_length1;
	gchar* data;
	char* _tmp11_;
	g_return_if_fail (self != NULL);
	g_return_if_fail (user != NULL);
	_inner_error_ = NULL;
	if (!g_file_test (PACKAGE_XAUTH_DIR, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_DIR)) {
		g_mkdir (PACKAGE_XAUTH_DIR, 0777);
		g_chmod (PACKAGE_XAUTH_DIR, 0777);
	}
	_tmp3_ = NULL;
	_tmp2_ = NULL;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->xauth_file = (_tmp3_ = g_strconcat (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat (PACKAGE_XAUTH_DIR "/xauth-", user, NULL), "-", NULL), _tmp2_ = g_strdup_printf ("%i", display), NULL), self->priv->xauth_file = (g_free (self->priv->xauth_file), NULL), _tmp3_);
	_tmp2_ = (g_free (_tmp2_), NULL);
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	if (g_file_test (self->priv->xauth_file, G_FILE_TEST_EXISTS)) {
		g_remove (self->priv->xauth_file);
	}
	f = fopen (self->priv->xauth_file, "w");
	auth = g_new0 (Xauth, 1);
	auth->family = FamilyLocal;
	_tmp4_ = NULL;
	auth->address = (_tmp4_ = g_strdup ("localhost"), auth->address = (g_free (auth->address), NULL), _tmp4_);
	auth->address_length = (gushort) g_utf8_strlen ("localhost", -1);
	_tmp5_ = NULL;
	auth->number = (_tmp5_ = g_strdup_printf ("%i", display), auth->number = (g_free (auth->number), NULL), _tmp5_);
	_tmp6_ = NULL;
	auth->number_length = (gushort) g_utf8_strlen (_tmp6_ = g_strdup_printf ("%i", display), -1);
	_tmp6_ = (g_free (_tmp6_), NULL);
	_tmp7_ = NULL;
	auth->name = (_tmp7_ = g_strdup ("MIT-MAGIC-COOKIE-1"), auth->name = (g_free (auth->name), NULL), _tmp7_);
	auth->name_length = (gushort) g_utf8_strlen ("MIT-MAGIC-COOKIE-1", -1);
	_tmp8_ = NULL;
	auth->data = (_tmp8_ = g_strdup (""), auth->data = (g_free (auth->data), NULL), _tmp8_);
	_tmp9_ = NULL;
	data = (_tmp9_ = g_new0 (gchar, 16), data_length1 = 16, data_size = data_length1, _tmp9_);
	{
		gint i;
		i = 0;
		{
			gboolean _tmp10_;
			_tmp10_ = TRUE;
			while (TRUE) {
				if (!_tmp10_) {
					i++;
				}
				_tmp10_ = FALSE;
				if (!(i < 16)) {
					break;
				}
				data[i] = (gchar) g_random_int_range ((gint32) 0, (gint32) 256);
			}
		}
	}
	_tmp11_ = NULL;
	auth->data = (_tmp11_ = g_strnfill ((gsize) 16, ' '), auth->data = (g_free (auth->data), NULL), _tmp11_);
	memcpy (auth->data, data, (gsize) 16);
	auth->data_length = (gushort) 16;
	XauWriteAuth (f, auth);
	fflush (f);
	if (chown (self->priv->xauth_file, self->priv->passwd->pw_uid, self->priv->passwd->pw_gid) < 0) {
		char* _tmp12_;
		GError* _tmp13_;
		_tmp12_ = NULL;
		_tmp13_ = NULL;
		_inner_error_ = (_tmp13_ = g_error_new_literal (XSAA_SESSION_ERROR, XSAA_SESSION_ERROR_XAUTH, _tmp12_ = g_strconcat ("Error on generate ", self->priv->xauth_file, NULL)), _tmp12_ = (g_free (_tmp12_), NULL), _tmp13_);
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_SESSION_ERROR) {
				g_propagate_error (error, _inner_error_);
				(f == NULL) ? NULL : (f = (fclose (f), NULL));
				(auth == NULL) ? NULL : (auth = (XauDisposeAuth (auth), NULL));
				data = (g_free (data), NULL);
				return;
			} else {
				(f == NULL) ? NULL : (f = (fclose (f), NULL));
				(auth == NULL) ? NULL : (auth = (XauDisposeAuth (auth), NULL));
				data = (g_free (data), NULL);
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return;
			}
		}
	}
	(f == NULL) ? NULL : (f = (fclose (f), NULL));
	(auth == NULL) ? NULL : (auth = (XauDisposeAuth (auth), NULL));
	data = (g_free (data), NULL);
}


static void _vala_ConsoleKitSessionParameter_array_free (ConsoleKitSessionParameter* array, gint array_length) {
	if (array != NULL) {
		int i;
		for (i = 0; i < array_length; i = i + 1) {
			console_kit_session_parameter_destroy (&array[i]);
		}
	}
	g_free (array);
}


static void xsaa_session_register (XSAASession* self) {
	GValue _tmp0_ = {0};
	GValue user_val;
	ConsoleKitSessionParameter _tmp1_ = {0};
	ConsoleKitSessionParameter unixuser;
	GValue _tmp2_ = {0};
	GValue display_val;
	ConsoleKitSessionParameter _tmp3_ = {0};
	ConsoleKitSessionParameter x11display;
	GValue _tmp4_ = {0};
	GValue display_dev_val;
	ConsoleKitSessionParameter _tmp5_ = {0};
	ConsoleKitSessionParameter x11displaydev;
	GValue _tmp6_ = {0};
	GValue is_local_val;
	ConsoleKitSessionParameter _tmp7_ = {0};
	ConsoleKitSessionParameter islocal;
	ConsoleKitSessionParameter* _tmp13_;
	gint parameters_size;
	gint parameters_length1;
	ConsoleKitSessionParameter* _tmp12_;
	ConsoleKitSessionParameter _tmp11_ = {0};
	ConsoleKitSessionParameter _tmp10_ = {0};
	ConsoleKitSessionParameter _tmp9_ = {0};
	ConsoleKitSessionParameter _tmp8_ = {0};
	ConsoleKitSessionParameter* parameters;
	char* _tmp14_;
	g_return_if_fail (self != NULL);
	user_val = (g_value_init (&_tmp0_, G_TYPE_INT), _tmp0_);
	g_value_set_int (&user_val, (gint) self->priv->passwd->pw_uid);
	unixuser = (console_kit_session_parameter_init (&_tmp1_, "unix-user", &user_val), _tmp1_);
	display_val = (g_value_init (&_tmp2_, G_TYPE_STRING), _tmp2_);
	g_value_set_string (&display_val, self->priv->display_num);
	x11display = (console_kit_session_parameter_init (&_tmp3_, "x11-display", &display_val), _tmp3_);
	display_dev_val = (g_value_init (&_tmp4_, G_TYPE_STRING), _tmp4_);
	g_value_set_string (&display_dev_val, self->priv->device_num);
	x11displaydev = (console_kit_session_parameter_init (&_tmp5_, "x11-display-device", &display_dev_val), _tmp5_);
	is_local_val = (g_value_init (&_tmp6_, G_TYPE_BOOLEAN), _tmp6_);
	g_value_set_boolean (&is_local_val, TRUE);
	islocal = (console_kit_session_parameter_init (&_tmp7_, "is-local", &is_local_val), _tmp7_);
	_tmp13_ = NULL;
	_tmp12_ = NULL;
	parameters = (_tmp13_ = (_tmp12_ = g_new0 (ConsoleKitSessionParameter, 4), _tmp12_[0] = (console_kit_session_parameter_copy (&unixuser, &_tmp8_), _tmp8_), _tmp12_[1] = (console_kit_session_parameter_copy (&x11display, &_tmp9_), _tmp9_), _tmp12_[2] = (console_kit_session_parameter_copy (&x11displaydev, &_tmp10_), _tmp10_), _tmp12_[3] = (console_kit_session_parameter_copy (&islocal, &_tmp11_), _tmp11_), _tmp12_), parameters_length1 = 4, parameters_size = parameters_length1, _tmp13_);
	_tmp14_ = NULL;
	self->priv->cookie = (_tmp14_ = console_kit_manager_open_session_with_parameters (self->priv->ck_manager, parameters, parameters_length1), self->priv->cookie = (g_free (self->priv->cookie), NULL), _tmp14_);
	G_IS_VALUE (&user_val) ? (g_value_unset (&user_val), NULL) : NULL;
	console_kit_session_parameter_destroy (&unixuser);
	G_IS_VALUE (&display_val) ? (g_value_unset (&display_val), NULL) : NULL;
	console_kit_session_parameter_destroy (&x11display);
	G_IS_VALUE (&display_dev_val) ? (g_value_unset (&display_dev_val), NULL) : NULL;
	console_kit_session_parameter_destroy (&x11displaydev);
	G_IS_VALUE (&is_local_val) ? (g_value_unset (&is_local_val), NULL) : NULL;
	console_kit_session_parameter_destroy (&islocal);
	parameters = (_vala_ConsoleKitSessionParameter_array_free (parameters, parameters_length1), NULL);
}


static void xsaa_session_on_child_setup (XSAASession* self) {
	GError * _inner_error_;
	gint fd;
	char* _tmp0_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	{
		xsaa_pam_session_open_session (self->priv->pam, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch1_g_error;
			goto __finally1;
		}
	}
	goto __finally1;
	__catch1_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			g_signal_emit_by_name (self, "error-msg", "Invalid user or wrong password");
			fprintf (stderr, "Error on open pam session\n");
			exit (1);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally1:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	if (setsid () < 0) {
		g_signal_emit_by_name (self, "error-msg", "Error on user authentification");
		fprintf (stderr, "Error on change user\n");
		exit (1);
	}
	if (setuid (self->priv->passwd->pw_uid) < 0) {
		g_signal_emit_by_name (self, "error-msg", "Error on user authentification");
		fprintf (stderr, "Error on change user\n");
		exit (1);
	}
	xsaa_pam_session_set_env (self->priv->pam);
	setenv ("XAUTHORITY", self->priv->xauth_file, 1);
	setenv ("XDG_SESSION_COOKIE", self->priv->cookie, 1);
	setenv ("DISPLAY", self->priv->display_num, 1);
	fd = open ("/dev/null", O_RDONLY, 0);
	dup2 (fd, 0);
	close (fd);
	_tmp0_ = NULL;
	fd = open (_tmp0_ = g_strconcat (self->priv->passwd->pw_dir, "/.xsession-errors", NULL), (O_TRUNC | O_CREAT) | O_WRONLY, (mode_t) 0644);
	_tmp0_ = (g_free (_tmp0_), NULL);
	dup2 (fd, 1);
	dup2 (fd, 2);
	close (fd);
}


static void xsaa_session_on_child_watch (XSAASession* self, GPid pid, gint status) {
	GError * _inner_error_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	if (WIFEXITED (status)) {
		g_signal_emit_by_name (self, "exited");
	} else {
		if (WIFSIGNALED (status)) {
			g_signal_emit_by_name (self, "died");
		}
	}
	g_spawn_close_pid (pid);
	self->priv->pid = (GPid) 0;
	{
		g_spawn_command_line_async ("killall dbus-launch", &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch2_g_error;
			goto __finally2;
		}
	}
	goto __finally2;
	__catch2_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on launch killall dbus-launch: %s\n", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally2:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
}


static char* xsaa_session_on_ask_passwd (XSAASession* self) {
	char* result;
	const char* _tmp0_;
	g_return_val_if_fail (self != NULL, NULL);
	_tmp0_ = NULL;
	result = (_tmp0_ = self->priv->pass, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_));
	return result;
}


static void xsaa_session_on_info (XSAASession* self, const char* text) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (text != NULL);
	g_signal_emit_by_name (self, "info", text);
}


static void xsaa_session_on_error_msg (XSAASession* self, const char* text) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (text != NULL);
	g_signal_emit_by_name (self, "error-msg", text);
}


void xsaa_session_set_passwd (XSAASession* self, const char* pass) {
	char* _tmp1_;
	const char* _tmp0_;
	g_return_if_fail (self != NULL);
	g_return_if_fail (pass != NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->pass = (_tmp1_ = (_tmp0_ = pass, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_)), self->priv->pass = (g_free (self->priv->pass), NULL), _tmp1_);
}


void xsaa_session_authenticate (XSAASession* self) {
	g_return_if_fail (self != NULL);
	fprintf (stderr, "Authenticate \n");
	g_signal_emit_by_name (self, "authenticated");
}


static void _xsaa_session_on_child_setup_gspawn_child_setup_func (gpointer self) {
	xsaa_session_on_child_setup (self);
}


static void _xsaa_session_on_child_watch_gchild_watch_func (GPid pid, gint status, gpointer self) {
	xsaa_session_on_child_watch (self, pid, status);
}


void xsaa_session_launch (XSAASession* self, const char* cmd, GError** error) {
	GError * _inner_error_;
	gint argvp_size;
	gint argvp_length1;
	char** argvp;
	g_return_if_fail (self != NULL);
	g_return_if_fail (cmd != NULL);
	_inner_error_ = NULL;
	argvp = (argvp_length1 = 0, NULL);
	xsaa_session_register (self);
	{
		g_shell_parse_argv (cmd, &argvp_length1, &argvp, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch3_g_error;
			goto __finally3;
		}
	}
	goto __finally3;
	__catch3_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			_inner_error_ = g_error_new (XSAA_SESSION_ERROR, XSAA_SESSION_ERROR_COMMAND, "Invalid %s command !!", cmd);
			if (_inner_error_ != NULL) {
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
				argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
				goto __finally3;
			}
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally3:
	if (_inner_error_ != NULL) {
		if (_inner_error_->domain == XSAA_SESSION_ERROR) {
			g_propagate_error (error, _inner_error_);
			argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
			return;
		} else {
			argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return;
		}
	}
	{
		g_spawn_async (NULL, argvp, NULL, G_SPAWN_SEARCH_PATH | G_SPAWN_DO_NOT_REAP_CHILD, _xsaa_session_on_child_setup_gspawn_child_setup_func, self, &self->priv->pid, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch4_g_error;
			goto __finally4;
		}
		g_child_watch_add ((GPid) self->priv->pid, _xsaa_session_on_child_watch_gchild_watch_func, self);
	}
	goto __finally4;
	__catch4_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			_inner_error_ = g_error_new_literal (XSAA_SESSION_ERROR, XSAA_SESSION_ERROR_LAUNCH, err->message);
			if (_inner_error_ != NULL) {
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
				argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
				goto __finally4;
			}
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally4:
	if (_inner_error_ != NULL) {
		if (_inner_error_->domain == XSAA_SESSION_ERROR) {
			g_propagate_error (error, _inner_error_);
			argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
			return;
		} else {
			argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return;
		}
	}
	argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
}


void _xsaa_session_dbus_unregister (DBusConnection* connection, void* user_data) {
}


static DBusMessage* _dbus_xsaa_session_introspect (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter;
	GString* xml_data;
	char** children;
	int i;
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	xml_data = g_string_new ("<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\" \"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">\n");
	g_string_append (xml_data, "<node>\n<interface name=\"org.freedesktop.DBus.Introspectable\">\n  <method name=\"Introspect\">\n    <arg name=\"data\" direction=\"out\" type=\"s\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.DBus.Properties\">\n  <method name=\"Get\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"out\" type=\"v\"/>\n  </method>\n  <method name=\"Set\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"in\" type=\"v\"/>\n  </method>\n  <method name=\"GetAll\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"props\" direction=\"out\" type=\"a{sv}\"/>\n  </method>\n</interface>\n<interface name=\"fr.supersonicimagine.XSAA.Manager.Session\">\n  <method name=\"SetPasswd\">\n    <arg name=\"pass\" type=\"s\" direction=\"in\"/>\n  </method>\n  <method name=\"Authenticate\">\n  </method>\n  <method name=\"Launch\">\n    <arg name=\"cmd\" type=\"s\" direction=\"in\"/>\n  </method>\n  <signal name=\"Died\">\n  </signal>\n  <signal name=\"Exited\">\n  </signal>\n  <signal name=\"Authenticated\">\n  </signal>\n  <signal name=\"Info\">\n    <arg name=\"msg\" type=\"s\"/>\n  </signal>\n  <signal name=\"ErrorMsg\">\n    <arg name=\"msg\" type=\"s\"/>\n  </signal>\n</interface>\n");
	dbus_connection_list_registered (connection, g_object_get_data ((GObject *) self, "dbus_object_path"), &children);
	for (i = 0; children[i]; i++) {
		g_string_append_printf (xml_data, "<node name=\"%s\"/>\n", children[i]);
	}
	dbus_free_string_array (children);
	g_string_append (xml_data, "</node>\n");
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_STRING, &xml_data->str);
	g_string_free (xml_data, TRUE);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_property_get_all (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter, reply_iter, subiter;
	char* interface_name;
	const char* _tmp2_;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &reply_iter);
	dbus_message_iter_get_basic (&iter, &_tmp2_);
	dbus_message_iter_next (&iter);
	interface_name = g_strdup (_tmp2_);
	if (strcmp (interface_name, "fr.supersonicimagine.XSAA.Manager.Session") == 0) {
		dbus_message_iter_open_container (&reply_iter, DBUS_TYPE_ARRAY, "{sv}", &subiter);
		dbus_message_iter_close_container (&reply_iter, &subiter);
	} else {
		dbus_message_unref (reply);
		reply = NULL;
	}
	g_free (interface_name);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_set_passwd (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	char* pass;
	const char* _tmp3_;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	pass = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp3_);
	dbus_message_iter_next (&iter);
	pass = g_strdup (_tmp3_);
	xsaa_session_set_passwd (self, pass);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	pass = (g_free (pass), NULL);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_authenticate (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	xsaa_session_authenticate (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_launch (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	char* cmd;
	const char* _tmp4_;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	cmd = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp4_);
	dbus_message_iter_next (&iter);
	cmd = g_strdup (_tmp4_);
	xsaa_session_launch (self, cmd, &error);
	if (error) {
		reply = dbus_message_new_error (message, DBUS_ERROR_FAILED, error->message);
		return reply;
	}
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	cmd = (g_free (cmd), NULL);
	return reply;
}


DBusHandlerResult xsaa_session_dbus_message (DBusConnection* connection, DBusMessage* message, void* object) {
	DBusMessage* reply;
	reply = NULL;
	if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Introspectable", "Introspect")) {
		reply = _dbus_xsaa_session_introspect (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Properties", "GetAll")) {
		reply = _dbus_xsaa_session_property_get_all (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager.Session", "SetPasswd")) {
		reply = _dbus_xsaa_session_set_passwd (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager.Session", "Authenticate")) {
		reply = _dbus_xsaa_session_authenticate (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager.Session", "Launch")) {
		reply = _dbus_xsaa_session_launch (object, connection, message);
	}
	if (reply) {
		dbus_connection_send (connection, reply, NULL);
		dbus_message_unref (reply);
		return DBUS_HANDLER_RESULT_HANDLED;
	} else {
		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
	}
}


static void _dbus_xsaa_session_died (GObject* _sender, DBusConnection* _connection) {
	const char * _path;
	DBusMessage *_message;
	DBusMessageIter _iter;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "Died");
	dbus_message_iter_init_append (_message, &_iter);
	dbus_connection_send (_connection, _message, NULL);
	dbus_message_unref (_message);
}


static void _dbus_xsaa_session_exited (GObject* _sender, DBusConnection* _connection) {
	const char * _path;
	DBusMessage *_message;
	DBusMessageIter _iter;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "Exited");
	dbus_message_iter_init_append (_message, &_iter);
	dbus_connection_send (_connection, _message, NULL);
	dbus_message_unref (_message);
}


static void _dbus_xsaa_session_authenticated (GObject* _sender, DBusConnection* _connection) {
	const char * _path;
	DBusMessage *_message;
	DBusMessageIter _iter;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "Authenticated");
	dbus_message_iter_init_append (_message, &_iter);
	dbus_connection_send (_connection, _message, NULL);
	dbus_message_unref (_message);
}


static void _dbus_xsaa_session_info (GObject* _sender, const char* msg, DBusConnection* _connection) {
	const char * _path;
	DBusMessage *_message;
	DBusMessageIter _iter;
	const char* _tmp5_;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "Info");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp5_ = msg;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp5_);
	dbus_connection_send (_connection, _message, NULL);
	dbus_message_unref (_message);
}


static void _dbus_xsaa_session_error_msg (GObject* _sender, const char* msg, DBusConnection* _connection) {
	const char * _path;
	DBusMessage *_message;
	DBusMessageIter _iter;
	const char* _tmp6_;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "ErrorMsg");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp6_ = msg;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp6_);
	dbus_connection_send (_connection, _message, NULL);
	dbus_message_unref (_message);
}


void xsaa_session_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	if (!g_object_get_data (object, "dbus_object_path")) {
		g_object_set_data (object, "dbus_object_path", g_strdup (path));
		dbus_connection_register_object_path (connection, path, &_xsaa_session_dbus_path_vtable, object);
		g_object_weak_ref (object, _vala_dbus_unregister_object, connection);
	}
	g_signal_connect (object, "died", (GCallback) _dbus_xsaa_session_died, connection);
	g_signal_connect (object, "exited", (GCallback) _dbus_xsaa_session_exited, connection);
	g_signal_connect (object, "authenticated", (GCallback) _dbus_xsaa_session_authenticated, connection);
	g_signal_connect (object, "info", (GCallback) _dbus_xsaa_session_info, connection);
	g_signal_connect (object, "error-msg", (GCallback) _dbus_xsaa_session_error_msg, connection);
}


static void xsaa_session_class_init (XSAASessionClass * klass) {
	xsaa_session_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAASessionPrivate));
	G_OBJECT_CLASS (klass)->finalize = xsaa_session_finalize;
	g_signal_new ("died", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("exited", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("authenticated", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("info", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__STRING, G_TYPE_NONE, 1, G_TYPE_STRING);
	g_signal_new ("error_msg", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__STRING, G_TYPE_NONE, 1, G_TYPE_STRING);
	g_type_set_qdata (XSAA_TYPE_SESSION, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_xsaa_session_dbus_vtable));
}


static void xsaa_session_instance_init (XSAASession * self) {
	self->priv = XSAA_SESSION_GET_PRIVATE (self);
	self->priv->pid = (GPid) 0;
	self->priv->pass = NULL;
}


static void xsaa_session_finalize (GObject* obj) {
	XSAASession * self;
	self = XSAA_SESSION (obj);
	{
		fprintf (stderr, "Close ck session\n");
		if (g_file_test (self->priv->xauth_file, G_FILE_TEST_EXISTS)) {
			g_remove (self->priv->xauth_file);
		}
		if (self->priv->cookie != NULL) {
			console_kit_manager_close_session (self->priv->ck_manager, self->priv->cookie);
		}
		if (self->priv->pid != ((GPid) 0)) {
			kill ((pid_t) self->priv->pid, SIGKILL);
		}
		self->priv->pid = (GPid) 0;
	}
	(self->priv->ck_manager == NULL) ? NULL : (self->priv->ck_manager = (g_object_unref (self->priv->ck_manager), NULL));
	self->priv->cookie = (g_free (self->priv->cookie), NULL);
	self->priv->display_num = (g_free (self->priv->display_num), NULL);
	self->priv->device_num = (g_free (self->priv->device_num), NULL);
	self->priv->pass = (g_free (self->priv->pass), NULL);
	(self->priv->pam == NULL) ? NULL : (self->priv->pam = (g_object_unref (self->priv->pam), NULL));
	self->priv->xauth_file = (g_free (self->priv->xauth_file), NULL);
	G_OBJECT_CLASS (xsaa_session_parent_class)->finalize (obj);
}


GType xsaa_session_get_type (void) {
	static GType xsaa_session_type_id = 0;
	if (xsaa_session_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAASessionClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_session_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAASession), 0, (GInstanceInitFunc) xsaa_session_instance_init, NULL };
		xsaa_session_type_id = g_type_register_static (G_TYPE_OBJECT, "XSAASession", &g_define_type_info, 0);
	}
	return xsaa_session_type_id;
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


static void _vala_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	const _DBusObjectVTable * vtable;
	vtable = g_type_get_qdata (G_TYPE_FROM_INSTANCE (object), g_quark_from_static_string ("DBusObjectVTable"));
	if (vtable) {
		vtable->register_object (connection, path, object);
	} else {
		g_warning ("Object does not implement any D-Bus interface");
	}
}


static void _vala_dbus_unregister_object (gpointer connection, GObject* object) {
	char* path;
	path = g_object_steal_data ((GObject*) object, "dbus_object_path");
	dbus_connection_unregister_object_path (connection, path);
	g_free (path);
}




