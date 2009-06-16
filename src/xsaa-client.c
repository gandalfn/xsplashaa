/* xsaa-client.vala
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
#include <sys/un.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <stdio.h>


#define XSAA_TYPE_SOCKET (xsaa_socket_get_type ())
#define XSAA_SOCKET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SOCKET, XSAASocket))
#define XSAA_SOCKET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SOCKET, XSAASocketClass))
#define XSAA_IS_SOCKET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SOCKET))
#define XSAA_IS_SOCKET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SOCKET))
#define XSAA_SOCKET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SOCKET, XSAASocketClass))

typedef struct _XSAASocket XSAASocket;
typedef struct _XSAASocketClass XSAASocketClass;
typedef struct _XSAASocketPrivate XSAASocketPrivate;

#define XSAA_TYPE_CLIENT (xsaa_client_get_type ())
#define XSAA_CLIENT(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_CLIENT, XSAAClient))
#define XSAA_CLIENT_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_CLIENT, XSAAClientClass))
#define XSAA_IS_CLIENT(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_CLIENT))
#define XSAA_IS_CLIENT_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_CLIENT))
#define XSAA_CLIENT_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_CLIENT, XSAAClientClass))

typedef struct _XSAAClient XSAAClient;
typedef struct _XSAAClientClass XSAAClientClass;
typedef struct _XSAAClientPrivate XSAAClientPrivate;

struct _XSAASocket {
	GObject parent_instance;
	XSAASocketPrivate * priv;
	char* filename;
	gint fd;
	struct sockaddr_un* saddr;
	GIOChannel* ioc;
};

struct _XSAASocketClass {
	GObjectClass parent_class;
};

struct _XSAAClient {
	XSAASocket parent_instance;
	XSAAClientPrivate * priv;
};

struct _XSAAClientClass {
	XSAASocketClass parent_class;
};

typedef enum  {
	XSAA_SOCKET_ERROR_INVALID_NAME,
	XSAA_SOCKET_ERROR_CREATE
} XSAASocketError;
#define XSAA_SOCKET_ERROR xsaa_socket_error_quark ()


GType xsaa_socket_get_type (void);
GType xsaa_client_get_type (void);
enum  {
	XSAA_CLIENT_DUMMY_PROPERTY
};
GQuark xsaa_socket_error_quark (void);
XSAASocket* xsaa_socket_new (const char* socket_name, GError** error);
XSAASocket* xsaa_socket_construct (GType object_type, const char* socket_name, GError** error);
XSAAClient* xsaa_client_new (const char* socket_name, GError** error);
XSAAClient* xsaa_client_construct (GType object_type, const char* socket_name, GError** error);
XSAAClient* xsaa_client_new (const char* socket_name, GError** error);
static gpointer xsaa_client_parent_class = NULL;
extern gboolean xsaa_ping;
extern gboolean xsaa_pulse;
extern gboolean xsaa_dbus;
extern gboolean xsaa_session;
extern gint xsaa_phase;
extern gint xsaa_progress;
extern gboolean xsaa_left_to_right;
extern gboolean xsaa_right_to_left;
extern gboolean xsaa_quit;
extern gboolean xsaa_close_session;
extern char* xsaa_socket_name;
gboolean xsaa_quit = FALSE;
gboolean xsaa_close_session = FALSE;
gboolean xsaa_ping = FALSE;
gboolean xsaa_pulse = FALSE;
gboolean xsaa_dbus = FALSE;
gboolean xsaa_session = FALSE;
gint xsaa_phase = 0;
gint xsaa_progress = 0;
gboolean xsaa_right_to_left = FALSE;
gboolean xsaa_left_to_right = FALSE;
char* xsaa_socket_name = NULL;
extern XSAAClient* xsaa_client;
XSAAClient* xsaa_client = NULL;
gboolean xsaa_socket_send (XSAASocket* self, const char* message);
gint xsaa_handle_quit (void);
gboolean xsaa_socket_recv (XSAASocket* self, char** message);
void xsaa_on_pong (void);
gint xsaa_handle_dbus (void);
gint xsaa_handle_session (void);
static void _xsaa_on_pong_xsaa_socket_in (XSAAClient* _sender, gpointer self);
gint xsaa_handle_ping (void);
gint xsaa_handle_phase (void);
gint xsaa_handle_progress (void);
gint xsaa_handle_right_to_left (void);
gint xsaa_handle_left_to_right (void);
gint xsaa_handle_pulse (void);
gint xsaa_handle_close_session (void);
gint xsaa_main (char** args, int args_length1);

static const GOptionEntry XSAA_option_entries[] = {{"ping", 'p', 0, G_OPTION_ARG_NONE, &xsaa_ping, "Ping", NULL}, {"pulse", 'u', 0, G_OPTION_ARG_NONE, &xsaa_pulse, "Pulse", NULL}, {"dbus", 'd', 0, G_OPTION_ARG_NONE, &xsaa_dbus, "DBus ready", NULL}, {"session", 's', 0, G_OPTION_ARG_NONE, &xsaa_session, "Session ready", NULL}, {"phase", 'a', 0, G_OPTION_ARG_INT, &xsaa_phase, NULL, "PHASE"}, {"progress", 'r', 0, G_OPTION_ARG_INT, &xsaa_progress, NULL, "PROGRESS"}, {"left-to-right", 'l', 0, G_OPTION_ARG_NONE, &xsaa_left_to_right, "Left to Right", NULL}, {"right-to-left", 'i', 0, G_OPTION_ARG_NONE, &xsaa_right_to_left, "Right to Left", NULL}, {"quit", 'q', 0, G_OPTION_ARG_NONE, &xsaa_quit, "Quit", NULL}, {"close-session", 'c', 0, G_OPTION_ARG_NONE, &xsaa_close_session, "Close session", NULL}, {"socket", (gchar) 0, 0, G_OPTION_ARG_STRING, &xsaa_socket_name, NULL, "SOCKET"}, {NULL}};


XSAAClient* xsaa_client_construct (GType object_type, const char* socket_name, GError** error) {
	GError * _inner_error_;
	XSAAClient * self;
	g_return_val_if_fail (socket_name != NULL, NULL);
	_inner_error_ = NULL;
	self = (XSAAClient*) xsaa_socket_construct (object_type, socket_name, error);
	fcntl (((XSAASocket*) self)->fd, O_NONBLOCK, NULL);
	if (connect (((XSAASocket*) self)->fd, (struct sockaddr*) ((XSAASocket*) self)->saddr, 110) != 0) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new (XSAA_SOCKET_ERROR, XSAA_SOCKET_ERROR_CREATE, "error on connect %s", socket_name);
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_SOCKET_ERROR) {
				g_propagate_error (error, _inner_error_);
				return;
			} else {
				g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
				g_clear_error (&_inner_error_);
				return NULL;
			}
		}
	}
	return self;
}


XSAAClient* xsaa_client_new (const char* socket_name, GError** error) {
	return xsaa_client_construct (XSAA_TYPE_CLIENT, socket_name, error);
}


static void xsaa_client_class_init (XSAAClientClass * klass) {
	xsaa_client_parent_class = g_type_class_peek_parent (klass);
}


static void xsaa_client_instance_init (XSAAClient * self) {
}


GType xsaa_client_get_type (void) {
	static GType xsaa_client_type_id = 0;
	if (xsaa_client_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAAClientClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_client_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAAClient), 0, (GInstanceInitFunc) xsaa_client_instance_init, NULL };
		xsaa_client_type_id = g_type_register_static (XSAA_TYPE_SOCKET, "XSAAClient", &g_define_type_info, 0);
	}
	return xsaa_client_type_id;
}


gint xsaa_handle_quit (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "quit");
	return 0;
}


void xsaa_on_pong (void) {
	char* message;
	char* _tmp2_;
	gboolean _tmp1_;
	char* _tmp0_;
	message = NULL;
	_tmp2_ = NULL;
	_tmp0_ = NULL;
	if ((_tmp1_ = xsaa_socket_recv ((XSAASocket*) xsaa_client, &_tmp0_), message = (_tmp2_ = _tmp0_, message = (g_free (message), NULL), _tmp2_), _tmp1_)) {
		exit (0);
	}
	message = (g_free (message), NULL);
}


gint xsaa_handle_dbus (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "dbus");
	return 0;
}


gint xsaa_handle_session (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "session");
	return 0;
}


static void _xsaa_on_pong_xsaa_socket_in (XSAAClient* _sender, gpointer self) {
	xsaa_on_pong ();
}


gint xsaa_handle_ping (void) {
	GMainLoop* loop;
	gint _tmp0_;
	loop = g_main_loop_new (NULL, FALSE);
	g_signal_connect ((XSAASocket*) xsaa_client, "in", (GCallback) _xsaa_on_pong_xsaa_socket_in, NULL);
	xsaa_socket_send ((XSAASocket*) xsaa_client, "ping");
	g_main_loop_run (loop);
	return (_tmp0_ = 0, (loop == NULL) ? NULL : (loop = (g_main_loop_unref (loop), NULL)), _tmp0_);
}


gint xsaa_handle_phase (void) {
	char* _tmp1_;
	char* _tmp0_;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	xsaa_socket_send ((XSAASocket*) xsaa_client, _tmp1_ = g_strconcat ("phase=", _tmp0_ = g_strdup_printf ("%i", xsaa_phase - 1), NULL));
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	return 0;
}


gint xsaa_handle_progress (void) {
	char* _tmp1_;
	char* _tmp0_;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	xsaa_socket_send ((XSAASocket*) xsaa_client, _tmp1_ = g_strconcat ("progress=", _tmp0_ = g_strdup_printf ("%i", xsaa_progress), NULL));
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	return 0;
}


gint xsaa_handle_right_to_left (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "right-to-left");
	return 0;
}


gint xsaa_handle_left_to_right (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "left-to-right");
	return 0;
}


gint xsaa_handle_pulse (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "pulse");
	return 0;
}


gint xsaa_handle_close_session (void) {
	xsaa_socket_send ((XSAASocket*) xsaa_client, "close-session");
	return 0;
}


gint xsaa_main (char** args, int args_length1) {
	GError * _inner_error_;
	char* _tmp0_;
	_inner_error_ = NULL;
	_tmp0_ = NULL;
	xsaa_socket_name = (_tmp0_ = g_strdup ("/tmp/xsplashaa-socket"), xsaa_socket_name = (g_free (xsaa_socket_name), NULL), _tmp0_);
	{
		GOptionContext* opt_context;
		opt_context = g_option_context_new ("- Xsplashaa client");
		g_option_context_set_help_enabled (opt_context, TRUE);
		g_option_context_add_main_entries (opt_context, XSAA_option_entries, "xsplasaa");
		g_option_context_parse (opt_context, &args_length1, &args, &_inner_error_);
		if (_inner_error_ != NULL) {
			(opt_context == NULL) ? NULL : (opt_context = (g_option_context_free (opt_context), NULL));
			if (_inner_error_->domain == G_OPTION_ERROR) {
				goto __catch1_g_option_error;
			}
			goto __finally1;
		}
		(opt_context == NULL) ? NULL : (opt_context = (g_option_context_free (opt_context), NULL));
	}
	goto __finally1;
	__catch1_g_option_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			gint _tmp1_;
			fprintf (stderr, "Option parsing failed: %s\n", err->message);
			return (_tmp1_ = -1, (err == NULL) ? NULL : (err = (g_error_free (err), NULL)), _tmp1_);
		}
	}
	__finally1:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return 0;
	}
	{
		XSAAClient* _tmp2_;
		_tmp2_ = NULL;
		xsaa_client = (_tmp2_ = xsaa_client_new (xsaa_socket_name, &_inner_error_), (xsaa_client == NULL) ? NULL : (xsaa_client = (g_object_unref (xsaa_client), NULL)), _tmp2_);
		if (_inner_error_ != NULL) {
			if (_inner_error_->domain == XSAA_SOCKET_ERROR) {
				goto __catch2_xsaa_socket_error;
			}
			goto __finally2;
		}
	}
	goto __finally2;
	__catch2_xsaa_socket_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			gint _tmp3_;
			return (_tmp3_ = -1, (err == NULL) ? NULL : (err = (g_error_free (err), NULL)), _tmp3_);
		}
	}
	__finally2:
	if (_inner_error_ != NULL) {
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return 0;
	}
	if (xsaa_quit) {
		return xsaa_handle_quit ();
	} else {
		if (xsaa_ping) {
			return xsaa_handle_ping ();
		} else {
			if (xsaa_dbus) {
				return xsaa_handle_dbus ();
			} else {
				if (xsaa_session) {
					return xsaa_handle_session ();
				} else {
					if (xsaa_phase > 0) {
						return xsaa_handle_phase ();
					} else {
						if (xsaa_pulse) {
							return xsaa_handle_pulse ();
						} else {
							if (xsaa_progress > 0) {
								return xsaa_handle_progress ();
							} else {
								if (xsaa_right_to_left) {
									return xsaa_handle_right_to_left ();
								} else {
									if (xsaa_left_to_right) {
										return xsaa_handle_left_to_right ();
									} else {
										if (xsaa_close_session) {
											return xsaa_handle_close_session ();
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return -1;
}


int main (int argc, char ** argv) {
	g_type_init ();
	return xsaa_main (argv, argc);
}




