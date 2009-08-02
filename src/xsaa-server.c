/* xsaa-server.vala
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
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <gtk/gtk.h>


#define XSAA_TYPE_SOCKET (xsaa_socket_get_type ())
#define XSAA_SOCKET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SOCKET, XSAASocket))
#define XSAA_SOCKET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SOCKET, XSAASocketClass))
#define XSAA_IS_SOCKET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SOCKET))
#define XSAA_IS_SOCKET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SOCKET))
#define XSAA_SOCKET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SOCKET, XSAASocketClass))

typedef struct _XSAASocket XSAASocket;
typedef struct _XSAASocketClass XSAASocketClass;
typedef struct _XSAASocketPrivate XSAASocketPrivate;

#define XSAA_TYPE_SERVER (xsaa_server_get_type ())
#define XSAA_SERVER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SERVER, XSAAServer))
#define XSAA_SERVER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SERVER, XSAAServerClass))
#define XSAA_IS_SERVER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SERVER))
#define XSAA_IS_SERVER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SERVER))
#define XSAA_SERVER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SERVER, XSAAServerClass))

typedef struct _XSAAServer XSAAServer;
typedef struct _XSAAServerClass XSAAServerClass;
typedef struct _XSAAServerPrivate XSAAServerPrivate;

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

struct _XSAAServer {
	XSAASocket parent_instance;
	XSAAServerPrivate * priv;
};

struct _XSAAServerClass {
	XSAASocketClass parent_class;
};

typedef enum  {
	XSAA_SOCKET_ERROR_INVALID_NAME,
	XSAA_SOCKET_ERROR_CREATE
} XSAASocketError;
#define XSAA_SOCKET_ERROR xsaa_socket_error_quark ()

static gint xsaa_server_BUFFER_LENGTH;
static gint xsaa_server_BUFFER_LENGTH = 200;
static gpointer xsaa_server_parent_class = NULL;

GType xsaa_socket_get_type (void);
GType xsaa_server_get_type (void);
enum  {
	XSAA_SERVER_DUMMY_PROPERTY
};
GQuark xsaa_socket_error_quark (void);
XSAASocket* xsaa_socket_new (const char* socket_name, GError** error);
XSAASocket* xsaa_socket_construct (GType object_type, const char* socket_name, GError** error);
static void xsaa_server_on_client_connect (XSAAServer* self);
static void _xsaa_server_on_client_connect_xsaa_socket_in (XSAAServer* _sender, gpointer self);
XSAAServer* xsaa_server_new (const char* socket_name, GError** error);
XSAAServer* xsaa_server_construct (GType object_type, const char* socket_name, GError** error);
static gboolean xsaa_server_on_client_message (XSAAServer* self, GIOChannel* client, GIOCondition condition);
static gboolean _xsaa_server_on_client_message_gio_func (GIOChannel* source, GIOCondition condition, gpointer self);
static void xsaa_server_handle_client_message (XSAAServer* self, GIOChannel* client, const char* buffer);
static void xsaa_server_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);
static gint _vala_array_length (gpointer array);
static int _vala_strcmp0 (const char * str1, const char * str2);



static void _xsaa_server_on_client_connect_xsaa_socket_in (XSAAServer* _sender, gpointer self) {
	xsaa_server_on_client_connect (self);
}


XSAAServer* xsaa_server_construct (GType object_type, const char* socket_name, GError** error) {
	GError * _inner_error_;
	XSAAServer * self;
	g_return_val_if_fail (socket_name != NULL, NULL);
	_inner_error_ = NULL;
	unlink (socket_name);
	self = (XSAAServer*) xsaa_socket_construct (object_type, socket_name, error);
	fcntl (((XSAASocket*) self)->fd, F_SETFD, FD_CLOEXEC, NULL);
	if (bind (((XSAASocket*) self)->fd, (struct sockaddr*) ((XSAASocket*) self)->saddr, 110) != 0) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_SOCKET_ERROR, XSAA_SOCKET_ERROR_CREATE, "error on bind socket");
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
	if (listen (((XSAASocket*) self)->fd, 5) != 0) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_SOCKET_ERROR, XSAA_SOCKET_ERROR_CREATE, "error on listen socket");
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
	chmod (socket_name, (mode_t) 0666);
	g_signal_connect_object ((XSAASocket*) self, "in", (GCallback) _xsaa_server_on_client_connect_xsaa_socket_in, self, 0);
	return self;
}


XSAAServer* xsaa_server_new (const char* socket_name, GError** error) {
	return xsaa_server_construct (XSAA_TYPE_SERVER, socket_name, error);
}


static gboolean _xsaa_server_on_client_message_gio_func (GIOChannel* source, GIOCondition condition, gpointer self) {
	return xsaa_server_on_client_message (self, source, condition);
}


static void xsaa_server_on_client_connect (XSAAServer* self) {
	GError * _inner_error_;
	gint client;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	client = accept (((XSAASocket*) self)->fd, NULL, 0);
	if (client > 0) {
		{
			GIOChannel* ioc;
			ioc = g_io_channel_unix_new (client);
			g_io_channel_set_encoding (ioc, NULL, &_inner_error_);
			if (_inner_error_ != NULL) {
				(ioc == NULL) ? NULL : (ioc = (g_io_channel_unref (ioc), NULL));
				if (_inner_error_->domain == G_IO_CHANNEL_ERROR) {
					goto __catch0_g_io_channel_error;
				}
				goto __finally0;
			}
			g_io_channel_set_buffered (ioc, FALSE);
			g_io_channel_set_flags (ioc, g_io_channel_get_flags (ioc) | G_IO_FLAG_NONBLOCK, &_inner_error_);
			if (_inner_error_ != NULL) {
				(ioc == NULL) ? NULL : (ioc = (g_io_channel_unref (ioc), NULL));
				if (_inner_error_->domain == G_IO_CHANNEL_ERROR) {
					goto __catch0_g_io_channel_error;
				}
				goto __finally0;
			}
			g_io_add_watch (ioc, G_IO_IN, _xsaa_server_on_client_message_gio_func, self);
			(ioc == NULL) ? NULL : (ioc = (g_io_channel_unref (ioc), NULL));
		}
		goto __finally0;
		__catch0_g_io_channel_error:
		{
			GError * err;
			err = _inner_error_;
			_inner_error_ = NULL;
			{
				fprintf (stderr, "Error on accept\n");
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
			}
		}
		__finally0:
		if (_inner_error_ != NULL) {
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return;
		}
	}
}


static gboolean xsaa_server_on_client_message (XSAAServer* self, GIOChannel* client, GIOCondition condition) {
	gboolean result;
	GError * _inner_error_;
	gchar* _tmp0_;
	gint buffer_size;
	gint buffer_length1;
	gchar* buffer;
	gsize bytes_read;
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (client != NULL, FALSE);
	_inner_error_ = NULL;
	_tmp0_ = NULL;
	buffer = (_tmp0_ = g_new0 (gchar, xsaa_server_BUFFER_LENGTH), buffer_length1 = xsaa_server_BUFFER_LENGTH, buffer_size = buffer_length1, _tmp0_);
	bytes_read = (gsize) 0;
	{
		gboolean _tmp1_;
		g_io_channel_read_chars (client, buffer, buffer_length1, &bytes_read, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch1_g_error;
			goto __finally1;
		}
		_tmp1_ = FALSE;
		if (bytes_read > 0) {
			_tmp1_ = bytes_read < 200;
		} else {
			_tmp1_ = FALSE;
		}
		if (_tmp1_) {
			buffer[bytes_read] = (gchar) 0;
			xsaa_server_handle_client_message (self, client, (const char*) buffer);
		}
	}
	goto __finally1;
	__catch1_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on read socket\n");
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally1:
	if (_inner_error_ != NULL) {
		buffer = (g_free (buffer), NULL);
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return FALSE;
	}
	close (g_io_channel_unix_get_fd (client));
	result = FALSE;
	buffer = (g_free (buffer), NULL);
	return result;
}


static gboolean string_contains (const char* self, const char* needle) {
	gboolean result;
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (needle != NULL, FALSE);
	result = strstr (self, needle) != NULL;
	return result;
}


static void xsaa_server_handle_client_message (XSAAServer* self, GIOChannel* client, const char* buffer) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (client != NULL);
	g_return_if_fail (buffer != NULL);
	if (_vala_strcmp0 (buffer, "ping") == 0) {
		char* message;
		message = g_strdup ("pong");
		if (write (g_io_channel_unix_get_fd (client), message, (gsize) (g_utf8_strlen (message, -1) + 1)) == 0) {
			fprintf (stderr, "Error on send pong");
		}
		message = (g_free (message), NULL);
	}
	if (string_contains (buffer, "phase=")) {
		gint _tmp1__length1;
		char** _tmp1_;
		char** _tmp0_;
		gint _tmp2_;
		gint val;
		_tmp1_ = NULL;
		_tmp0_ = NULL;
		val = (_tmp2_ = atoi ((_tmp1_ = _tmp0_ = g_strsplit (buffer, "=", 0), _tmp1__length1 = _vala_array_length (_tmp0_), _tmp1_)[1]), _tmp1_ = (_vala_array_free (_tmp1_, _tmp1__length1, (GDestroyNotify) g_free), NULL), _tmp2_);
		g_signal_emit_by_name (self, "phase", val);
	}
	if (string_contains (buffer, "progress=")) {
		gint _tmp4__length1;
		char** _tmp4_;
		char** _tmp3_;
		gint _tmp5_;
		gint val;
		_tmp4_ = NULL;
		_tmp3_ = NULL;
		val = (_tmp5_ = atoi ((_tmp4_ = _tmp3_ = g_strsplit (buffer, "=", 0), _tmp4__length1 = _vala_array_length (_tmp3_), _tmp4_)[1]), _tmp4_ = (_vala_array_free (_tmp4_, _tmp4__length1, (GDestroyNotify) g_free), NULL), _tmp5_);
		g_signal_emit_by_name (self, "progress", val);
	}
	if (_vala_strcmp0 (buffer, "left-to-right") == 0) {
		g_signal_emit_by_name (self, "progress-orientation", GTK_PROGRESS_LEFT_TO_RIGHT);
	}
	if (_vala_strcmp0 (buffer, "right-to-left") == 0) {
		g_signal_emit_by_name (self, "progress-orientation", GTK_PROGRESS_RIGHT_TO_LEFT);
	}
	if (_vala_strcmp0 (buffer, "pulse") == 0) {
		g_signal_emit_by_name (self, "pulse");
	}
	if (_vala_strcmp0 (buffer, "dbus") == 0) {
		g_signal_emit_by_name (self, "dbus");
	}
	if (_vala_strcmp0 (buffer, "session") == 0) {
		g_signal_emit_by_name (self, "session");
	}
	if (_vala_strcmp0 (buffer, "close-session") == 0) {
		g_signal_emit_by_name (self, "close-session");
	}
	if (_vala_strcmp0 (buffer, "quit") == 0) {
		g_signal_emit_by_name (self, "quit");
	}
}


static void xsaa_server_class_init (XSAAServerClass * klass) {
	xsaa_server_parent_class = g_type_class_peek_parent (klass);
	G_OBJECT_CLASS (klass)->finalize = xsaa_server_finalize;
	g_signal_new ("phase", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__INT, G_TYPE_NONE, 1, G_TYPE_INT);
	g_signal_new ("progress", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__INT, G_TYPE_NONE, 1, G_TYPE_INT);
	g_signal_new ("progress_orientation", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__ENUM, G_TYPE_NONE, 1, GTK_TYPE_PROGRESS_BAR_ORIENTATION);
	g_signal_new ("dbus", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("session", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("pulse", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("close_session", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("quit", XSAA_TYPE_SERVER, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
}


static void xsaa_server_instance_init (XSAAServer * self) {
}


static void xsaa_server_finalize (GObject* obj) {
	XSAAServer * self;
	self = XSAA_SERVER (obj);
	{
		unlink (((XSAASocket*) self)->filename);
	}
	G_OBJECT_CLASS (xsaa_server_parent_class)->finalize (obj);
}


GType xsaa_server_get_type (void) {
	static GType xsaa_server_type_id = 0;
	if (xsaa_server_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAAServerClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_server_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAAServer), 0, (GInstanceInitFunc) xsaa_server_instance_init, NULL };
		xsaa_server_type_id = g_type_register_static (XSAA_TYPE_SOCKET, "XSAAServer", &g_define_type_info, 0);
	}
	return xsaa_server_type_id;
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


static int _vala_strcmp0 (const char * str1, const char * str2) {
	if (str1 == NULL) {
		return -(str1 != str2);
	}
	if (str2 == NULL) {
		return str1 != str2;
	}
	return strcmp (str1, str2);
}




