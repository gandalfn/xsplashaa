/* xsaa-session-daemon.vala
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
#include <gee.h>
#include <stdio.h>
#include <unistd.h>
#include <dbus/dbus.h>


#define CONSOLE_KIT_TYPE_SESSION (console_kit_session_get_type ())
#define CONSOLE_KIT_SESSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), CONSOLE_KIT_TYPE_SESSION, ConsoleKitSession))
#define CONSOLE_KIT_IS_SESSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CONSOLE_KIT_TYPE_SESSION))
#define CONSOLE_KIT_SESSION_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), CONSOLE_KIT_TYPE_SESSION, ConsoleKitSessionIface))

typedef struct _ConsoleKitSession ConsoleKitSession;
typedef struct _ConsoleKitSessionIface ConsoleKitSessionIface;
typedef DBusGProxy ConsoleKitSessionDBusProxy;
typedef DBusGProxyClass ConsoleKitSessionDBusProxyClass;

#define CONSOLE_KIT_TYPE_MANAGER (console_kit_manager_get_type ())
#define CONSOLE_KIT_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), CONSOLE_KIT_TYPE_MANAGER, ConsoleKitManager))
#define CONSOLE_KIT_IS_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CONSOLE_KIT_TYPE_MANAGER))
#define CONSOLE_KIT_MANAGER_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), CONSOLE_KIT_TYPE_MANAGER, ConsoleKitManagerIface))

typedef struct _ConsoleKitManager ConsoleKitManager;
typedef struct _ConsoleKitManagerIface ConsoleKitManagerIface;

#define CONSOLE_KIT_TYPE_SESSION_PARAMETER (console_kit_session_parameter_get_type ())
typedef struct _ConsoleKitSessionParameter ConsoleKitSessionParameter;
typedef DBusGProxy ConsoleKitManagerDBusProxy;
typedef DBusGProxyClass ConsoleKitManagerDBusProxyClass;

#define SETTINGS_DAEMON_TYPE_MANAGER (settings_daemon_manager_get_type ())
#define SETTINGS_DAEMON_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), SETTINGS_DAEMON_TYPE_MANAGER, SettingsDaemonManager))
#define SETTINGS_DAEMON_IS_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), SETTINGS_DAEMON_TYPE_MANAGER))
#define SETTINGS_DAEMON_MANAGER_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), SETTINGS_DAEMON_TYPE_MANAGER, SettingsDaemonManagerIface))

typedef struct _SettingsDaemonManager SettingsDaemonManager;
typedef struct _SettingsDaemonManagerIface SettingsDaemonManagerIface;
typedef DBusGProxy SettingsDaemonManagerDBusProxy;
typedef DBusGProxyClass SettingsDaemonManagerDBusProxyClass;

#define XSAA_TYPE_SESSION_MANAGER (xsaa_session_manager_get_type ())
#define XSAA_SESSION_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SESSION_MANAGER, XSAASessionManager))
#define XSAA_SESSION_MANAGER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SESSION_MANAGER, XSAASessionManagerClass))
#define XSAA_IS_SESSION_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SESSION_MANAGER))
#define XSAA_IS_SESSION_MANAGER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SESSION_MANAGER))
#define XSAA_SESSION_MANAGER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SESSION_MANAGER, XSAASessionManagerClass))

typedef struct _XSAASessionManager XSAASessionManager;
typedef struct _XSAASessionManagerClass XSAASessionManagerClass;
typedef struct _XSAASessionManagerPrivate XSAASessionManagerPrivate;

#define XSAA_TYPE_SESSION (xsaa_session_get_type ())
#define XSAA_SESSION(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SESSION, XSAASession))
#define XSAA_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SESSION, XSAASessionClass))
#define XSAA_IS_SESSION(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SESSION))
#define XSAA_IS_SESSION_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SESSION))
#define XSAA_SESSION_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SESSION, XSAASessionClass))

typedef struct _XSAASession XSAASession;
typedef struct _XSAASessionClass XSAASessionClass;
typedef struct _DBusObjectVTable _DBusObjectVTable;

struct _ConsoleKitSessionIface {
	GTypeInterface parent_iface;
	void (*activate) (ConsoleKitSession* self);
};

struct _ConsoleKitSessionParameter {
	char* key;
	GValue* value;
};

struct _ConsoleKitManagerIface {
	GTypeInterface parent_iface;
	char* (*open_session_with_parameters) (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1);
	gint (*close_session) (ConsoleKitManager* self, const char* cookie);
	char* (*get_session_for_cookie) (ConsoleKitManager* self, const char* cookie);
	void (*restart) (ConsoleKitManager* self);
	void (*stop) (ConsoleKitManager* self);
};

struct _SettingsDaemonManagerIface {
	GTypeInterface parent_iface;
};

struct _XSAASessionManager {
	GObject parent_instance;
	XSAASessionManagerPrivate * priv;
	GeeMap* sessions;
};

struct _XSAASessionManagerClass {
	GObjectClass parent_class;
};

struct _XSAASessionManagerPrivate {
	DBusGConnection* connection;
	ConsoleKitManager* manager;
};

typedef enum  {
	XSAA_SESSION_ERROR_COMMAND,
	XSAA_SESSION_ERROR_LAUNCH,
	XSAA_SESSION_ERROR_USER,
	XSAA_SESSION_ERROR_XAUTH
} XSAASessionError;
#define XSAA_SESSION_ERROR xsaa_session_error_quark ()
struct _DBusObjectVTable {
	void (*register_object) (DBusConnection*, const char*, void*);
};



#define PACKAGE_XAUTH_DIR "/tmp/xsplashaa-xauth"
GType console_kit_session_get_type (void);
void console_kit_session_activate (ConsoleKitSession* self);
void console_kit_session_dbus_register_object (DBusConnection* connection, const char* path, void* object);
void _console_kit_session_dbus_unregister (DBusConnection* connection, void* user_data);
DBusHandlerResult console_kit_session_dbus_message (DBusConnection* connection, DBusMessage* message, void* object);
static DBusMessage* _dbus_console_kit_session_introspect (ConsoleKitSession* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_session_property_get_all (ConsoleKitSession* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_session_activate (ConsoleKitSession* self, DBusConnection* connection, DBusMessage* message);
ConsoleKitSession* console_kit_session_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path);
DBusHandlerResult console_kit_session_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data);
static void console_kit_session_dbus_proxy_activate (ConsoleKitSession* self);
static void console_kit_session_dbus_proxy_interface_init (ConsoleKitSessionIface* iface);
GType console_kit_session_parameter_get_type (void);
ConsoleKitSessionParameter* console_kit_session_parameter_dup (const ConsoleKitSessionParameter* self);
void console_kit_session_parameter_free (ConsoleKitSessionParameter* self);
void console_kit_session_parameter_copy (const ConsoleKitSessionParameter* self, ConsoleKitSessionParameter* dest);
void console_kit_session_parameter_destroy (ConsoleKitSessionParameter* self);
GType console_kit_manager_get_type (void);
char* console_kit_manager_open_session_with_parameters (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1);
gint console_kit_manager_close_session (ConsoleKitManager* self, const char* cookie);
char* console_kit_manager_get_session_for_cookie (ConsoleKitManager* self, const char* cookie);
void console_kit_manager_restart (ConsoleKitManager* self);
void console_kit_manager_stop (ConsoleKitManager* self);
void console_kit_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object);
void _console_kit_manager_dbus_unregister (DBusConnection* connection, void* user_data);
DBusHandlerResult console_kit_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object);
static DBusMessage* _dbus_console_kit_manager_introspect (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_manager_property_get_all (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_manager_open_session_with_parameters (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_manager_close_session (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_manager_get_session_for_cookie (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_manager_restart (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_console_kit_manager_stop (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message);
ConsoleKitManager* console_kit_manager_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path);
DBusHandlerResult console_kit_manager_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data);
static char* console_kit_manager_dbus_proxy_open_session_with_parameters (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1);
static gint console_kit_manager_dbus_proxy_close_session (ConsoleKitManager* self, const char* cookie);
static char* console_kit_manager_dbus_proxy_get_session_for_cookie (ConsoleKitManager* self, const char* cookie);
static void console_kit_manager_dbus_proxy_restart (ConsoleKitManager* self);
static void console_kit_manager_dbus_proxy_stop (ConsoleKitManager* self);
static void console_kit_manager_dbus_proxy_interface_init (ConsoleKitManagerIface* iface);
GType settings_daemon_manager_get_type (void);
void settings_daemon_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object);
void _settings_daemon_manager_dbus_unregister (DBusConnection* connection, void* user_data);
DBusHandlerResult settings_daemon_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object);
static DBusMessage* _dbus_settings_daemon_manager_introspect (SettingsDaemonManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_settings_daemon_manager_property_get_all (SettingsDaemonManager* self, DBusConnection* connection, DBusMessage* message);
SettingsDaemonManager* settings_daemon_manager_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path);
DBusHandlerResult settings_daemon_manager_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data);
static void settings_daemon_manager_dbus_proxy_interface_init (SettingsDaemonManagerIface* iface);
extern GMainLoop* xsaa_loop;
GMainLoop* xsaa_loop = NULL;
GType xsaa_session_manager_get_type (void);
GType xsaa_session_get_type (void);
#define XSAA_SESSION_MANAGER_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_SESSION_MANAGER, XSAASessionManagerPrivate))
enum  {
	XSAA_SESSION_MANAGER_DUMMY_PROPERTY
};
XSAASessionManager* xsaa_session_manager_new (DBusGConnection* conn);
XSAASessionManager* xsaa_session_manager_construct (GType object_type, DBusGConnection* conn);
XSAASessionManager* xsaa_session_manager_new (DBusGConnection* conn);
GQuark xsaa_session_error_quark (void);
XSAASession* xsaa_session_new (DBusGConnection* conn, ConsoleKitManager* manager, const char* service, const char* user, gint display, const char* device, GError** error);
XSAASession* xsaa_session_construct (GType object_type, DBusGConnection* conn, ConsoleKitManager* manager, const char* service, const char* user, gint display, const char* device, GError** error);
gboolean xsaa_session_manager_open_session (XSAASessionManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path);
void xsaa_session_manager_close_session (XSAASessionManager* self, const char* path);
void xsaa_session_manager_reboot (XSAASessionManager* self);
void xsaa_session_manager_halt (XSAASessionManager* self);
static gpointer xsaa_session_manager_parent_class = NULL;
void xsaa_session_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object);
void _xsaa_session_manager_dbus_unregister (DBusConnection* connection, void* user_data);
DBusHandlerResult xsaa_session_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object);
static DBusMessage* _dbus_xsaa_session_manager_introspect (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_manager_property_get_all (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_manager_open_session (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_manager_close_session (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_manager_reboot (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message);
static DBusMessage* _dbus_xsaa_session_manager_halt (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message);
static void xsaa_session_manager_finalize (GObject* obj);
extern gboolean xsaa_no_daemon;
gboolean xsaa_no_daemon = FALSE;
guint _dynamic_request_name0 (DBusGProxy* self, const char* param1, guint param2, GError** error);
guint _dynamic_request_name1 (DBusGProxy* self, const char* param1, guint param2, GError** error);
gint xsaa_main (char** args, int args_length1);
static void _vala_dbus_register_object (DBusConnection* connection, const char* path, void* object);
static void _vala_dbus_unregister_object (gpointer connection, GObject* object);

static const DBusObjectPathVTable _console_kit_session_dbus_path_vtable = {_console_kit_session_dbus_unregister, console_kit_session_dbus_message};
static const _DBusObjectVTable _console_kit_session_dbus_vtable = {console_kit_session_dbus_register_object};
static const DBusObjectPathVTable _console_kit_manager_dbus_path_vtable = {_console_kit_manager_dbus_unregister, console_kit_manager_dbus_message};
static const _DBusObjectVTable _console_kit_manager_dbus_vtable = {console_kit_manager_dbus_register_object};
static const DBusObjectPathVTable _settings_daemon_manager_dbus_path_vtable = {_settings_daemon_manager_dbus_unregister, settings_daemon_manager_dbus_message};
static const _DBusObjectVTable _settings_daemon_manager_dbus_vtable = {settings_daemon_manager_dbus_register_object};
static const DBusObjectPathVTable _xsaa_session_manager_dbus_path_vtable = {_xsaa_session_manager_dbus_unregister, xsaa_session_manager_dbus_message};
static const _DBusObjectVTable _xsaa_session_manager_dbus_vtable = {xsaa_session_manager_dbus_register_object};
static const GOptionEntry XSAA_option_entries[] = {{"no-daemonize", 'd', 0, G_OPTION_ARG_NONE, &xsaa_no_daemon, "Do not run xsplashaa-session-daemon as a daemonn", NULL}, {NULL}};


void console_kit_session_activate (ConsoleKitSession* self) {
	CONSOLE_KIT_SESSION_GET_INTERFACE (self)->activate (self);
}


void _console_kit_session_dbus_unregister (DBusConnection* connection, void* user_data) {
}


static DBusMessage* _dbus_console_kit_session_introspect (ConsoleKitSession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter;
	GString* xml_data;
	char** children;
	int i;
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	xml_data = g_string_new ("<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\" \"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">\n");
	g_string_append (xml_data, "<node>\n<interface name=\"org.freedesktop.DBus.Introspectable\">\n  <method name=\"Introspect\">\n    <arg name=\"data\" direction=\"out\" type=\"s\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.DBus.Properties\">\n  <method name=\"Get\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"out\" type=\"v\"/>\n  </method>\n  <method name=\"Set\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"in\" type=\"v\"/>\n  </method>\n  <method name=\"GetAll\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"props\" direction=\"out\" type=\"a{sv}\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.ConsoleKit.Session\">\n  <method name=\"Activate\">\n  </method>\n</interface>\n");
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


static DBusMessage* _dbus_console_kit_session_property_get_all (ConsoleKitSession* self, DBusConnection* connection, DBusMessage* message) {
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
	if (strcmp (interface_name, "org.freedesktop.ConsoleKit.Session") == 0) {
		dbus_message_iter_open_container (&reply_iter, DBUS_TYPE_ARRAY, "{sv}", &subiter);
		dbus_message_iter_close_container (&reply_iter, &subiter);
	} else {
		return NULL;
	}
	return reply;
}


static DBusMessage* _dbus_console_kit_session_activate (ConsoleKitSession* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	console_kit_session_activate (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


DBusHandlerResult console_kit_session_dbus_message (DBusConnection* connection, DBusMessage* message, void* object) {
	DBusMessage* reply;
	reply = NULL;
	if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Introspectable", "Introspect")) {
		reply = _dbus_console_kit_session_introspect (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Properties", "GetAll")) {
		reply = _dbus_console_kit_session_property_get_all (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.ConsoleKit.Session", "Activate")) {
		reply = _dbus_console_kit_session_activate (object, connection, message);
	}
	if (reply) {
		dbus_connection_send (connection, reply, NULL);
		dbus_message_unref (reply);
		return DBUS_HANDLER_RESULT_HANDLED;
	} else {
		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
	}
}


void console_kit_session_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	if (!g_object_get_data (object, "dbus_object_path")) {
		g_object_set_data (object, "dbus_object_path", g_strdup (path));
		dbus_connection_register_object_path (connection, path, &_console_kit_session_dbus_path_vtable, object);
		g_object_weak_ref (object, _vala_dbus_unregister_object, connection);
	}
}


static void console_kit_session_base_init (ConsoleKitSessionIface * iface) {
	static gboolean initialized = FALSE;
	if (!initialized) {
		initialized = TRUE;
		g_type_set_qdata (CONSOLE_KIT_TYPE_SESSION, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_console_kit_session_dbus_vtable));
	}
}


GType console_kit_session_get_type (void) {
	static GType console_kit_session_type_id = 0;
	if (console_kit_session_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (ConsoleKitSessionIface), (GBaseInitFunc) console_kit_session_base_init, (GBaseFinalizeFunc) NULL, (GClassInitFunc) NULL, (GClassFinalizeFunc) NULL, NULL, 0, 0, (GInstanceInitFunc) NULL, NULL };
		console_kit_session_type_id = g_type_register_static (G_TYPE_INTERFACE, "ConsoleKitSession", &g_define_type_info, 0);
		g_type_interface_add_prerequisite (console_kit_session_type_id, DBUS_TYPE_G_PROXY);
	}
	return console_kit_session_type_id;
}


G_DEFINE_TYPE_EXTENDED (ConsoleKitSessionDBusProxy, console_kit_session_dbus_proxy, DBUS_TYPE_G_PROXY, 0, G_IMPLEMENT_INTERFACE (CONSOLE_KIT_TYPE_SESSION, console_kit_session_dbus_proxy_interface_init));
ConsoleKitSession* console_kit_session_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path) {
	ConsoleKitSession* self;
	char* filter;
	self = g_object_new (console_kit_session_dbus_proxy_get_type (), "connection", connection, "name", name, "path", path, "interface", "org.freedesktop.ConsoleKit.Session", NULL);
	dbus_connection_add_filter (dbus_g_connection_get_connection (connection), console_kit_session_dbus_proxy_filter, self, NULL);
	filter = g_strdup_printf ("type='signal',path='%s'", path);
	dbus_bus_add_match (dbus_g_connection_get_connection (connection), filter, NULL);
	g_free (filter);
	return self;
}


DBusHandlerResult console_kit_session_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data) {
	if (dbus_message_has_path (message, dbus_g_proxy_get_path (user_data))) {
	}
	return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}


static void console_kit_session_dbus_proxy_dispose (GObject* self) {
	DBusGConnection *connection;
	g_object_get (self, "connection", &connection, NULL);
	dbus_connection_remove_filter (dbus_g_connection_get_connection (connection), console_kit_session_dbus_proxy_filter, self);
	G_OBJECT_CLASS (console_kit_session_dbus_proxy_parent_class)->dispose (self);
}


static void console_kit_session_dbus_proxy_class_init (ConsoleKitSessionDBusProxyClass* klass) {
	G_OBJECT_CLASS (klass)->dispose = console_kit_session_dbus_proxy_dispose;
}


static void console_kit_session_dbus_proxy_init (ConsoleKitSessionDBusProxy* self) {
}


static void console_kit_session_dbus_proxy_activate (ConsoleKitSession* self) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "org.freedesktop.ConsoleKit.Session", "Activate");
	dbus_message_iter_init_append (_message, &_iter);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void console_kit_session_dbus_proxy_interface_init (ConsoleKitSessionIface* iface) {
	iface->activate = console_kit_session_dbus_proxy_activate;
}


char* console_kit_manager_open_session_with_parameters (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1) {
	return CONSOLE_KIT_MANAGER_GET_INTERFACE (self)->open_session_with_parameters (self, parameters, parameters_length1);
}


gint console_kit_manager_close_session (ConsoleKitManager* self, const char* cookie) {
	return CONSOLE_KIT_MANAGER_GET_INTERFACE (self)->close_session (self, cookie);
}


char* console_kit_manager_get_session_for_cookie (ConsoleKitManager* self, const char* cookie) {
	return CONSOLE_KIT_MANAGER_GET_INTERFACE (self)->get_session_for_cookie (self, cookie);
}


void console_kit_manager_restart (ConsoleKitManager* self) {
	CONSOLE_KIT_MANAGER_GET_INTERFACE (self)->restart (self);
}


void console_kit_manager_stop (ConsoleKitManager* self) {
	CONSOLE_KIT_MANAGER_GET_INTERFACE (self)->stop (self);
}


void _console_kit_manager_dbus_unregister (DBusConnection* connection, void* user_data) {
}


static DBusMessage* _dbus_console_kit_manager_introspect (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter;
	GString* xml_data;
	char** children;
	int i;
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	xml_data = g_string_new ("<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\" \"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">\n");
	g_string_append (xml_data, "<node>\n<interface name=\"org.freedesktop.DBus.Introspectable\">\n  <method name=\"Introspect\">\n    <arg name=\"data\" direction=\"out\" type=\"s\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.DBus.Properties\">\n  <method name=\"Get\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"out\" type=\"v\"/>\n  </method>\n  <method name=\"Set\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"in\" type=\"v\"/>\n  </method>\n  <method name=\"GetAll\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"props\" direction=\"out\" type=\"a{sv}\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.ConsoleKit.Manager\">\n  <method name=\"OpenSessionWithParameters\">\n    <arg name=\"parameters\" type=\"a(sv)\" direction=\"in\"/>\n    <arg name=\"result\" type=\"s\" direction=\"out\"/>\n  </method>\n  <method name=\"CloseSession\">\n    <arg name=\"cookie\" type=\"s\" direction=\"in\"/>\n    <arg name=\"result\" type=\"i\" direction=\"out\"/>\n  </method>\n  <method name=\"GetSessionForCookie\">\n    <arg name=\"cookie\" type=\"s\" direction=\"in\"/>\n    <arg name=\"result\" type=\"o\" direction=\"out\"/>\n  </method>\n  <method name=\"Restart\">\n  </method>\n  <method name=\"Stop\">\n  </method>\n</interface>\n");
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


static DBusMessage* _dbus_console_kit_manager_property_get_all (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter, reply_iter, subiter;
	char* interface_name;
	const char* _tmp1_;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &reply_iter);
	dbus_message_iter_get_basic (&iter, &_tmp1_);
	dbus_message_iter_next (&iter);
	interface_name = g_strdup (_tmp1_);
	if (strcmp (interface_name, "org.freedesktop.ConsoleKit.Manager") == 0) {
		dbus_message_iter_open_container (&reply_iter, DBUS_TYPE_ARRAY, "{sv}", &subiter);
		dbus_message_iter_close_container (&reply_iter, &subiter);
	} else {
		return NULL;
	}
	return reply;
}


static DBusMessage* _dbus_console_kit_manager_open_session_with_parameters (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	ConsoleKitSessionParameter* parameters;
	int parameters_length1;
	ConsoleKitSessionParameter* _tmp2_;
	int _tmp2__length;
	int _tmp2__size;
	int _tmp2__length1;
	DBusMessageIter _tmp3_;
	char* result;
	DBusMessage* reply;
	const char* _tmp21_;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "a(sv)")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	parameters = NULL;
	parameters_length1 = 0;
	_tmp2_ = g_new (ConsoleKitSessionParameter, 5);
	_tmp2__length = 0;
	_tmp2__size = 4;
	_tmp2__length1 = 0;
	dbus_message_iter_recurse (&iter, &_tmp3_);
	for (; dbus_message_iter_get_arg_type (&_tmp3_); _tmp2__length1++) {
		ConsoleKitSessionParameter _tmp4_;
		DBusMessageIter _tmp5_;
		const char* _tmp6_;
		GValue _tmp7_ = {0};
		DBusMessageIter _tmp8_;
		if (_tmp2__size == _tmp2__length) {
			_tmp2__size = 2 * _tmp2__size;
			_tmp2_ = g_renew (ConsoleKitSessionParameter, _tmp2_, _tmp2__size + 1);
		}
		dbus_message_iter_recurse (&_tmp3_, &_tmp5_);
		dbus_message_iter_get_basic (&_tmp5_, &_tmp6_);
		dbus_message_iter_next (&_tmp5_);
		_tmp4_.key = g_strdup (_tmp6_);
		dbus_message_iter_recurse (&_tmp5_, &_tmp8_);
		if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_BYTE) {
			guint8 _tmp9_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp9_);
			g_value_init (&_tmp7_, G_TYPE_UCHAR);
			g_value_set_uchar (&_tmp7_, _tmp9_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_BOOLEAN) {
			dbus_bool_t _tmp10_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp10_);
			g_value_init (&_tmp7_, G_TYPE_BOOLEAN);
			g_value_set_boolean (&_tmp7_, _tmp10_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_INT16) {
			dbus_int16_t _tmp11_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp11_);
			g_value_init (&_tmp7_, G_TYPE_INT);
			g_value_set_int (&_tmp7_, _tmp11_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_UINT16) {
			dbus_uint16_t _tmp12_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp12_);
			g_value_init (&_tmp7_, G_TYPE_UINT);
			g_value_set_uint (&_tmp7_, _tmp12_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_INT32) {
			dbus_int32_t _tmp13_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp13_);
			g_value_init (&_tmp7_, G_TYPE_INT);
			g_value_set_int (&_tmp7_, _tmp13_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_UINT32) {
			dbus_uint32_t _tmp14_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp14_);
			g_value_init (&_tmp7_, G_TYPE_UINT);
			g_value_set_uint (&_tmp7_, _tmp14_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_INT64) {
			dbus_int64_t _tmp15_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp15_);
			g_value_init (&_tmp7_, G_TYPE_INT64);
			g_value_set_int64 (&_tmp7_, _tmp15_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_UINT64) {
			dbus_uint64_t _tmp16_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp16_);
			g_value_init (&_tmp7_, G_TYPE_UINT64);
			g_value_set_uint64 (&_tmp7_, _tmp16_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_DOUBLE) {
			double _tmp17_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp17_);
			g_value_init (&_tmp7_, G_TYPE_DOUBLE);
			g_value_set_double (&_tmp7_, _tmp17_);
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_STRING) {
			const char* _tmp18_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp18_);
			g_value_init (&_tmp7_, G_TYPE_STRING);
			g_value_take_string (&_tmp7_, g_strdup (_tmp18_));
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_OBJECT_PATH) {
			const char* _tmp19_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp19_);
			g_value_init (&_tmp7_, G_TYPE_STRING);
			g_value_take_string (&_tmp7_, g_strdup (_tmp19_));
		} else if (dbus_message_iter_get_arg_type (&_tmp8_) == DBUS_TYPE_SIGNATURE) {
			const char* _tmp20_;
			dbus_message_iter_get_basic (&_tmp8_, &_tmp20_);
			g_value_init (&_tmp7_, G_TYPE_STRING);
			g_value_take_string (&_tmp7_, g_strdup (_tmp20_));
		}
		dbus_message_iter_next (&_tmp5_);
		_tmp4_.value = g_memdup (&_tmp7_, sizeof (GValue));
		dbus_message_iter_next (&_tmp3_);
		_tmp2_[_tmp2__length++] = _tmp4_;
	}
	parameters_length1 = _tmp2__length1;
	dbus_message_iter_next (&iter);
	parameters = _tmp2_;
	result = console_kit_manager_open_session_with_parameters (self, parameters, parameters_length1);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	_tmp21_ = result;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_STRING, &_tmp21_);
	return reply;
}


static DBusMessage* _dbus_console_kit_manager_close_session (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	const char* cookie;
	const char* _tmp22_;
	gint result;
	DBusMessage* reply;
	dbus_int32_t _tmp23_;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	cookie = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp22_);
	dbus_message_iter_next (&iter);
	cookie = g_strdup (_tmp22_);
	result = console_kit_manager_close_session (self, cookie);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	_tmp23_ = result;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_INT32, &_tmp23_);
	return reply;
}


static DBusMessage* _dbus_console_kit_manager_get_session_for_cookie (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	const char* cookie;
	const char* _tmp24_;
	char* result;
	DBusMessage* reply;
	const char* _tmp25_;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	cookie = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp24_);
	dbus_message_iter_next (&iter);
	cookie = g_strdup (_tmp24_);
	result = console_kit_manager_get_session_for_cookie (self, cookie);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	_tmp25_ = result;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_OBJECT_PATH, &_tmp25_);
	return reply;
}


static DBusMessage* _dbus_console_kit_manager_restart (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	console_kit_manager_restart (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


static DBusMessage* _dbus_console_kit_manager_stop (ConsoleKitManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	console_kit_manager_stop (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


DBusHandlerResult console_kit_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object) {
	DBusMessage* reply;
	reply = NULL;
	if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Introspectable", "Introspect")) {
		reply = _dbus_console_kit_manager_introspect (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Properties", "GetAll")) {
		reply = _dbus_console_kit_manager_property_get_all (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.ConsoleKit.Manager", "OpenSessionWithParameters")) {
		reply = _dbus_console_kit_manager_open_session_with_parameters (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.ConsoleKit.Manager", "CloseSession")) {
		reply = _dbus_console_kit_manager_close_session (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.ConsoleKit.Manager", "GetSessionForCookie")) {
		reply = _dbus_console_kit_manager_get_session_for_cookie (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.ConsoleKit.Manager", "Restart")) {
		reply = _dbus_console_kit_manager_restart (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.ConsoleKit.Manager", "Stop")) {
		reply = _dbus_console_kit_manager_stop (object, connection, message);
	}
	if (reply) {
		dbus_connection_send (connection, reply, NULL);
		dbus_message_unref (reply);
		return DBUS_HANDLER_RESULT_HANDLED;
	} else {
		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
	}
}


void console_kit_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	if (!g_object_get_data (object, "dbus_object_path")) {
		g_object_set_data (object, "dbus_object_path", g_strdup (path));
		dbus_connection_register_object_path (connection, path, &_console_kit_manager_dbus_path_vtable, object);
		g_object_weak_ref (object, _vala_dbus_unregister_object, connection);
	}
}


static void console_kit_manager_base_init (ConsoleKitManagerIface * iface) {
	static gboolean initialized = FALSE;
	if (!initialized) {
		initialized = TRUE;
		g_type_set_qdata (CONSOLE_KIT_TYPE_MANAGER, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_console_kit_manager_dbus_vtable));
	}
}


GType console_kit_manager_get_type (void) {
	static GType console_kit_manager_type_id = 0;
	if (console_kit_manager_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (ConsoleKitManagerIface), (GBaseInitFunc) console_kit_manager_base_init, (GBaseFinalizeFunc) NULL, (GClassInitFunc) NULL, (GClassFinalizeFunc) NULL, NULL, 0, 0, (GInstanceInitFunc) NULL, NULL };
		console_kit_manager_type_id = g_type_register_static (G_TYPE_INTERFACE, "ConsoleKitManager", &g_define_type_info, 0);
		g_type_interface_add_prerequisite (console_kit_manager_type_id, DBUS_TYPE_G_PROXY);
	}
	return console_kit_manager_type_id;
}


G_DEFINE_TYPE_EXTENDED (ConsoleKitManagerDBusProxy, console_kit_manager_dbus_proxy, DBUS_TYPE_G_PROXY, 0, G_IMPLEMENT_INTERFACE (CONSOLE_KIT_TYPE_MANAGER, console_kit_manager_dbus_proxy_interface_init));
ConsoleKitManager* console_kit_manager_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path) {
	ConsoleKitManager* self;
	char* filter;
	self = g_object_new (console_kit_manager_dbus_proxy_get_type (), "connection", connection, "name", name, "path", path, "interface", "org.freedesktop.ConsoleKit.Manager", NULL);
	dbus_connection_add_filter (dbus_g_connection_get_connection (connection), console_kit_manager_dbus_proxy_filter, self, NULL);
	filter = g_strdup_printf ("type='signal',path='%s'", path);
	dbus_bus_add_match (dbus_g_connection_get_connection (connection), filter, NULL);
	g_free (filter);
	return self;
}


DBusHandlerResult console_kit_manager_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data) {
	if (dbus_message_has_path (message, dbus_g_proxy_get_path (user_data))) {
	}
	return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}


static void console_kit_manager_dbus_proxy_dispose (GObject* self) {
	DBusGConnection *connection;
	g_object_get (self, "connection", &connection, NULL);
	dbus_connection_remove_filter (dbus_g_connection_get_connection (connection), console_kit_manager_dbus_proxy_filter, self);
	G_OBJECT_CLASS (console_kit_manager_dbus_proxy_parent_class)->dispose (self);
}


static void console_kit_manager_dbus_proxy_class_init (ConsoleKitManagerDBusProxyClass* klass) {
	G_OBJECT_CLASS (klass)->dispose = console_kit_manager_dbus_proxy_dispose;
}


static void console_kit_manager_dbus_proxy_init (ConsoleKitManagerDBusProxy* self) {
}


static char* console_kit_manager_dbus_proxy_open_session_with_parameters (ConsoleKitManager* self, ConsoleKitSessionParameter* parameters, int parameters_length1) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	ConsoleKitSessionParameter* _tmp26_;
	DBusMessageIter _tmp27_;
	int _tmp28_;
	char* _result;
	const char* _tmp40_;
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "org.freedesktop.ConsoleKit.Manager", "OpenSessionWithParameters");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp26_ = parameters;
	dbus_message_iter_open_container (&_iter, DBUS_TYPE_ARRAY, "(sv)", &_tmp27_);
	for (_tmp28_ = 0; _tmp28_ < parameters_length1; _tmp28_++) {
		DBusMessageIter _tmp29_;
		const char* _tmp30_;
		DBusMessageIter _tmp31_;
		dbus_message_iter_open_container (&_tmp27_, DBUS_TYPE_STRUCT, NULL, &_tmp29_);
		_tmp30_ = (*_tmp26_).key;
		dbus_message_iter_append_basic (&_tmp29_, DBUS_TYPE_STRING, &_tmp30_);
		if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_UCHAR) {
			guint8 _tmp32_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "y", &_tmp31_);
			_tmp32_ = g_value_get_uchar (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_BYTE, &_tmp32_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_BOOLEAN) {
			dbus_bool_t _tmp33_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "b", &_tmp31_);
			_tmp33_ = g_value_get_boolean (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_BOOLEAN, &_tmp33_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_INT) {
			dbus_int32_t _tmp34_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "i", &_tmp31_);
			_tmp34_ = g_value_get_int (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_INT32, &_tmp34_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_UINT) {
			dbus_uint32_t _tmp35_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "u", &_tmp31_);
			_tmp35_ = g_value_get_uint (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_UINT32, &_tmp35_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_INT64) {
			dbus_int64_t _tmp36_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "x", &_tmp31_);
			_tmp36_ = g_value_get_int64 (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_INT64, &_tmp36_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_UINT64) {
			dbus_uint64_t _tmp37_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "t", &_tmp31_);
			_tmp37_ = g_value_get_uint64 (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_UINT64, &_tmp37_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_DOUBLE) {
			double _tmp38_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "d", &_tmp31_);
			_tmp38_ = g_value_get_double (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_DOUBLE, &_tmp38_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		} else if (G_VALUE_TYPE (&(*(*_tmp26_).value)) == G_TYPE_STRING) {
			const char* _tmp39_;
			dbus_message_iter_open_container (&_tmp29_, DBUS_TYPE_VARIANT, "s", &_tmp31_);
			_tmp39_ = g_value_get_string (&(*(*_tmp26_).value));
			dbus_message_iter_append_basic (&_tmp31_, DBUS_TYPE_STRING, &_tmp39_);
			dbus_message_iter_close_container (&_tmp29_, &_tmp31_);
		}
		dbus_message_iter_close_container (&_tmp27_, &_tmp29_);
		_tmp26_++;
	}
	dbus_message_iter_close_container (&_iter, &_tmp27_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_iter_get_basic (&_iter, &_tmp40_);
	dbus_message_iter_next (&_iter);
	_result = g_strdup (_tmp40_);
	dbus_message_unref (_reply);
	return _result;
}


static gint console_kit_manager_dbus_proxy_close_session (ConsoleKitManager* self, const char* cookie) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	const char* _tmp41_;
	gint _result;
	dbus_int32_t _tmp42_;
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "org.freedesktop.ConsoleKit.Manager", "CloseSession");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp41_ = cookie;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp41_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_iter_get_basic (&_iter, &_tmp42_);
	dbus_message_iter_next (&_iter);
	_result = _tmp42_;
	dbus_message_unref (_reply);
	return _result;
}


static char* console_kit_manager_dbus_proxy_get_session_for_cookie (ConsoleKitManager* self, const char* cookie) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	const char* _tmp43_;
	char* _result;
	const char* _tmp44_;
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "org.freedesktop.ConsoleKit.Manager", "GetSessionForCookie");
	dbus_message_iter_init_append (_message, &_iter);
	_tmp43_ = cookie;
	dbus_message_iter_append_basic (&_iter, DBUS_TYPE_STRING, &_tmp43_);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_iter_get_basic (&_iter, &_tmp44_);
	dbus_message_iter_next (&_iter);
	_result = g_strdup (_tmp44_);
	dbus_message_unref (_reply);
	return _result;
}


static void console_kit_manager_dbus_proxy_restart (ConsoleKitManager* self) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "org.freedesktop.ConsoleKit.Manager", "Restart");
	dbus_message_iter_init_append (_message, &_iter);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void console_kit_manager_dbus_proxy_stop (ConsoleKitManager* self) {
	DBusGConnection *_connection;
	DBusMessage *_message, *_reply;
	DBusMessageIter _iter;
	_message = dbus_message_new_method_call (dbus_g_proxy_get_bus_name ((DBusGProxy*) self), dbus_g_proxy_get_path ((DBusGProxy*) self), "org.freedesktop.ConsoleKit.Manager", "Stop");
	dbus_message_iter_init_append (_message, &_iter);
	g_object_get (self, "connection", &_connection, NULL);
	_reply = dbus_connection_send_with_reply_and_block (dbus_g_connection_get_connection (_connection), _message, -1, NULL);
	dbus_g_connection_unref (_connection);
	dbus_message_unref (_message);
	dbus_message_iter_init (_reply, &_iter);
	dbus_message_unref (_reply);
}


static void console_kit_manager_dbus_proxy_interface_init (ConsoleKitManagerIface* iface) {
	iface->open_session_with_parameters = console_kit_manager_dbus_proxy_open_session_with_parameters;
	iface->close_session = console_kit_manager_dbus_proxy_close_session;
	iface->get_session_for_cookie = console_kit_manager_dbus_proxy_get_session_for_cookie;
	iface->restart = console_kit_manager_dbus_proxy_restart;
	iface->stop = console_kit_manager_dbus_proxy_stop;
}


void _settings_daemon_manager_dbus_unregister (DBusConnection* connection, void* user_data) {
}


static DBusMessage* _dbus_settings_daemon_manager_introspect (SettingsDaemonManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter;
	GString* xml_data;
	char** children;
	int i;
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	xml_data = g_string_new ("<!DOCTYPE node PUBLIC \"-//freedesktop//DTD D-BUS Object Introspection 1.0//EN\" \"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd\">\n");
	g_string_append (xml_data, "<node>\n<interface name=\"org.freedesktop.DBus.Introspectable\">\n  <method name=\"Introspect\">\n    <arg name=\"data\" direction=\"out\" type=\"s\"/>\n  </method>\n</interface>\n<interface name=\"org.freedesktop.DBus.Properties\">\n  <method name=\"Get\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"out\" type=\"v\"/>\n  </method>\n  <method name=\"Set\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"propname\" direction=\"in\" type=\"s\"/>\n    <arg name=\"value\" direction=\"in\" type=\"v\"/>\n  </method>\n  <method name=\"GetAll\">\n    <arg name=\"interface\" direction=\"in\" type=\"s\"/>\n    <arg name=\"props\" direction=\"out\" type=\"a{sv}\"/>\n  </method>\n</interface>\n<interface name=\"org.gnome.SettingsDaemon\">\n</interface>\n");
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


static DBusMessage* _dbus_settings_daemon_manager_property_get_all (SettingsDaemonManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter, reply_iter, subiter;
	char* interface_name;
	const char* _tmp45_;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &reply_iter);
	dbus_message_iter_get_basic (&iter, &_tmp45_);
	dbus_message_iter_next (&iter);
	interface_name = g_strdup (_tmp45_);
	if (strcmp (interface_name, "org.gnome.SettingsDaemon") == 0) {
		dbus_message_iter_open_container (&reply_iter, DBUS_TYPE_ARRAY, "{sv}", &subiter);
		dbus_message_iter_close_container (&reply_iter, &subiter);
	} else {
		return NULL;
	}
	return reply;
}


DBusHandlerResult settings_daemon_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object) {
	DBusMessage* reply;
	reply = NULL;
	if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Introspectable", "Introspect")) {
		reply = _dbus_settings_daemon_manager_introspect (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Properties", "GetAll")) {
		reply = _dbus_settings_daemon_manager_property_get_all (object, connection, message);
	}
	if (reply) {
		dbus_connection_send (connection, reply, NULL);
		dbus_message_unref (reply);
		return DBUS_HANDLER_RESULT_HANDLED;
	} else {
		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
	}
}


void settings_daemon_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	if (!g_object_get_data (object, "dbus_object_path")) {
		g_object_set_data (object, "dbus_object_path", g_strdup (path));
		dbus_connection_register_object_path (connection, path, &_settings_daemon_manager_dbus_path_vtable, object);
		g_object_weak_ref (object, _vala_dbus_unregister_object, connection);
	}
}


static void settings_daemon_manager_base_init (SettingsDaemonManagerIface * iface) {
	static gboolean initialized = FALSE;
	if (!initialized) {
		initialized = TRUE;
		g_type_set_qdata (SETTINGS_DAEMON_TYPE_MANAGER, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_settings_daemon_manager_dbus_vtable));
	}
}


GType settings_daemon_manager_get_type (void) {
	static GType settings_daemon_manager_type_id = 0;
	if (settings_daemon_manager_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (SettingsDaemonManagerIface), (GBaseInitFunc) settings_daemon_manager_base_init, (GBaseFinalizeFunc) NULL, (GClassInitFunc) NULL, (GClassFinalizeFunc) NULL, NULL, 0, 0, (GInstanceInitFunc) NULL, NULL };
		settings_daemon_manager_type_id = g_type_register_static (G_TYPE_INTERFACE, "SettingsDaemonManager", &g_define_type_info, 0);
		g_type_interface_add_prerequisite (settings_daemon_manager_type_id, DBUS_TYPE_G_PROXY);
	}
	return settings_daemon_manager_type_id;
}


G_DEFINE_TYPE_EXTENDED (SettingsDaemonManagerDBusProxy, settings_daemon_manager_dbus_proxy, DBUS_TYPE_G_PROXY, 0, G_IMPLEMENT_INTERFACE (SETTINGS_DAEMON_TYPE_MANAGER, settings_daemon_manager_dbus_proxy_interface_init));
SettingsDaemonManager* settings_daemon_manager_dbus_proxy_new (DBusGConnection* connection, const char* name, const char* path) {
	SettingsDaemonManager* self;
	char* filter;
	self = g_object_new (settings_daemon_manager_dbus_proxy_get_type (), "connection", connection, "name", name, "path", path, "interface", "org.gnome.SettingsDaemon", NULL);
	dbus_connection_add_filter (dbus_g_connection_get_connection (connection), settings_daemon_manager_dbus_proxy_filter, self, NULL);
	filter = g_strdup_printf ("type='signal',path='%s'", path);
	dbus_bus_add_match (dbus_g_connection_get_connection (connection), filter, NULL);
	g_free (filter);
	return self;
}


DBusHandlerResult settings_daemon_manager_dbus_proxy_filter (DBusConnection* connection, DBusMessage* message, void* user_data) {
	if (dbus_message_has_path (message, dbus_g_proxy_get_path (user_data))) {
	}
	return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}


static void settings_daemon_manager_dbus_proxy_dispose (GObject* self) {
	DBusGConnection *connection;
	g_object_get (self, "connection", &connection, NULL);
	dbus_connection_remove_filter (dbus_g_connection_get_connection (connection), settings_daemon_manager_dbus_proxy_filter, self);
	G_OBJECT_CLASS (settings_daemon_manager_dbus_proxy_parent_class)->dispose (self);
}


static void settings_daemon_manager_dbus_proxy_class_init (SettingsDaemonManagerDBusProxyClass* klass) {
	G_OBJECT_CLASS (klass)->dispose = settings_daemon_manager_dbus_proxy_dispose;
}


static void settings_daemon_manager_dbus_proxy_init (SettingsDaemonManagerDBusProxy* self) {
}


static void settings_daemon_manager_dbus_proxy_interface_init (SettingsDaemonManagerIface* iface) {
}


XSAASessionManager* xsaa_session_manager_construct (GType object_type, DBusGConnection* conn) {
	XSAASessionManager * self;
	DBusGConnection* _tmp1_;
	DBusGConnection* _tmp0_;
	ConsoleKitManager* _tmp2_;
	GeeMap* _tmp3_;
	g_return_val_if_fail (conn != NULL, NULL);
	self = g_object_newv (object_type, 0, NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->connection = (_tmp1_ = (_tmp0_ = conn, (_tmp0_ == NULL) ? NULL : dbus_g_connection_ref (_tmp0_)), (self->priv->connection == NULL) ? NULL : (self->priv->connection = (dbus_g_connection_unref (self->priv->connection), NULL)), _tmp1_);
	_tmp2_ = NULL;
	self->priv->manager = (_tmp2_ = console_kit_manager_dbus_proxy_new (conn, "org.freedesktop.ConsoleKit", "/org/freedesktop/ConsoleKit/Manager"), (self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL)), _tmp2_);
	_tmp3_ = NULL;
	self->sessions = (_tmp3_ = (GeeMap*) gee_hash_map_new (G_TYPE_STRING, (GBoxedCopyFunc) g_strdup, g_free, XSAA_TYPE_SESSION, (GBoxedCopyFunc) g_object_ref, g_object_unref, g_str_hash, g_str_equal, g_direct_equal), (self->sessions == NULL) ? NULL : (self->sessions = (gee_collection_object_unref (self->sessions), NULL)), _tmp3_);
	return self;
}


XSAASessionManager* xsaa_session_manager_new (DBusGConnection* conn) {
	return xsaa_session_manager_construct (XSAA_TYPE_SESSION_MANAGER, conn);
}


gboolean xsaa_session_manager_open_session (XSAASessionManager* self, const char* user, gint display, const char* device, gboolean autologin, char** path) {
	GError * _inner_error_;
	char* _tmp4_;
	char* _tmp3_;
	char* _tmp2_;
	char* _tmp1_;
	char* _tmp0_;
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (user != NULL, FALSE);
	g_return_val_if_fail (device != NULL, FALSE);
	if (path != NULL) {
		*path = NULL;
	}
	_inner_error_ = NULL;
	_tmp4_ = NULL;
	_tmp3_ = NULL;
	_tmp2_ = NULL;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	(*path) = (_tmp4_ = g_strdup (_tmp3_ = g_strconcat (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("/fr/supersonicimagine/XSAA/Manager/Session/", user, NULL), "/", NULL), _tmp2_ = g_strdup_printf ("%i", display), NULL)), (*path) = (g_free ((*path)), NULL), _tmp4_);
	_tmp3_ = (g_free (_tmp3_), NULL);
	_tmp2_ = (g_free (_tmp2_), NULL);
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	{
		char* service;
		XSAASession* session;
		service = g_strdup ("xsplashaa");
		if (autologin) {
			char* _tmp5_;
			_tmp5_ = NULL;
			service = (_tmp5_ = g_strdup ("xsplashaa-autologin"), service = (g_free (service), NULL), _tmp5_);
		}
		session = xsaa_session_new (self->priv->connection, self->priv->manager, service, user, display, device, &_inner_error_);
		if (_inner_error_ != NULL) {
			service = (g_free (service), NULL);
			goto __catch5_g_error;
			goto __finally5;
		}
		fprintf (stderr, "Open session %s\n", (*path));
		_vala_dbus_register_object (dbus_g_connection_get_connection (self->priv->connection), (*path), (GObject*) session);
		gee_map_set (self->sessions, (*path), session);
		service = (g_free (service), NULL);
		(session == NULL) ? NULL : (session = (g_object_unref (session), NULL));
	}
	goto __finally5;
	__catch5_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			gboolean _tmp6_;
			fprintf (stderr, "Error on create session : %s", err->message);
			return (_tmp6_ = FALSE, (err == NULL) ? NULL : (err = (g_error_free (err), NULL)), _tmp6_);
		}
	}
	__finally5:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return FALSE;
	}
	return TRUE;
}


void xsaa_session_manager_close_session (XSAASessionManager* self, const char* path) {
	g_return_if_fail (self != NULL);
	fprintf (stderr, "Close session %s\n", path);
	gee_map_remove (self->sessions, path);
}


void xsaa_session_manager_reboot (XSAASessionManager* self) {
	g_return_if_fail (self != NULL);
	console_kit_manager_restart (self->priv->manager);
}


void xsaa_session_manager_halt (XSAASessionManager* self) {
	g_return_if_fail (self != NULL);
	console_kit_manager_stop (self->priv->manager);
}


void _xsaa_session_manager_dbus_unregister (DBusConnection* connection, void* user_data) {
}


static DBusMessage* _dbus_xsaa_session_manager_introspect (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message) {
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


static DBusMessage* _dbus_xsaa_session_manager_property_get_all (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessage* reply;
	DBusMessageIter iter, reply_iter, subiter;
	char* interface_name;
	const char* _tmp46_;
	if (strcmp (dbus_message_get_signature (message), "s")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &reply_iter);
	dbus_message_iter_get_basic (&iter, &_tmp46_);
	dbus_message_iter_next (&iter);
	interface_name = g_strdup (_tmp46_);
	if (strcmp (interface_name, "fr.supersonicimagine.XSAA.Manager") == 0) {
		dbus_message_iter_open_container (&reply_iter, DBUS_TYPE_ARRAY, "{sv}", &subiter);
		dbus_message_iter_close_container (&reply_iter, &subiter);
	} else {
		return NULL;
	}
	return reply;
}


static DBusMessage* _dbus_xsaa_session_manager_open_session (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	const char* user;
	const char* _tmp47_;
	gint display;
	dbus_int32_t _tmp48_;
	const char* device;
	const char* _tmp49_;
	gboolean autologin;
	dbus_bool_t _tmp50_;
	char* path;
	gboolean result;
	DBusMessage* reply;
	const char* _tmp51_;
	dbus_bool_t _tmp52_;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "sisb")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	user = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp47_);
	dbus_message_iter_next (&iter);
	user = g_strdup (_tmp47_);
	display = 0;
	dbus_message_iter_get_basic (&iter, &_tmp48_);
	dbus_message_iter_next (&iter);
	display = _tmp48_;
	device = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp49_);
	dbus_message_iter_next (&iter);
	device = g_strdup (_tmp49_);
	autologin = FALSE;
	dbus_message_iter_get_basic (&iter, &_tmp50_);
	dbus_message_iter_next (&iter);
	autologin = _tmp50_;
	path = NULL;
	result = xsaa_session_manager_open_session (self, user, display, device, autologin, &path);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	_tmp51_ = path;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_OBJECT_PATH, &_tmp51_);
	_tmp52_ = result;
	dbus_message_iter_append_basic (&iter, DBUS_TYPE_BOOLEAN, &_tmp52_);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_manager_close_session (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	const char* path;
	const char* _tmp53_;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "o")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	path = NULL;
	dbus_message_iter_get_basic (&iter, &_tmp53_);
	dbus_message_iter_next (&iter);
	path = g_strdup (_tmp53_);
	xsaa_session_manager_close_session (self, path);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_manager_reboot (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	xsaa_session_manager_reboot (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


static DBusMessage* _dbus_xsaa_session_manager_halt (XSAASessionManager* self, DBusConnection* connection, DBusMessage* message) {
	DBusMessageIter iter;
	GError* error;
	DBusMessage* reply;
	error = NULL;
	if (strcmp (dbus_message_get_signature (message), "")) {
		return NULL;
	}
	dbus_message_iter_init (message, &iter);
	xsaa_session_manager_halt (self);
	reply = dbus_message_new_method_return (message);
	dbus_message_iter_init_append (reply, &iter);
	return reply;
}


DBusHandlerResult xsaa_session_manager_dbus_message (DBusConnection* connection, DBusMessage* message, void* object) {
	DBusMessage* reply;
	reply = NULL;
	if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Introspectable", "Introspect")) {
		reply = _dbus_xsaa_session_manager_introspect (object, connection, message);
	} else if (dbus_message_is_method_call (message, "org.freedesktop.DBus.Properties", "GetAll")) {
		reply = _dbus_xsaa_session_manager_property_get_all (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "OpenSession")) {
		reply = _dbus_xsaa_session_manager_open_session (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "CloseSession")) {
		reply = _dbus_xsaa_session_manager_close_session (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "Reboot")) {
		reply = _dbus_xsaa_session_manager_reboot (object, connection, message);
	} else if (dbus_message_is_method_call (message, "fr.supersonicimagine.XSAA.Manager", "Halt")) {
		reply = _dbus_xsaa_session_manager_halt (object, connection, message);
	}
	if (reply) {
		dbus_connection_send (connection, reply, NULL);
		dbus_message_unref (reply);
		return DBUS_HANDLER_RESULT_HANDLED;
	} else {
		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
	}
}


void xsaa_session_manager_dbus_register_object (DBusConnection* connection, const char* path, void* object) {
	if (!g_object_get_data (object, "dbus_object_path")) {
		g_object_set_data (object, "dbus_object_path", g_strdup (path));
		dbus_connection_register_object_path (connection, path, &_xsaa_session_manager_dbus_path_vtable, object);
		g_object_weak_ref (object, _vala_dbus_unregister_object, connection);
	}
}


static void xsaa_session_manager_class_init (XSAASessionManagerClass * klass) {
	xsaa_session_manager_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAASessionManagerPrivate));
	G_OBJECT_CLASS (klass)->finalize = xsaa_session_manager_finalize;
	g_type_set_qdata (XSAA_TYPE_SESSION_MANAGER, g_quark_from_static_string ("DBusObjectVTable"), (void*) (&_xsaa_session_manager_dbus_vtable));
}


static void xsaa_session_manager_instance_init (XSAASessionManager * self) {
	self->priv = XSAA_SESSION_MANAGER_GET_PRIVATE (self);
}


static void xsaa_session_manager_finalize (GObject* obj) {
	XSAASessionManager * self;
	self = XSAA_SESSION_MANAGER (obj);
	(self->priv->connection == NULL) ? NULL : (self->priv->connection = (dbus_g_connection_unref (self->priv->connection), NULL));
	(self->sessions == NULL) ? NULL : (self->sessions = (gee_collection_object_unref (self->sessions), NULL));
	(self->priv->manager == NULL) ? NULL : (self->priv->manager = (g_object_unref (self->priv->manager), NULL));
	G_OBJECT_CLASS (xsaa_session_manager_parent_class)->finalize (obj);
}


GType xsaa_session_manager_get_type (void) {
	static GType xsaa_session_manager_type_id = 0;
	if (xsaa_session_manager_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAASessionManagerClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_session_manager_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAASessionManager), 0, (GInstanceInitFunc) xsaa_session_manager_instance_init, NULL };
		xsaa_session_manager_type_id = g_type_register_static (G_TYPE_OBJECT, "XSAASessionManager", &g_define_type_info, 0);
	}
	return xsaa_session_manager_type_id;
}


guint _dynamic_request_name0 (DBusGProxy* self, const char* param1, guint param2, GError** error) {
	guint result;
	dbus_g_proxy_call (self, "RequestName", error, G_TYPE_STRING, param1, G_TYPE_UINT, param2, G_TYPE_INVALID, G_TYPE_UINT, &result, G_TYPE_INVALID);
	if (*error) {
		return 0U;
	}
	return result;
}


guint _dynamic_request_name1 (DBusGProxy* self, const char* param1, guint param2, GError** error) {
	guint result;
	dbus_g_proxy_call (self, "RequestName", error, G_TYPE_STRING, param1, G_TYPE_UINT, param2, G_TYPE_INVALID, G_TYPE_UINT, &result, G_TYPE_INVALID);
	if (*error) {
		return 0U;
	}
	return result;
}


gint xsaa_main (char** args, int args_length1) {
	GError * _inner_error_;
	_inner_error_ = NULL;
	{
		GOptionContext* opt_context;
		opt_context = g_option_context_new ("- Xsplashaa session daemon");
		g_option_context_set_help_enabled (opt_context, TRUE);
		g_option_context_add_main_entries (opt_context, XSAA_option_entries, "xsplasaa-session-daemon");
		g_option_context_parse (opt_context, &args_length1, &args, &_inner_error_);
		if (_inner_error_ != NULL) {
			(opt_context == NULL) ? NULL : (opt_context = (g_option_context_free (opt_context), NULL));
			if (_inner_error_->domain == G_OPTION_ERROR) {
				goto __catch6_g_option_error;
			}
			goto __finally6;
		}
		(opt_context == NULL) ? NULL : (opt_context = (g_option_context_free (opt_context), NULL));
	}
	goto __finally6;
	__catch6_g_option_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			gint _tmp0_;
			fprintf (stderr, "Option parsing failed: %s\n", err->message);
			return (_tmp0_ = -1, (err == NULL) ? NULL : (err = (g_error_free (err), NULL)), _tmp0_);
		}
	}
	__finally6:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return 0;
	}
	if (!xsaa_no_daemon) {
		daemon (0, 0);
	}
	{
		GMainLoop* _tmp1_;
		DBusGConnection* conn;
		DBusGProxy* bus;
		guint r1;
		guint r2;
		gboolean _tmp2_;
		_tmp1_ = NULL;
		xsaa_loop = (_tmp1_ = g_main_loop_new (NULL, FALSE), (xsaa_loop == NULL) ? NULL : (xsaa_loop = (g_main_loop_unref (xsaa_loop), NULL)), _tmp1_);
		conn = dbus_g_bus_get (DBUS_BUS_SYSTEM, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch7_g_error;
			goto __finally7;
		}
		bus = dbus_g_proxy_new_for_name (conn, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus");
		r1 = _dynamic_request_name0 (bus, "fr.supersonicimagine.XSAA.Manager.Session", (guint) 0, &_inner_error_);
		if (_inner_error_ != NULL) {
			(conn == NULL) ? NULL : (conn = (dbus_g_connection_unref (conn), NULL));
			(bus == NULL) ? NULL : (bus = (g_object_unref (bus), NULL));
			goto __catch7_g_error;
			goto __finally7;
		}
		r2 = _dynamic_request_name1 (bus, "fr.supersonicimagine.XSAA.Manager", (guint) 0, &_inner_error_);
		if (_inner_error_ != NULL) {
			(conn == NULL) ? NULL : (conn = (dbus_g_connection_unref (conn), NULL));
			(bus == NULL) ? NULL : (bus = (g_object_unref (bus), NULL));
			goto __catch7_g_error;
			goto __finally7;
		}
		_tmp2_ = FALSE;
		if (r1 == DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER) {
			_tmp2_ = r2 == DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER;
		} else {
			_tmp2_ = FALSE;
		}
		if (_tmp2_) {
			XSAASessionManager* service;
			service = xsaa_session_manager_new (conn);
			_vala_dbus_register_object (dbus_g_connection_get_connection (conn), "/fr/supersonicimagine/XSAA/Manager", (GObject*) service);
			g_main_loop_run (xsaa_loop);
			(service == NULL) ? NULL : (service = (g_object_unref (service), NULL));
		}
		(conn == NULL) ? NULL : (conn = (dbus_g_connection_unref (conn), NULL));
		(bus == NULL) ? NULL : (bus = (g_object_unref (bus), NULL));
	}
	goto __finally7;
	__catch7_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			gint _tmp3_;
			g_message ("xsaa-session-daemon.vala:177: %s\n", err->message);
			return (_tmp3_ = -1, (err == NULL) ? NULL : (err = (g_error_free (err), NULL)), _tmp3_);
		}
	}
	__finally7:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return 0;
	}
	return 0;
}


int main (int argc, char ** argv) {
	g_type_init ();
	return xsaa_main (argv, argc);
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




