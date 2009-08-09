/* xsaa-main.vala
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
#include <dbus/dbus-glib-lowlevel.h>
#include <dbus/dbus-glib.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <xsaa-private.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <config.h>
#include <stdio.h>
#include <gdk/gdk.h>
#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#include <fcntl.h>
#include <sys/types.h>
#include <stropts.h>
#include <linux/vt.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <dbus/dbus.h>


#define XSAA_TYPE_MANAGER (xsaa_manager_get_type ())
#define XSAA_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_MANAGER, XSAAManager))
#define XSAA_IS_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_MANAGER))
#define XSAA_MANAGER_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), XSAA_TYPE_MANAGER, XSAAManagerIface))

typedef struct _XSAAManager XSAAManager;
typedef struct _XSAAManagerIface XSAAManagerIface;
typedef struct _XSAAManagerDBusProxy XSAAManagerDBusProxy;
typedef DBusGProxyClass XSAAManagerDBusProxyClass;

#define XSAA_TYPE_SESSION (xsaa_session_get_type ())
#define XSAA_SESSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SESSION, XSAASession))
#define XSAA_IS_SESSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SESSION))
#define XSAA_SESSION_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), XSAA_TYPE_SESSION, XSAASessionIface))

typedef struct _XSAASession XSAASession;
typedef struct _XSAASessionIface XSAASessionIface;
typedef struct _XSAASessionDBusProxy XSAASessionDBusProxy;
typedef DBusGProxyClass XSAASessionDBusProxyClass;

#define XSAA_TYPE_DAEMON (xsaa_daemon_get_type ())
#define XSAA_DAEMON(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_DAEMON, XSAADaemon))
#define XSAA_DAEMON_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_DAEMON, XSAADaemonClass))
#define XSAA_IS_DAEMON(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_DAEMON))
#define XSAA_IS_DAEMON_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_DAEMON))
#define XSAA_DAEMON_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_DAEMON, XSAADaemonClass))

typedef struct _XSAADaemon XSAADaemon;
typedef struct _XSAADaemonClass XSAADaemonClass;
typedef struct _XSAADaemonPrivate XSAADaemonPrivate;

#define XSAA_TYPE_SERVER (xsaa_server_get_type ())
#define XSAA_SERVER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SERVER, XSAAServer))
#define XSAA_SERVER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SERVER, XSAAServerClass))
#define XSAA_IS_SERVER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SERVER))
#define XSAA_IS_SERVER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SERVER))
#define XSAA_SERVER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SERVER, XSAAServerClass))

typedef struct _XSAAServer XSAAServer;
typedef struct _XSAAServerClass XSAAServerClass;

#define XSAA_TYPE_SPLASH (xsaa_splash_get_type ())
#define XSAA_SPLASH(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SPLASH, XSAASplash))
#define XSAA_SPLASH_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SPLASH, XSAASplashClass))
#define XSAA_IS_SPLASH(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SPLASH))
#define XSAA_IS_SPLASH_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SPLASH))
#define XSAA_SPLASH_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SPLASH, XSAASplashClass))

typedef struct _XSAASplash XSAASplash;
typedef struct _XSAASplashClass XSAASplashClass;

#define XSAA_TYPE_DISPLAY (xsaa_display_get_type ())
#define XSAA_DISPLAY(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_DISPLAY, XSAADisplay))
#define XSAA_DISPLAY_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_DISPLAY, XSAADisplayClass))
#define XSAA_IS_DISPLAY(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_DISPLAY))
#define XSAA_IS_DISPLAY_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_DISPLAY))
#define XSAA_DISPLAY_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_DISPLAY, XSAADisplayClass))

typedef struct _XSAADisplay XSAADisplay;
typedef struct _XSAADisplayClass XSAADisplayClass;
typedef struct _DBusObjectVTable _DBusObjectVTable;

struct _XSAAManagerIface {
	GTypeInterface parent_iface;
	gboolean (*open_session) (XSAAManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path);
	void (*close_session) (XSAAManager* self, const char* path);
	void (*reboot) (XSAAManager* self);
	void (*halt) (XSAAManager* self);
};

struct _XSAAManagerDBusProxy {
	DBusGProxy parent_instance;
	gboolean disposed;
};

struct _XSAASessionIface {
	GTypeInterface parent_iface;
	void (*set_passwd) (XSAASession* self, const char* pass);
	void (*authenticate) (XSAASession* self);
	void (*launch) (XSAASession* self, const char* cmd);
};

struct _XSAASessionDBusProxy {
	DBusGProxy parent_instance;
	gboolean disposed;
};

typedef enum  {
	XSAA_DAEMON_ERROR_DISABLED
} XSAADaemonError;
#define XSAA_DAEMON_ERROR xsaa_daemon_error_quark ()
struct _XSAADaemon {
	GObject parent_instance;
	XSAADaemonPrivate * priv;
	char** args;
	gint args_length1;
	jmp_buf env;
};

struct _XSAADaemonClass {
	GObjectClass parent_class;
};

struct _XSAADaemonPrivate {
	gboolean enable;
	gboolean first_start;
	XSAAServer* socket;
	XSAASplash* splash;
	XSAADisplay* display;
	DBusGConnection* conn;
	XSAAManager* manager;
	char* server;
	gint number;
	char* device;
	char* options;
	char* user;
	char* pass;
	char* exec;
	char* path;
	XSAASession* session;
};

typedef enum  {
	XSAA_DISPLAY_ERROR_COMMAND,
	XSAA_DISPLAY_ERROR_LAUNCH
} XSAADisplayError;
#define XSAA_DISPLAY_ERROR xsaa_display_error_quark ()
struct _DBusObjectVTable {
	void (*register_object) (DBusConnection*, const char*, void*);
};


extern XSAADaemon* xsaa_daemon;
XSAADaemon* xsaa_daemon = NULL;
extern gboolean xsaa_shutdown;
gboolean xsaa_shutdown = FALSE;
static gpointer xsaa_daemon_parent_class = NULL;

GType xsaa_manager_get_type (void);
gboolean xsaa_manager_open_session (XSAAManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path);
void xsaa_manager_close_session (XSAAManager* self, const char* path);
void xsaa_manager_reboot (XSAAManager* self);
void xsaa_manager_halt (XSAAManager* self);
void xsaa_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object);
void _xsaa_manager_dbus_unregister (DBusConnection* connection, void* user_data);
DBusHandlerResult xsaa_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object);
static DBusMessage* _dbus_xsaa_manager_introspect (XSAAManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_manager_property_get_all (XSAAManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_manager_open_session (XSAAManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_manager_close_session (XSAAManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_manager_reboot (XSAAManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_manager_halt (XSAAManager* self, DBusConnection* connection, DBusMessage* message);
GType xsaa_manager_dbus_proxy_get_type (void);
XSAAManager* xsaa_manager_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path);
DBusHandlerResult xsaa_manager_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data);
enum  {
	XSAA_MANAGER_DBUS_PROXY_DUMMY_PROPERTY
};
static gboolean xsaa_manager_dbus_proxy_open_session (XSAAManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path);
static void xsaa_manager_dbus_proxy_close_session (XSAAManager* self, const char* path);
static void xsaa_manager_dbus_proxy_reboot (XSAAManager* self);
static void xsaa_manager_dbus_proxy_halt (XSAAManager* self);
static void xsaa_manager_dbus_proxy_interface_init (XSAAManagerIface* iface);
static void xsaa_manager_dbus_proxy_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec);
static void xsaa_manager_dbus_proxy_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec);
GType xsaa_session_get_type (void);
void xsaa_session_set_passwd (XSAASession* self, const char* pass);
void xsaa_session_authenticate (XSAASession* self);
void xsaa_session_launch (XSAASession* self, const char* cmd);
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
GType xsaa_session_dbus_proxy_get_type (void);
XSAASession* xsaa_session_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path);
static void _dbus_handle_xsaa_session_died (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static void _dbus_handle_xsaa_session_exited (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static void _dbus_handle_xsaa_session_authenticated (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static void _dbus_handle_xsaa_session_info (XSAASession* self, DBusConnection* connection, DBusMessage* message);
static void _dbus_handle_xsaa_session_error_msg (XSAASession* self, DBusConnection* connection, DBusMessage* message);
DBusHandlerResult xsaa_session_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data);
enum  {
	XSAA_SESSION_DBUS_PROXY_DUMMY_PROPERTY
};
static void xsaa_session_dbus_proxy_set_passwd (XSAASession* self, const char* pass);
static void xsaa_session_dbus_proxy_authenticate (XSAASession* self);
static void xsaa_session_dbus_proxy_launch (XSAASession* self, const char* cmd);
static void xsaa_session_dbus_proxy_interface_init (XSAASessionIface* iface);
static void xsaa_session_dbus_proxy_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec);
static void xsaa_session_dbus_proxy_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec);
#define XSAA_SOCKET_NAME "/tmp/xsplashaa-socket"
GType xsaa_daemon_get_type (void);
GQuark xsaa_daemon_error_quark (void);
GType xsaa_server_get_type (void);
GType xsaa_splash_get_type (void);
GType xsaa_display_get_type (void);
#define XSAA_DAEMON_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_DAEMON, XSAADaemonPrivate))
enum  {
	XSAA_DAEMON_DUMMY_PROPERTY
};
static void xsaa_daemon_load_config (XSAADaemon* self);
GQuark xsaa_display_error_quark (void);
XSAADisplay* xsaa_display_new (const char* cmd, gint number, GError** error);
XSAADisplay* xsaa_display_construct (GType object_type, const char* cmd, gint number, GError** error);
static void xsaa_daemon_on_display_ready (XSAADaemon* self);
static void _xsaa_daemon_on_display_ready_xsaa_display_ready (XSAADisplay* _sender, gpointer self);
static void xsaa_daemon_on_display_exit (XSAADaemon* self);
static void _xsaa_daemon_on_display_exit_xsaa_display_died (XSAADisplay* _sender, gpointer self);
static void _xsaa_daemon_on_display_exit_xsaa_display_exited (XSAADisplay* _sender, gpointer self);
XSAAServer* xsaa_server_new (const char* socket_name, GError** error);
XSAAServer* xsaa_server_construct (GType object_type, const char* socket_name, GError** error);
static void xsaa_daemon_on_dbus_ready (XSAADaemon* self);
static void _xsaa_daemon_on_dbus_ready_xsaa_server_dbus (XSAAServer* _sender, gpointer self);
static void xsaa_daemon_on_session_ready (XSAADaemon* self);
static void _xsaa_daemon_on_session_ready_xsaa_server_session (XSAAServer* _sender, gpointer self);
static void xsaa_daemon_on_init_shutdown (XSAADaemon* self);
static void _xsaa_daemon_on_init_shutdown_xsaa_server_close_session (XSAAServer* _sender, gpointer self);
static void xsaa_daemon_on_quit (XSAADaemon* self);
static void _xsaa_daemon_on_quit_xsaa_server_quit (XSAAServer* _sender, gpointer self);
XSAADaemon* xsaa_daemon_new (const char* socket_name, GError** error);
XSAADaemon* xsaa_daemon_construct (GType object_type, const char* socket_name, GError** error);
void xsaa_change_vt (gint vt);
static void xsaa_daemon_change_to_display_vt (XSAADaemon* self);
gint xsaa_on_display_io_error (Display* display);
static gint _xsaa_on_display_io_error_io_error_handler (Display* display);
XSAASplash* xsaa_splash_new (XSAAServer* server);
XSAASplash* xsaa_splash_construct (GType object_type, XSAAServer* server);
static void xsaa_daemon_on_login_response (XSAADaemon* self, const char* username, const char* passwd);
static void _xsaa_daemon_on_login_response_xsaa_splash_login (XSAASplash* _sender, const char* username, const char* passwd, gpointer self);
static void xsaa_daemon_on_restart_request (XSAADaemon* self);
static void _xsaa_daemon_on_restart_request_xsaa_splash_restart (XSAASplash* _sender, gpointer self);
static void xsaa_daemon_on_shutdown_request (XSAADaemon* self);
static void _xsaa_daemon_on_shutdown_request_xsaa_splash_shutdown (XSAASplash* _sender, gpointer self);
static void xsaa_daemon_on_session_ended (XSAADaemon* self);
static void _xsaa_daemon_on_session_ended_xsaa_session_died (XSAASession* _sender, gpointer self);
static void _xsaa_daemon_on_session_ended_xsaa_session_exited (XSAASession* _sender, gpointer self);
static void xsaa_daemon_on_session_info (XSAADaemon* self, const char* msg);
static void _xsaa_daemon_on_session_info_xsaa_session_info (XSAASession* _sender, const char* msg, gpointer self);
static void xsaa_daemon_on_error_msg (XSAADaemon* self, const char* msg);
static void _xsaa_daemon_on_error_msg_xsaa_session_error_msg (XSAASession* _sender, const char* msg, gpointer self);
static gboolean xsaa_daemon_open_session (XSAADaemon* self, const char* username, gboolean autologin);
char* xsaa_display_get_device (XSAADisplay* self);
void xsaa_splash_ask_for_login (XSAASplash* self);
static void xsaa_daemon_on_authenticated (XSAADaemon* self);
static void _xsaa_daemon_on_authenticated_xsaa_session_authenticated (XSAASession* _sender, gpointer self);
void xsaa_splash_show_shutdown (XSAASplash* self);
void xsaa_splash_login_message (XSAASplash* self, const char* msg);
void xsaa_splash_show_launch (XSAASplash* self);
void xsaa_daemon_run (XSAADaemon* self, gboolean first_start);
static void xsaa_daemon_finalize (GObject* obj);
void xsaa_on_sig_term (gint signum);
static void _xsaa_on_sig_term_sighandler_t (gint signal);
static char** _vala_array_dup1 (char** self, int length);
gint xsaa_main (char** args, int args_length1);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_dbus_register_object (DBusConnection* connection, const char* path, void* object);
static void _vala_dbus_unregister_object (gpointer connection, GObject* object);

static const DBusObjectPathVTable _xsaa_manager_dbus_path_vtable = {_xsaa_manager_dbus_unregister, xsaa_manager_dbus_message};
static const _DBusObjectVTable _xsaa_manager_dbus_vtable = {xsaa_manager_dbus_register_object};
static const DBusObjectPathVTable _xsaa_session_dbus_path_vtable = {_xsaa_session_dbus_unregister, xsaa_session_dbus_message};
static const _DBusObjectVTable _xsaa_session_dbus_vtable = {xsaa_session_dbus_register_object};


gboolean xsaa_manager_open_session (XSAAManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path) {
	return XSAA_MANAGER_GET_INTERFACE (self)->open_session (self, user, display, device, autologin, path);
}


void xsaa_manager_close_session (XSAAManager* self, const char* path) {
	XSAA_MANAGER_GET_INTERFACE (self)->close_session (self, path);
}


void xsaa_manager_reboot (XSAAManager* self) {
	XSAA_MANAGER_GET_INTERFACE (self)->reboot (self);
}


void xsaa_manager_halt (XSAAManager* self) {
	XSAA_MANAGER_GET_INTERFACE (self)->halt (self);
}


void _xsaa_manager_dbus_unregister (DBusConnection* connection, void* user_data) {
}


static DBusMessage* _dbus_xsaa_manager_introspect (XSAAManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter;
	GString* xml_data;
	char** children;
	int i;
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	xml_data = g_string_new ("<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\" \"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">\n");
	g_string_append (xml_data, "<node>\n<interface name=\"org.freedesktop.DBus.Introspectable\">\n  <method name=\"Introspect\">\n    <arg name=\"data\" direction=\"out\" type=\"s\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.DBus.Properties\">\n  <method name=\"Get\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"out\" type=\"v\"/>\n  </method>\n  <method name=\"Set\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"in\" type=\"v\"/>\n  </method>\n  <method name=\"GetAll\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"props\" direction=\"out\" type=\"a{sv}\"/>\n  </method>\n</interface>\n<interface name=\"fr.supersonicimagine.XSAA.Manager\">\n  <method name=\"OpenSession\">\n    <arg name=\"user\" type=\"s\" direction=\"in\"/>\n    <arg name=\"display\" type=\"i\" direction=\"in\"/>\n    <arg name=\"device\" type=\"s\" direction=\"in\"/>\n    <arg name=\"autologin\" type=\"b\" direction=\"in\"/>\n    <arg name=\"path\" type=\"o\" direction=\"out\"/>\n    <arg name=\"result\" type=\"b\" direction=\"out\"/>\n  </method>\n  <method name=\"CloseSession\">\n    <arg name=\"path\" type=\"o\" direction=\"in\"/>\n  </method>\n  <method name=\"Reboot\">\n  </method>\n  <method name=\"Halt\">\n  </method>\n</interface>\n");
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


static DBusMessage* _dbus_xsaa_manager_property_get_all (XSAAManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter, reply_iter, subiter;
	char* interface_name;
	const char* _tmp0_;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &reply_iter);
	dbus_message_iter_get_basic (&iter, &_tmp0_);
	dbus_message_iter_next (&iter);
	interface_name = g_strdup (_tmp0_);
	if (strcmp (interface_name, "fr.supersonicimagine.XSAA.Manager") == 0) {
		dbus_message_iter_open_container (&reply_iter, DBUS_TYPE_ARRAY, "{sv}", &subiter);
		dbus_message_iter_close_container (&reply_iter, &subiter);
	} else {
		dbus_message_unref (reply);
		reply = NULL;
	}
	g_free (interface_name);
	return reply;
}


static DBusMessage* _dbus_xsaa_manager_open_session (XSAAManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	char* user;
	const char* _tmp1_;
	gint display;
	dbus_int32_t _tmp2_;
	char* device;
	const char* _tmp3_;
	gboolean autologin;
	dbus_bool_t _tmp4_;
	char* path;
	gboolean result;
	DBusMessage* reply;
	const char* _tmp5_;
	dbus_bool_t _tmp6_;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "sisb")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	user = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp1_);
	dbus_message_iter_next (&iter);
	user = g_strdup (_tmp1_);
	display = 0;
	dbus_message_iter_get_basic (&iter, &_tmp2_);
	dbus_message_iter_next (&iter);
	display = _tmp2_;
	device = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp3_);
	dbus_message_iter_next (&iter);
	device = g_strdup (_tmp3_);
	autologin = FALSE;
	dbus_message_iter_get_basic (&iter, &_tmp4_);
	dbus_message_iter_next (&iter);
	autologin = _tmp4_;
	path = NULL;
	result = xsaa_manager_open_session (self, user, display, device, autologin, &path);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	user = (g_free (user), NULL);
	device = (g_free (device), NULL);
	_tmp5_ = path;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_OBJECT_PATH, &_tmp5_);
	path = (g_free (path), NULL);
	_tmp6_ = result;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_BOOLEAN, &_tmp6_);
	return reply;
}


static DBusMessage* _dbus_xsaa_manager_close_session (XSAAManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	char* path;
	const char* _tmp7_;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "o")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	path = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp7_);
	dbus_message_iter_next (&iter);
	path = g_strdup (_tmp7_);
	xsaa_manager_close_session (self, path);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	path = (g_free (path), NULL);
	return reply;
}


static DBusMessage* _dbus_xsaa_manager_reboot (XSAAManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	xsaa_manager_reboot (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


static DBusMessage* _dbus_xsaa_manager_halt (XSAAManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	xsaa_manager_halt (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


DBusHandlerResult xsaa_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object) {
	DBusMessage* reply;
	reply = NULL;
	if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Introspectable", "Introspect")) {
		reply = _dbus_xsaa_manager_introspect (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Properties", "GetAll")) {
		reply = _dbus_xsaa_manager_property_get_all (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "OpenSession")) {
		reply = _dbus_xsaa_manager_open_session (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "CloseSession")) {
		reply = _dbus_xsaa_manager_close_session (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "Reboot")) {
		reply = _dbus_xsaa_manager_reboot (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "Halt")) {
		reply = _dbus_xsaa_manager_halt (object, connection, message);
	}
	if (reply) {
		dbus_connection_send (connection, reply, NULL);
		dbus_message_unref (reply);
		return DBUS_HANDLER_RESULT_HANDLED;
	} else {
		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
	}
}


void xsaa_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	if (!g_object_get_data (object, "dbus_object_path")) {
		g_object_set_data (object, "dbus_object_path", g_strdup (path));
		dbus_connection_register_object_path (connection, path, &_xsaa_manager_dbus_path_vtable, object);
		g_object_weak_ref (object, _vala_dbus_unregister_object, connection);
	}
}


static void xsaa_manager_base_init (XSAAManagerIface * iface) {
	static gboolean initialized = FALSE;
	if (!initialized) {
		initialized = TRUE;
		g_type_set_qdata (XSAA_TYPE_MANAGER, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_xsaa_manager_dbus_vtable));
	}
}


GType xsaa_manager_get_type (void) {
	static GType xsaa_manager_type_id = 0;
	if (xsaa_manager_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAAManagerIface), (GBaseInitFunc) xsaa_manager_base_init, (GBaseFinalizeFunc) NULL, (GClassInitFunc) NULL, (GClassFinalizeFunc) NULL, NULL, 0, 0, (GInstanceInitFunc) NULL, NULL };
		xsaa_manager_type_id = g_type_register_static (G_TYPE_INTERFACE, "XSAAManager", &g_define_type_info, 0);
		g_type_interface_add_prerequisite (xsaa_manager_type_id, DBUS_TYPE_G_PROXY);
		g_type_set_qdata (xsaa_manager_type_id, g_quark_from_string ("ValaDBusInterfaceProxyType"), &xsaa_manager_dbus_proxy_get_type);
	}
	return xsaa_manager_type_id;
}


G_DEFINE_TYPE_EXTENDED (XSAAManagerDBusProxy, xsaa_manager_dbus_proxy, DBUS_TYPE_G_PROXY, 0, G_IMPLEMENT_INTERFACE (XSAA_TYPE_MANAGER, xsaa_manager_dbus_proxy_interface_init));
XSAAManager* xsaa_manager_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path) {
	XSAAManager* self;
	self = g_object_new (xsaa_manager_dbus_proxy_get_type (), "connection", connection, "name", name, "path", path, "interface", "fr.supersonicimagine.XSAA.Manager", NULL);
	return self;
}


static GObject* xsaa_manager_dbus_proxy_construct (GType gtype, guint n_properties, GObjectConstructParam* properties) {
	GObject* self;
	DBusGConnection *connection;
	char* path;
	char* filter;
	self = G_OBJECT_CLASS (xsaa_manager_dbus_proxy_parent_class)->constructor (gtype, n_properties, properties);
	g_object_get (self, "connection", &connection, NULL);
	g_object_get (self, "path", &path, NULL);
	dbus_connection_add_filter (dbus_g_connection_get_connection (connection), xsaa_manager_dbus_proxy_filter, self, NULL);
	filter = g_strdup_printf ("type='signal',path='%s'", path);
	dbus_bus_add_match (dbus_g_connection_get_connection (connection), filter, NULL);
	dbus_g_connection_unref (connection);
	g_free (path);
	g_free (filter);
	return self;
}


DBusHandlerResult xsaa_manager_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data) {
	if (dbus_message_has_path (message, dbus_g_proxy_get_path (user_data))) {
	}
	return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}


static void xsaa_manager_dbus_proxy_dispose (GObject* self) {
	DBusGConnection *connection;
	if (((XSAAManagerDBusProxy*) self)->disposed) {
		return;
	}
	((XSAAManagerDBusProxy*) self)->disposed = TRUE;
	g_object_get (self, "connection", &connection, NULL);
	dbus_connection_remove_filter (dbus_g_connection_get_connection (connection), xsaa_manager_dbus_proxy_filter, self);
	G_OBJECT_CLASS (xsaa_manager_dbus_proxy_parent_class)->dispose (self);
}


static void xsaa_manager_dbus_proxy_class_init (XSAAManagerDBusProxyClass* klass) {
	G_OBJECT_CLASS (klass)->constructor = xsaa_manager_dbus_proxy_construct;
	G_OBJECT_CLASS (klass)->dispose = xsaa_manager_dbus_proxy_dispose;
	G_OBJECT_CLASS (klass)->get_property = xsaa_manager_dbus_proxy_get_property;
	G_OBJECT_CLASS (klass)->set_property = xsaa_manager_dbus_proxy_set_property;
}


static void xsaa_manager_dbus_proxy_init (XSAAManagerDBusProxy* self) {
}


static gboolean xsaa_manager_dbus_proxy_open_session (XSAAManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	const char* _tmp8_;
	dbus_int32_t _tmp9_;
	const char* _tmp10_;
	dbus_bool_t _tmp11_;
	char* _path;
	const char* _tmp12_;
	gboolean _result;
	dbus_bool_t _tmp13_;
	if (((XSAAManagerDBusProxy*) self)->disposed) {
		return FALSE;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager", "OpenSession");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp8_ = user;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp8_);
	_tmp9_ = display;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_INT32, &_tmp9_);
	_tmp10_ = device;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp10_);
	_tmp11_ = autologin;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_BOOLEAN, &_tmp11_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_iter_get_basic (&_iter, &_tmp12_);
	dbus_message_iter_next (&_iter);
	_path = g_strdup (_tmp12_);
	*path = _path;
	dbus_message_iter_get_basic (&_iter, &_tmp13_);
	dbus_message_iter_next (&_iter);
	_result = _tmp13_;
	dbus_message_unref (_reply);
	return _result;
}


static void xsaa_manager_dbus_proxy_close_session (XSAAManager* self, const char* path) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	const char* _tmp14_;
	if (((XSAAManagerDBusProxy*) self)->disposed) {
		return;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager", "CloseSession");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp14_ = path;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_OBJECT_PATH, &_tmp14_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void xsaa_manager_dbus_proxy_reboot (XSAAManager* self) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	if (((XSAAManagerDBusProxy*) self)->disposed) {
		return;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager", "Reboot");
	dbus_message_iter_init_append (_message, &_iter);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void xsaa_manager_dbus_proxy_halt (XSAAManager* self) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	if (((XSAAManagerDBusProxy*) self)->disposed) {
		return;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager", "Halt");
	dbus_message_iter_init_append (_message, &_iter);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void xsaa_manager_dbus_proxy_interface_init (XSAAManagerIface* iface) {
	iface->open_session = xsaa_manager_dbus_proxy_open_session;
	iface->close_session = xsaa_manager_dbus_proxy_close_session;
	iface->reboot = xsaa_manager_dbus_proxy_reboot;
	iface->halt = xsaa_manager_dbus_proxy_halt;
}


static void xsaa_manager_dbus_proxy_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec) {
}


static void xsaa_manager_dbus_proxy_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec) {
}


void xsaa_session_set_passwd (XSAASession* self, const char* pass) {
	XSAA_SESSION_GET_INTERFACE (self)->set_passwd (self, pass);
}


void xsaa_session_authenticate (XSAASession* self) {
	XSAA_SESSION_GET_INTERFACE (self)->authenticate (self);
}


void xsaa_session_launch (XSAASession* self, const char* cmd) {
	XSAA_SESSION_GET_INTERFACE (self)->launch (self, cmd);
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
	const char* _tmp15_;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &reply_iter);
	dbus_message_iter_get_basic (&iter, &_tmp15_);
	dbus_message_iter_next (&iter);
	interface_name = g_strdup (_tmp15_);
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
	const char* _tmp16_;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	pass = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp16_);
	dbus_message_iter_next (&iter);
	pass = g_strdup (_tmp16_);
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
	const char* _tmp17_;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	cmd = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp17_);
	dbus_message_iter_next (&iter);
	cmd = g_strdup (_tmp17_);
	xsaa_session_launch (self, cmd);
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
	const char* _tmp18_;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "Info");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp18_ = msg;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp18_);
	dbus_connection_send (_connection, _message, NULL);
	dbus_message_unref (_message);
}


static void _dbus_xsaa_session_error_msg (GObject* _sender, const char* msg, DBusConnection* _connection) {
	const char * _path;
	DBusMessage *_message;
	DBusMessageIter _iter;
	const char* _tmp19_;
	_path = g_object_get_data (_sender, "dbus_object_path");
	_message = dbus_message_new_signal (_path, "fr.supersonicimagine.XSAA.Manager.Session", "ErrorMsg");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp19_ = msg;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp19_);
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


static void xsaa_session_base_init (XSAASessionIface * iface) {
	static gboolean initialized = FALSE;
	if (!initialized) {
		initialized = TRUE;
		g_signal_new ("died", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
		g_signal_new ("exited", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
		g_signal_new ("authenticated", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
		g_signal_new ("info", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__STRING, G_TYPE_NONE, 1, G_TYPE_STRING);
		g_signal_new ("error_msg", XSAA_TYPE_SESSION, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__STRING, G_TYPE_NONE, 1, G_TYPE_STRING);
		g_type_set_qdata (XSAA_TYPE_SESSION, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_xsaa_session_dbus_vtable));
	}
}


GType xsaa_session_get_type (void) {
	static GType xsaa_session_type_id = 0;
	if (xsaa_session_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAASessionIface), (GBaseInitFunc) xsaa_session_base_init, (GBaseFinalizeFunc) NULL, (GClassInitFunc) NULL, (GClassFinalizeFunc) NULL, NULL, 0, 0, (GInstanceInitFunc) NULL, NULL };
		xsaa_session_type_id = g_type_register_static (G_TYPE_INTERFACE, "XSAASession", &g_define_type_info, 0);
		g_type_interface_add_prerequisite (xsaa_session_type_id, DBUS_TYPE_G_PROXY);
		g_type_set_qdata (xsaa_session_type_id, g_quark_from_string ("ValaDBusInterfaceProxyType"), &xsaa_session_dbus_proxy_get_type);
	}
	return xsaa_session_type_id;
}


G_DEFINE_TYPE_EXTENDED (XSAASessionDBusProxy, xsaa_session_dbus_proxy, DBUS_TYPE_G_PROXY, 0, G_IMPLEMENT_INTERFACE (XSAA_TYPE_SESSION, xsaa_session_dbus_proxy_interface_init));
XSAASession* xsaa_session_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path) {
	XSAASession* self;
	self = g_object_new (xsaa_session_dbus_proxy_get_type (), "connection", connection, "name", name, "path", path, "interface", "fr.supersonicimagine.XSAA.Manager.Session", NULL);
	return self;
}


static GObject* xsaa_session_dbus_proxy_construct (GType gtype, guint n_properties, GObjectConstructParam* properties) {
	GObject* self;
	DBusGConnection *connection;
	char* path;
	char* filter;
	self = G_OBJECT_CLASS (xsaa_session_dbus_proxy_parent_class)->constructor (gtype, n_properties, properties);
	g_object_get (self, "connection", &connection, NULL);
	g_object_get (self, "path", &path, NULL);
	dbus_connection_add_filter (dbus_g_connection_get_connection (connection), xsaa_session_dbus_proxy_filter, self, NULL);
	filter = g_strdup_printf ("type='signal',path='%s'", path);
	dbus_bus_add_match (dbus_g_connection_get_connection (connection), filter, NULL);
	dbus_g_connection_unref (connection);
	g_free (path);
	g_free (filter);
	return self;
}


static void _dbus_handle_xsaa_session_died (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	DBusMessage* reply;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return;
	}
	dbus_message_iter_init (message, &iter);
	g_signal_emit_by_name (self, "died");
}


static void _dbus_handle_xsaa_session_exited (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	DBusMessage* reply;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return;
	}
	dbus_message_iter_init (message, &iter);
	g_signal_emit_by_name (self, "exited");
}


static void _dbus_handle_xsaa_session_authenticated (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	DBusMessage* reply;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return;
	}
	dbus_message_iter_init (message, &iter);
	g_signal_emit_by_name (self, "authenticated");
}


static void _dbus_handle_xsaa_session_info (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	const char* msg;
	const char* _tmp20_;
	DBusMessage* reply;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return;
	}
	dbus_message_iter_init (message, &iter);
	msg = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp20_);
	dbus_message_iter_next (&iter);
	msg = g_strdup (_tmp20_);
	g_signal_emit_by_name (self, "info", msg);
}


static void _dbus_handle_xsaa_session_error_msg (XSAASession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	const char* msg;
	const char* _tmp21_;
	DBusMessage* reply;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return;
	}
	dbus_message_iter_init (message, &iter);
	msg = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp21_);
	dbus_message_iter_next (&iter);
	msg = g_strdup (_tmp21_);
	g_signal_emit_by_name (self, "error-msg", msg);
}


DBusHandlerResult xsaa_session_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data) {
	if (dbus_message_has_path (message, dbus_g_proxy_get_path (user_data))) {
		if (dbus_message_is_signal (message, "fr.supersonicimagine.XSAA.Manager.Session", "Died")) {
			_dbus_handle_xsaa_session_died (user_data, connection, message);
		} else if (dbus_message_is_signal (message, "fr.supersonicimagine.XSAA.Manager.Session", "Exited")) {
			_dbus_handle_xsaa_session_exited (user_data, connection, message);
		} else if (dbus_message_is_signal (message, "fr.supersonicimagine.XSAA.Manager.Session", "Authenticated")) {
			_dbus_handle_xsaa_session_authenticated (user_data, connection, message);
		} else if (dbus_message_is_signal (message, "fr.supersonicimagine.XSAA.Manager.Session", "Info")) {
			_dbus_handle_xsaa_session_info (user_data, connection, message);
		} else if (dbus_message_is_signal (message, "fr.supersonicimagine.XSAA.Manager.Session", "ErrorMsg")) {
			_dbus_handle_xsaa_session_error_msg (user_data, connection, message);
		}
	}
	return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}


static void xsaa_session_dbus_proxy_dispose (GObject* self) {
	DBusGConnection *connection;
	if (((XSAASessionDBusProxy*) self)->disposed) {
		return;
	}
	((XSAASessionDBusProxy*) self)->disposed = TRUE;
	g_object_get (self, "connection", &connection, NULL);
	dbus_connection_remove_filter (dbus_g_connection_get_connection (connection), xsaa_session_dbus_proxy_filter, self);
	G_OBJECT_CLASS (xsaa_session_dbus_proxy_parent_class)->dispose (self);
}


static void xsaa_session_dbus_proxy_class_init (XSAASessionDBusProxyClass* klass) {
	G_OBJECT_CLASS (klass)->constructor = xsaa_session_dbus_proxy_construct;
	G_OBJECT_CLASS (klass)->dispose = xsaa_session_dbus_proxy_dispose;
	G_OBJECT_CLASS (klass)->get_property = xsaa_session_dbus_proxy_get_property;
	G_OBJECT_CLASS (klass)->set_property = xsaa_session_dbus_proxy_set_property;
}


static void xsaa_session_dbus_proxy_init (XSAASessionDBusProxy* self) {
}


static void xsaa_session_dbus_proxy_set_passwd (XSAASession* self, const char* pass) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	const char* _tmp22_;
	if (((XSAASessionDBusProxy*) self)->disposed) {
		return;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager.Session", "SetPasswd");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp22_ = pass;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp22_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void xsaa_session_dbus_proxy_authenticate (XSAASession* self) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	if (((XSAASessionDBusProxy*) self)->disposed) {
		return;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager.Session", "Authenticate");
	dbus_message_iter_init_append (_message, &_iter);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void xsaa_session_dbus_proxy_launch (XSAASession* self, const char* cmd) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	const char* _tmp23_;
	if (((XSAASessionDBusProxy*) self)->disposed) {
		return;
	}
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "fr.supersonicimagine.XSAA.Manager.Session", "Launch");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp23_ = cmd;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp23_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void xsaa_session_dbus_proxy_interface_init (XSAASessionIface* iface) {
	iface->set_passwd = xsaa_session_dbus_proxy_set_passwd;
	iface->authenticate = xsaa_session_dbus_proxy_authenticate;
	iface->launch = xsaa_session_dbus_proxy_launch;
}


static void xsaa_session_dbus_proxy_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec) {
}


static void xsaa_session_dbus_proxy_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec) {
}


GQuark xsaa_daemon_error_quark (void) {
	return g_quark_from_static_string ("xsaa_daemon_error-quark");
}


static void _xsaa_daemon_on_display_ready_xsaa_display_ready (XSAADisplay* _sender, gpointer self) {
	xsaa_daemon_on_display_ready (self);
}


static void _xsaa_daemon_on_display_exit_xsaa_display_died (XSAADisplay* _sender, gpointer self) {
	xsaa_daemon_on_display_exit (self);
}


static void _xsaa_daemon_on_display_exit_xsaa_display_exited (XSAADisplay* _sender, gpointer self) {
	xsaa_daemon_on_display_exit (self);
}


static void _xsaa_daemon_on_dbus_ready_xsaa_server_dbus (XSAAServer* _sender, gpointer self) {
	xsaa_daemon_on_dbus_ready (self);
}


static void _xsaa_daemon_on_session_ready_xsaa_server_session (XSAAServer* _sender, gpointer self) {
	xsaa_daemon_on_session_ready (self);
}


static void _xsaa_daemon_on_init_shutdown_xsaa_server_close_session (XSAAServer* _sender, gpointer self) {
	xsaa_daemon_on_init_shutdown (self);
}


static void _xsaa_daemon_on_quit_xsaa_server_quit (XSAAServer* _sender, gpointer self) {
	xsaa_daemon_on_quit (self);
}


XSAADaemon* xsaa_daemon_construct (GType object_type, const char* socket_name, GError** error) {
	GError * _inner_error_;
	XSAADaemon * self;
	char* _tmp3_;
	char* _tmp2_;
	char* _tmp1_;
	char* _tmp0_;
	char* _tmp4_;
	char* cmd;
	g_return_val_if_fail (socket_name != NULL, NULL);
	_inner_error_ = NULL;
	self = g_object_newv (object_type, 0, NULL);
	xsaa_daemon_load_config (self);
	if (!self->priv->enable) {
		_inner_error_ = g_error_new_literal (XSAA_DAEMON_ERROR, XSAA_DAEMON_ERROR_DISABLED, "Use gdm instead xsplashaa");
		if (_inner_error_ != NULL) {
			g_propagate_error (error, _inner_error_);
			return;
		}
	}
	_tmp3_ = NULL;
	_tmp2_ = NULL;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	_tmp4_ = NULL;
	cmd = (_tmp4_ = g_strconcat (_tmp3_ = g_strconcat (_tmp2_ = g_strconcat (_tmp0_ = g_strconcat (self->priv->server, " :", NULL), _tmp1_ = g_strdup_printf ("%i", self->priv->number), NULL), " ", NULL), self->priv->options, NULL), _tmp3_ = (g_free (_tmp3_), NULL), _tmp2_ = (g_free (_tmp2_), NULL), _tmp1_ = (g_free (_tmp1_), NULL), _tmp0_ = (g_free (_tmp0_), NULL), _tmp4_);
	{
		XSAADisplay* _tmp5_;
		XSAADisplay* _tmp6_;
		XSAAServer* _tmp7_;
		XSAAServer* _tmp8_;
		_tmp5_ = xsaa_display_new (cmd, self->priv->number, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch14_g_error;
			goto __finally14;
		}
		_tmp6_ = NULL;
		self->priv->display = (_tmp6_ = _tmp5_, (self->priv->display == NULL) ? NULL : (self->priv->display = (g_object_unref (self->priv->display), NULL)), _tmp6_);
		g_signal_connect_object (self->priv->display, "ready", (GCallback) _xsaa_daemon_on_display_ready_xsaa_display_ready, self, 0);
		g_signal_connect_object (self->priv->display, "died", (GCallback) _xsaa_daemon_on_display_exit_xsaa_display_died, self, 0);
		g_signal_connect_object (self->priv->display, "exited", (GCallback) _xsaa_daemon_on_display_exit_xsaa_display_exited, self, 0);
		_tmp7_ = xsaa_server_new (socket_name, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch14_g_error;
			goto __finally14;
		}
		_tmp8_ = NULL;
		self->priv->socket = (_tmp8_ = _tmp7_, (self->priv->socket == NULL) ? NULL : (self->priv->socket = (g_object_unref (self->priv->socket), NULL)), _tmp8_);
		g_signal_connect_object (self->priv->socket, "dbus", (GCallback) _xsaa_daemon_on_dbus_ready_xsaa_server_dbus, self, 0);
		g_signal_connect_object (self->priv->socket, "session", (GCallback) _xsaa_daemon_on_session_ready_xsaa_server_session, self, 0);
		g_signal_connect_object (self->priv->socket, "close-session", (GCallback) _xsaa_daemon_on_init_shutdown_xsaa_server_close_session, self, 0);
		g_signal_connect_object (self->priv->socket, "quit", (GCallback) _xsaa_daemon_on_quit_xsaa_server_quit, self, 0);
	}
	goto __finally14;
	__catch14_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			GError* _tmp9_;
			g_object_unref ((GObject*) self);
			_tmp9_ = NULL;
			_inner_error_ = (_tmp9_ = err, (_tmp9_ == NULL) ? ((gpointer) _tmp9_) : g_error_copy (_tmp9_));
			if (_inner_error_ != NULL) {
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
				cmd = (g_free (cmd), NULL);
				goto __finally14;
			}
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally14:
	if (_inner_error_ != NULL) {
		g_propagate_error (error, _inner_error_);
		cmd = (g_free (cmd), NULL);
		return;
	}
	cmd = (g_free (cmd), NULL);
	return self;
}


XSAADaemon* xsaa_daemon_new (const char* socket_name, GError** error) {
	return xsaa_daemon_construct (XSAA_TYPE_DAEMON, socket_name, error);
}


static void xsaa_daemon_load_config (XSAADaemon* self) {
	GError * _inner_error_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	if (g_file_test (PACKAGE_CONFIG_FILE, G_FILE_TEST_EXISTS)) {
		{
			GKeyFile* config;
			gboolean _tmp0_;
			char* _tmp1_;
			char* _tmp2_;
			gint _tmp3_;
			char* _tmp4_;
			char* _tmp5_;
			char* _tmp6_;
			char* _tmp7_;
			char* _tmp8_;
			char* _tmp9_;
			config = g_key_file_new ();
			g_key_file_load_from_file (config, PACKAGE_CONFIG_FILE, G_KEY_FILE_NONE, &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			_tmp0_ = g_key_file_get_boolean (config, "general", "enable", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			self->priv->enable = _tmp0_;
			_tmp1_ = g_key_file_get_string (config, "display", "server", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			_tmp2_ = NULL;
			self->priv->server = (_tmp2_ = _tmp1_, self->priv->server = (g_free (self->priv->server), NULL), _tmp2_);
			_tmp3_ = g_key_file_get_integer (config, "display", "number", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			self->priv->number = _tmp3_;
			_tmp4_ = g_key_file_get_string (config, "display", "options", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			_tmp5_ = NULL;
			self->priv->options = (_tmp5_ = _tmp4_, self->priv->options = (g_free (self->priv->options), NULL), _tmp5_);
			_tmp6_ = g_key_file_get_string (config, "session", "exec", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			_tmp7_ = NULL;
			self->priv->exec = (_tmp7_ = _tmp6_, self->priv->exec = (g_free (self->priv->exec), NULL), _tmp7_);
			_tmp8_ = g_key_file_get_string (config, "session", "user", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch15_g_error;
				goto __finally15;
			}
			_tmp9_ = NULL;
			self->priv->user = (_tmp9_ = _tmp8_, self->priv->user = (g_free (self->priv->user), NULL), _tmp9_);
			(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
		}
		goto __finally15;
		__catch15_g_error:
		{
			GError * err;
			err = _inner_error_;
			_inner_error_ = NULL;
			{
				fprintf (stderr, "Error on read %s: %s", PACKAGE_CONFIG_FILE, err->message);
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
			}
		}
		__finally15:
		if (_inner_error_ != NULL) {
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return;
		}
	}
}


static void xsaa_daemon_change_to_display_vt (XSAADaemon* self) {
	gint vt;
	g_return_if_fail (self != NULL);
	vt = 0;
	sscanf (self->priv->device, "/dev/tty%i", &vt);
	xsaa_change_vt (vt);
}


static gint _xsaa_on_display_io_error_io_error_handler (Display* display) {
	return xsaa_on_display_io_error (display);
}


static void _xsaa_daemon_on_login_response_xsaa_splash_login (XSAASplash* _sender, const char* username, const char* passwd, gpointer self) {
	xsaa_daemon_on_login_response (self, username, passwd);
}


static void _xsaa_daemon_on_restart_request_xsaa_splash_restart (XSAASplash* _sender, gpointer self) {
	xsaa_daemon_on_restart_request (self);
}


static void _xsaa_daemon_on_shutdown_request_xsaa_splash_shutdown (XSAASplash* _sender, gpointer self) {
	xsaa_daemon_on_shutdown_request (self);
}


static void xsaa_daemon_on_display_ready (XSAADaemon* self) {
	char* _tmp1_;
	char* _tmp0_;
	GdkDisplay* _tmp4_;
	char* _tmp3_;
	char* _tmp2_;
	GdkDisplay* _tmp5_;
	GdkDisplay* display;
	GdkDisplayManager* _tmp6_;
	GdkDisplayManager* manager;
	XSAASplash* _tmp7_;
	g_return_if_fail (self != NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	putenv (_tmp1_ = g_strconcat ("DISPLAY=:", _tmp0_ = g_strdup_printf ("%i", self->priv->number), NULL));
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	gtk_init_check (&self->args_length1, &self->args);
	_tmp4_ = NULL;
	_tmp3_ = NULL;
	_tmp2_ = NULL;
	_tmp5_ = NULL;
	display = (_tmp5_ = (_tmp4_ = gdk_display_open (_tmp3_ = g_strconcat (":", _tmp2_ = g_strdup_printf ("%i", self->priv->number), NULL)), (_tmp4_ == NULL) ? NULL : g_object_ref (_tmp4_)), _tmp3_ = (g_free (_tmp3_), NULL), _tmp2_ = (g_free (_tmp2_), NULL), _tmp5_);
	_tmp6_ = NULL;
	manager = (_tmp6_ = gdk_display_manager_get (), (_tmp6_ == NULL) ? NULL : g_object_ref (_tmp6_));
	gdk_display_manager_set_default_display (manager, display);
	XSetIOErrorHandler (_xsaa_on_display_io_error_io_error_handler);
	_tmp7_ = NULL;
	self->priv->splash = (_tmp7_ = g_object_ref_sink (xsaa_splash_new (self->priv->socket)), (self->priv->splash == NULL) ? NULL : (self->priv->splash = (g_object_unref (self->priv->splash), NULL)), _tmp7_);
	g_signal_connect_object (self->priv->splash, "login", (GCallback) _xsaa_daemon_on_login_response_xsaa_splash_login, self, 0);
	g_signal_connect_object (self->priv->splash, "restart", (GCallback) _xsaa_daemon_on_restart_request_xsaa_splash_restart, self, 0);
	g_signal_connect_object (self->priv->splash, "shutdown", (GCallback) _xsaa_daemon_on_shutdown_request_xsaa_splash_shutdown, self, 0);
	gtk_widget_show ((GtkWidget*) self->priv->splash);
	if (xsaa_shutdown) {
		xsaa_daemon_on_init_shutdown (self);
	} else {
		if (!self->priv->first_start) {
			xsaa_daemon_on_dbus_ready (self);
		}
	}
	(display == NULL) ? NULL : (display = (g_object_unref (display), NULL));
	(manager == NULL) ? NULL : (manager = (g_object_unref (manager), NULL));
}


static void xsaa_daemon_on_session_ready (XSAADaemon* self) {
	g_return_if_fail (self != NULL);
	if (self->priv->session != NULL) {
		gtk_widget_hide ((GtkWidget*) self->priv->splash);
	}
}


static void _xsaa_daemon_on_session_ended_xsaa_session_died (XSAASession* _sender, gpointer self) {
	xsaa_daemon_on_session_ended (self);
}


static void _xsaa_daemon_on_session_ended_xsaa_session_exited (XSAASession* _sender, gpointer self) {
	xsaa_daemon_on_session_ended (self);
}


static void _xsaa_daemon_on_session_info_xsaa_session_info (XSAASession* _sender, const char* msg, gpointer self) {
	xsaa_daemon_on_session_info (self, msg);
}


static void _xsaa_daemon_on_error_msg_xsaa_session_error_msg (XSAASession* _sender, const char* msg, gpointer self) {
	xsaa_daemon_on_error_msg (self, msg);
}


static gboolean xsaa_daemon_open_session (XSAADaemon* self, const char* username, gboolean autologin) {
	gboolean result;
	GError * _inner_error_;
	gboolean ret;
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (username != NULL, FALSE);
	_inner_error_ = NULL;
	ret = FALSE;
	{
		if (self->priv->conn == NULL) {
			DBusGConnection* _tmp0_;
			DBusGConnection* _tmp1_;
			_tmp0_ = dbus_g_bus_get (DBUS_BUS_SYSTEM, &_inner_error_);
			if (_inner_error_ != NULL) {
				goto __catch16_g_error;
				goto __finally16;
			}
			_tmp1_ = NULL;
			self->priv->conn = (_tmp1_ = _tmp0_, (self->priv->conn == NULL) ? NULL : (self->priv->conn = (dbus_g_connection_unref (self->priv->conn), NULL)), _tmp1_);
		}
		if (self->priv->manager == NULL) {
			XSAAManager* _tmp2_;
			_tmp2_ = NULL;
			self->priv->manager = (_tmp2_ = xsaa_manager_dbus_proxy_new (self->priv->conn, "fr.supersonicimagine.XSAA.Manager", "/fr/supersonicimagine/XSAA/Manager"), (self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL)), _tmp2_);
		}
		if (self->priv->session == NULL) {
			char* _tmp5_;
			gboolean _tmp4_;
			char* _tmp3_;
			fprintf (stderr, "Open session\n");
			_tmp5_ = NULL;
			_tmp3_ = NULL;
			if ((_tmp4_ = xsaa_manager_open_session (self->priv->manager, username, self->priv->number, self->priv->device, autologin, &_tmp3_), self->priv->path = (_tmp5_ = _tmp3_, self->priv->path = (g_free (self->priv->path), NULL), _tmp5_), _tmp4_)) {
				XSAASession* _tmp6_;
				_tmp6_ = NULL;
				self->priv->session = (_tmp6_ = xsaa_session_dbus_proxy_new (self->priv->conn, "fr.supersonicimagine.XSAA.Manager.Session", self->priv->path), (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp6_);
				g_signal_connect_object (self->priv->session, "died", (GCallback) _xsaa_daemon_on_session_ended_xsaa_session_died, self, 0);
				g_signal_connect_object (self->priv->session, "exited", (GCallback) _xsaa_daemon_on_session_ended_xsaa_session_exited, self, 0);
				g_signal_connect_object (self->priv->session, "info", (GCallback) _xsaa_daemon_on_session_info_xsaa_session_info, self, 0);
				g_signal_connect_object (self->priv->session, "error-msg", (GCallback) _xsaa_daemon_on_error_msg_xsaa_session_error_msg, self, 0);
				ret = TRUE;
			} else {
				fprintf (stderr, "Error on open session");
			}
		}
	}
	goto __finally16;
	__catch16_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on launch session: %s\n", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally16:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return FALSE;
	}
	result = ret;
	return result;
}


static void _xsaa_daemon_on_authenticated_xsaa_session_authenticated (XSAASession* _sender, gpointer self) {
	xsaa_daemon_on_authenticated (self);
}


static void xsaa_daemon_on_dbus_ready (XSAADaemon* self) {
	char* _tmp0_;
	gboolean _tmp1_;
	g_return_if_fail (self != NULL);
	_tmp0_ = NULL;
	self->priv->device = (_tmp0_ = xsaa_display_get_device (self->priv->display), self->priv->device = (g_free (self->priv->device), NULL), _tmp0_);
	_tmp1_ = FALSE;
	if (self->priv->user == NULL) {
		_tmp1_ = TRUE;
	} else {
		_tmp1_ = g_utf8_strlen (self->priv->user, -1) == 0;
	}
	if (_tmp1_) {
		xsaa_splash_ask_for_login (self->priv->splash);
	} else {
		xsaa_daemon_open_session (self, self->priv->user, TRUE);
		xsaa_session_authenticate (self->priv->session);
		g_signal_connect_object (self->priv->session, "authenticated", (GCallback) _xsaa_daemon_on_authenticated_xsaa_session_authenticated, self, 0);
	}
}


static void xsaa_daemon_on_session_ended (XSAADaemon* self) {
	gboolean _tmp0_;
	XSAASession* _tmp1_;
	g_return_if_fail (self != NULL);
	fprintf (stderr, "Session end\n");
	_tmp0_ = FALSE;
	if (self->priv->manager != NULL) {
		_tmp0_ = self->priv->path != NULL;
	} else {
		_tmp0_ = FALSE;
	}
	if (_tmp0_) {
		xsaa_manager_close_session (self->priv->manager, self->priv->path);
	}
	_tmp1_ = NULL;
	self->priv->session = (_tmp1_ = NULL, (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp1_);
	gtk_widget_show ((GtkWidget*) self->priv->splash);
	xsaa_splash_ask_for_login (self->priv->splash);
}


static void xsaa_daemon_on_init_shutdown (XSAADaemon* self) {
	gboolean _tmp0_;
	gboolean _tmp1_;
	XSAAManager* _tmp3_;
	DBusGConnection* _tmp4_;
	gboolean _tmp5_;
	g_return_if_fail (self != NULL);
	fprintf (stderr, "Init shutdown\n");
	xsaa_daemon_change_to_display_vt (self);
	_tmp0_ = FALSE;
	_tmp1_ = FALSE;
	if (self->priv->manager != NULL) {
		_tmp1_ = self->priv->path != NULL;
	} else {
		_tmp1_ = FALSE;
	}
	if (_tmp1_) {
		_tmp0_ = self->priv->session != NULL;
	} else {
		_tmp0_ = FALSE;
	}
	if (_tmp0_) {
		XSAASession* _tmp2_;
		xsaa_manager_close_session (self->priv->manager, self->priv->path);
		_tmp2_ = NULL;
		self->priv->session = (_tmp2_ = NULL, (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp2_);
	}
	_tmp3_ = NULL;
	self->priv->manager = (_tmp3_ = NULL, (self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL)), _tmp3_);
	_tmp4_ = NULL;
	self->priv->conn = (_tmp4_ = NULL, (self->priv->conn == NULL) ? NULL : (self->priv->conn = (dbus_g_connection_unref (self->priv->conn), NULL)), _tmp4_);
	gtk_widget_show ((GtkWidget*) self->priv->splash);
	xsaa_splash_show_shutdown (self->priv->splash);
	_tmp5_ = FALSE;
	if (!xsaa_shutdown) {
		_tmp5_ = setjmp (self->env) == 0;
	} else {
		_tmp5_ = FALSE;
	}
	if (_tmp5_) {
		xsaa_shutdown = TRUE;
	}
}


static void xsaa_daemon_on_restart_request (XSAADaemon* self) {
	GError * _inner_error_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	{
		XSAAManager* _tmp0_;
		DBusGConnection* _tmp1_;
		g_spawn_command_line_async ("shutdown -r now", &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch17_g_error;
			goto __finally17;
		}
		_tmp0_ = NULL;
		self->priv->manager = (_tmp0_ = NULL, (self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL)), _tmp0_);
		_tmp1_ = NULL;
		self->priv->conn = (_tmp1_ = NULL, (self->priv->conn == NULL) ? NULL : (self->priv->conn = (dbus_g_connection_unref (self->priv->conn), NULL)), _tmp1_);
	}
	goto __finally17;
	__catch17_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on launch shutdown: %s\n", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally17:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	xsaa_splash_show_shutdown (self->priv->splash);
}


static void xsaa_daemon_on_shutdown_request (XSAADaemon* self) {
	GError * _inner_error_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	{
		XSAAManager* _tmp0_;
		DBusGConnection* _tmp1_;
		g_spawn_command_line_async ("shutdown -h now", &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch18_g_error;
			goto __finally18;
		}
		_tmp0_ = NULL;
		self->priv->manager = (_tmp0_ = NULL, (self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL)), _tmp0_);
		_tmp1_ = NULL;
		self->priv->conn = (_tmp1_ = NULL, (self->priv->conn == NULL) ? NULL : (self->priv->conn = (dbus_g_connection_unref (self->priv->conn), NULL)), _tmp1_);
	}
	goto __finally18;
	__catch18_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on launch shutdown: %s\n", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally18:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	xsaa_splash_show_shutdown (self->priv->splash);
}


static void xsaa_daemon_on_display_exit (XSAADaemon* self) {
	g_return_if_fail (self != NULL);
	gtk_main_quit ();
	exit (-1);
}


static void xsaa_daemon_on_quit (XSAADaemon* self) {
	g_return_if_fail (self != NULL);
	gtk_main_quit ();
}


static void xsaa_daemon_on_session_info (XSAADaemon* self, const char* msg) {
	char* _tmp1_;
	char* _tmp2_;
	g_return_if_fail (self != NULL);
	g_return_if_fail (msg != NULL);
	fprintf (stderr, "Info %s\n", msg);
	if (self->priv->session != NULL) {
		XSAASession* _tmp0_;
		xsaa_manager_close_session (self->priv->manager, self->priv->path);
		_tmp0_ = NULL;
		self->priv->session = (_tmp0_ = NULL, (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp0_);
	}
	_tmp1_ = NULL;
	self->priv->user = (_tmp1_ = NULL, self->priv->user = (g_free (self->priv->user), NULL), _tmp1_);
	_tmp2_ = NULL;
	self->priv->pass = (_tmp2_ = NULL, self->priv->pass = (g_free (self->priv->pass), NULL), _tmp2_);
	xsaa_splash_login_message (self->priv->splash, msg);
	xsaa_splash_ask_for_login (self->priv->splash);
}


static void xsaa_daemon_on_error_msg (XSAADaemon* self, const char* msg) {
	char* _tmp1_;
	char* _tmp2_;
	XSAASession* _tmp3_;
	g_return_if_fail (self != NULL);
	g_return_if_fail (msg != NULL);
	fprintf (stderr, "Error msg %s\n", msg);
	if (self->priv->session != NULL) {
		XSAASession* _tmp0_;
		xsaa_manager_close_session (self->priv->manager, self->priv->path);
		_tmp0_ = NULL;
		self->priv->session = (_tmp0_ = NULL, (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp0_);
	}
	_tmp1_ = NULL;
	self->priv->user = (_tmp1_ = NULL, self->priv->user = (g_free (self->priv->user), NULL), _tmp1_);
	_tmp2_ = NULL;
	self->priv->pass = (_tmp2_ = NULL, self->priv->pass = (g_free (self->priv->pass), NULL), _tmp2_);
	xsaa_manager_close_session (self->priv->manager, self->priv->path);
	_tmp3_ = NULL;
	self->priv->session = (_tmp3_ = NULL, (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp3_);
	xsaa_splash_login_message (self->priv->splash, msg);
	xsaa_splash_ask_for_login (self->priv->splash);
}


static void xsaa_daemon_on_authenticated (XSAADaemon* self) {
	g_return_if_fail (self != NULL);
	xsaa_session_launch (self->priv->session, self->priv->exec);
	xsaa_splash_show_launch (self->priv->splash);
}


static void xsaa_daemon_on_login_response (XSAADaemon* self, const char* username, const char* passwd) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (username != NULL);
	g_return_if_fail (passwd != NULL);
	fprintf (stderr, "Open session for %s\n", username);
	if (xsaa_daemon_open_session (self, username, FALSE)) {
		char* _tmp1_;
		const char* _tmp0_;
		char* _tmp3_;
		const char* _tmp2_;
		fprintf (stderr, "Open session for %s\n", username);
		_tmp1_ = NULL;
		_tmp0_ = NULL;
		self->priv->user = (_tmp1_ = (_tmp0_ = username, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_)), self->priv->user = (g_free (self->priv->user), NULL), _tmp1_);
		_tmp3_ = NULL;
		_tmp2_ = NULL;
		self->priv->pass = (_tmp3_ = (_tmp2_ = passwd, (_tmp2_ == NULL) ? NULL : g_strdup (_tmp2_)), self->priv->pass = (g_free (self->priv->pass), NULL), _tmp3_);
		xsaa_session_set_passwd (self->priv->session, self->priv->pass);
		xsaa_session_authenticate (self->priv->session);
		g_signal_connect_object (self->priv->session, "authenticated", (GCallback) _xsaa_daemon_on_authenticated_xsaa_session_authenticated, self, 0);
	} else {
		char* _tmp4_;
		char* _tmp5_;
		_tmp4_ = NULL;
		self->priv->user = (_tmp4_ = NULL, self->priv->user = (g_free (self->priv->user), NULL), _tmp4_);
		_tmp5_ = NULL;
		self->priv->pass = (_tmp5_ = NULL, self->priv->pass = (g_free (self->priv->pass), NULL), _tmp5_);
		xsaa_splash_ask_for_login (self->priv->splash);
	}
}


void xsaa_daemon_run (XSAADaemon* self, gboolean first_start) {
	g_return_if_fail (self != NULL);
	self->priv->first_start = first_start;
	gtk_main ();
}


static void xsaa_daemon_class_init (XSAADaemonClass * klass) {
	xsaa_daemon_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAADaemonPrivate));
	G_OBJECT_CLASS (klass)->finalize = xsaa_daemon_finalize;
}


static void xsaa_daemon_instance_init (XSAADaemon * self) {
	self->priv = XSAA_DAEMON_GET_PRIVATE (self);
	self->priv->enable = TRUE;
	self->priv->first_start = TRUE;
	self->priv->conn = NULL;
	self->priv->manager = NULL;
	self->priv->server = g_strdup ("/usr/bin/Xorg");
	self->priv->number = 0;
	self->priv->device = g_strdup ("/dev/tty1");
	self->priv->options = g_strdup ("");
	self->priv->user = NULL;
	self->priv->pass = NULL;
	self->priv->exec = NULL;
	self->priv->path = NULL;
	self->priv->session = NULL;
}


static void xsaa_daemon_finalize (GObject* obj) {
	XSAADaemon * self;
	self = XSAA_DAEMON (obj);
	{
		gboolean _tmp24_;
		XSAAManager* _tmp26_;
		_tmp24_ = FALSE;
		if (self->priv->manager != NULL) {
			_tmp24_ = self->priv->path != NULL;
		} else {
			_tmp24_ = FALSE;
		}
		if (_tmp24_) {
			XSAASession* _tmp25_;
			xsaa_manager_close_session (self->priv->manager, self->priv->path);
			_tmp25_ = NULL;
			self->priv->session = (_tmp25_ = NULL, (self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL)), _tmp25_);
		}
		_tmp26_ = NULL;
		self->priv->manager = (_tmp26_ = NULL, (self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL)), _tmp26_);
	}
	self->args = (_vala_array_free (self->args, self->args_length1, (GDestroyNotify) g_free), NULL);
	(self->priv->socket == NULL) ? NULL : (self->priv->socket = (g_object_unref (self->priv->socket), NULL));
	(self->priv->splash == NULL) ? NULL : (self->priv->splash = (g_object_unref (self->priv->splash), NULL));
	(self->priv->display == NULL) ? NULL : (self->priv->display = (g_object_unref (self->priv->display), NULL));
	(self->priv->conn == NULL) ? NULL : (self->priv->conn = (dbus_g_connection_unref (self->priv->conn), NULL));
	(self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL));
	self->priv->server = (g_free (self->priv->server), NULL);
	self->priv->device = (g_free (self->priv->device), NULL);
	self->priv->options = (g_free (self->priv->options), NULL);
	self->priv->user = (g_free (self->priv->user), NULL);
	self->priv->pass = (g_free (self->priv->pass), NULL);
	self->priv->exec = (g_free (self->priv->exec), NULL);
	self->priv->path = (g_free (self->priv->path), NULL);
	(self->priv->session == NULL) ? NULL : (self->priv->session = (g_object_unref (self->priv->session), NULL));
	G_OBJECT_CLASS (xsaa_daemon_parent_class)->finalize (obj);
}


GType xsaa_daemon_get_type (void) {
	static GType xsaa_daemon_type_id = 0;
	if (xsaa_daemon_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAADaemonClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_daemon_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAADaemon), 0, (GInstanceInitFunc) xsaa_daemon_instance_init, NULL };
		xsaa_daemon_type_id = g_type_register_static (G_TYPE_OBJECT, "XSAADaemon", &g_define_type_info, 0);
	}
	return xsaa_daemon_type_id;
}


void xsaa_change_vt (gint vt) {
	gint fd;
	gint rc;
	char* _tmp1_;
	char* _tmp0_;
	fd = 0;
	rc = 0;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	fd = open (_tmp1_ = g_strconcat ("/dev/tty", _tmp0_ = g_strdup_printf ("%i", vt), NULL), O_WRONLY | O_NOCTTY, (mode_t) 0);
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	if (fd > 0) {
		rc = ioctl (fd, VT_ACTIVATE, vt);
		rc = ioctl (fd, VT_WAITACTIVE, vt);
		close (fd);
	}
}


gint xsaa_on_display_io_error (Display* display) {
	gint result;
	XSAADaemon* _tmp0_;
	g_return_val_if_fail (display != NULL, 0);
	fprintf (stderr, "DISPLAY Error\n");
	_tmp0_ = NULL;
	xsaa_daemon = (_tmp0_ = NULL, (xsaa_daemon == NULL) ? NULL : (xsaa_daemon = (g_object_unref (xsaa_daemon), NULL)), _tmp0_);
	result = -1;
	return result;
}


void xsaa_on_sig_term (gint signum) {
	gboolean _tmp0_;
	_tmp0_ = FALSE;
	if (xsaa_shutdown) {
		_tmp0_ = xsaa_daemon != NULL;
	} else {
		_tmp0_ = FALSE;
	}
	if (_tmp0_) {
		longjmp (xsaa_daemon->env, 1);
	} else {
		exit (-1);
	}
}


static void _xsaa_on_sig_term_sighandler_t (gint signal) {
	xsaa_on_sig_term (signal);
}


static char** _vala_array_dup1 (char** self, int length) {
	char** result;
	int i;
	const char* _tmp2_;
	result = g_new0 (char*, length);
	for (i = 0; i < length; i++) {
		result[i] = (_tmp2_ = self[i], (_tmp2_ == NULL) ? NULL : g_strdup (_tmp2_));
	}
	return result;
}


gint xsaa_main (char** args, int args_length1) {
	gint result;
	GError * _inner_error_;
	pid_t pid;
	pid_t ppgid;
	gint status;
	gboolean first_start;
	_inner_error_ = NULL;
	pid = 0;
	ppgid = 0;
	pid = getpid ();
	ppgid = getpgid (pid);
	setsid ();
	setpgid ((pid_t) 0, ppgid);
	signal (SIGTERM, SIG_IGN);
	signal (SIGKILL, SIG_IGN);
	status = -1;
	first_start = TRUE;
	while (TRUE) {
		if (!(status != 0)) {
			break;
		}
		switch (fork ()) {
			case 0:
			{
				{
					XSAADaemon* _tmp0_;
					XSAADaemon* _tmp1_;
					char** _tmp4_;
					char** _tmp3_;
					const char* _tmp2_;
					XSAADaemon* _tmp5_;
					signal (SIGSEGV, _xsaa_on_sig_term_sighandler_t);
					signal (SIGTERM, _xsaa_on_sig_term_sighandler_t);
					signal (SIGKILL, _xsaa_on_sig_term_sighandler_t);
					_tmp0_ = xsaa_daemon_new (XSAA_SOCKET_NAME, &_inner_error_);
					if (_inner_error_ != NULL) {
						goto __catch19_g_error;
						goto __finally19;
					}
					_tmp1_ = NULL;
					xsaa_daemon = (_tmp1_ = _tmp0_, (xsaa_daemon == NULL) ? NULL : (xsaa_daemon = (g_object_unref (xsaa_daemon), NULL)), _tmp1_);
					_tmp4_ = NULL;
					_tmp3_ = NULL;
					_tmp2_ = NULL;
					xsaa_daemon->args = (_tmp4_ = (_tmp3_ = args, (_tmp3_ == NULL) ? ((gpointer) _tmp3_) : _vala_array_dup1 (_tmp3_, args_length1)), xsaa_daemon->args = (_vala_array_free (xsaa_daemon->args, xsaa_daemon->args_length1, (GDestroyNotify) g_free), NULL), xsaa_daemon->args_length1 = args_length1, _tmp4_);
					xsaa_daemon_run (xsaa_daemon, first_start);
					_tmp5_ = NULL;
					xsaa_daemon = (_tmp5_ = NULL, (xsaa_daemon == NULL) ? NULL : (xsaa_daemon = (g_object_unref (xsaa_daemon), NULL)), _tmp5_);
				}
				goto __finally19;
				__catch19_g_error:
				{
					GError * err;
					err = _inner_error_;
					_inner_error_ = NULL;
					{
						XSAADaemon* _tmp6_;
						fprintf (stderr, "%s\n", err->message);
						_tmp6_ = NULL;
						xsaa_daemon = (_tmp6_ = NULL, (xsaa_daemon == NULL) ? NULL : (xsaa_daemon = (g_object_unref (xsaa_daemon), NULL)), _tmp6_);
						result = -1;
						(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
						return result;
					}
				}
				__finally19:
				if (_inner_error_ != NULL) {
					g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
					g_clear_error (&_inner_error_);
					return 0;
				}
				result = 0;
				return result;
			}
			case -1:
			{
				result = -1;
				return result;
			}
			default:
			{
				gint ret;
				ret = 0;
				first_start = FALSE;
				wait (&ret);
				status = WEXITSTATUS (ret);
				break;
			}
		}
	}
	result = 0;
	return result;
}


int main (int argc, char ** argv) {
	g_type_init ();
	return xsaa_main (argv, argc);
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




