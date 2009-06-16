/* xsaa-socket.vala
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
#include <sys/socket.h>
#include <unistd.h>
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

typedef enum  {
	XSAA_SOCKET_ERROR_INVALID_NAME,
	XSAA_SOCKET_ERROR_CREATE
} XSAASocketError;
#define XSAA_SOCKET_ERROR xsaa_socket_error_quark ()
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



GQuark xsaa_socket_error_quark (void);
GType xsaa_socket_get_type (void);
enum  {
	XSAA_SOCKET_DUMMY_PROPERTY
};
static gint xsaa_socket_BUFFER_LENGTH;
static gint xsaa_socket_BUFFER_LENGTH = 200;
static gboolean xsaa_socket_on_in_data (XSAASocket* self, GIOChannel* client, GIOCondition condition);
static gboolean _xsaa_socket_on_in_data_gio_func (GIOChannel* source, GIOCondition condition, gpointer self);
XSAASocket* xsaa_socket_new (const char* socket_name, GError** error);
XSAASocket* xsaa_socket_construct (GType object_type, const char* socket_name, GError** error);
XSAASocket* xsaa_socket_new (const char* socket_name, GError** error);
gboolean xsaa_socket_send (XSAASocket* self, const char* message);
gboolean xsaa_socket_recv (XSAASocket* self, char** message);
static gpointer xsaa_socket_parent_class = NULL;
static void xsaa_socket_finalize (GObject* obj);



GQuark xsaa_socket_error_quark (void) {
	return g_quark_from_static_string ("xsaa_socket_error-quark");
}


static gboolean _xsaa_socket_on_in_data_gio_func (GIOChannel* source, GIOCondition condition, gpointer self) {
	return xsaa_socket_on_in_data (self, source, condition);
}


XSAASocket* xsaa_socket_construct (GType object_type, const char* socket_name, GError** error) {
	GError * _inner_error_;
	XSAASocket * self;
	gint state;
	char* _tmp1_;
	const char* _tmp0_;
	struct sockaddr_un* _tmp2_;
	GIOChannel* _tmp3_;
	g_return_val_if_fail (socket_name != NULL, NULL);
	_inner_error_ = NULL;
	self = g_object_newv (object_type, 0, NULL);
	state = 1;
	if (g_utf8_strlen (socket_name, -1) == 0) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new_literal (XSAA_SOCKET_ERROR, XSAA_SOCKET_ERROR_INVALID_NAME, "error socket name is empty");
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
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->filename = (_tmp1_ = (_tmp0_ = socket_name, (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_)), self->filename = (g_free (self->filename), NULL), _tmp1_);
	self->fd = socket (PF_UNIX, SOCK_STREAM, 0);
	if (self->fd < 0) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new (XSAA_SOCKET_ERROR, XSAA_SOCKET_ERROR_CREATE, "error on create socket %s", socket_name);
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
	if (setsockopt (self->fd, SOL_SOCKET, SO_REUSEADDR, &state, (gsize) sizeof (gint)) != 0) {
		g_object_unref ((GObject*) self);
		_inner_error_ = g_error_new (XSAA_SOCKET_ERROR, XSAA_SOCKET_ERROR_CREATE, "error on setsockopt socket %s", socket_name);
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
	_tmp2_ = NULL;
	self->saddr = (_tmp2_ = g_new0 (struct sockaddr_un, 1), self->saddr = (g_free (self->saddr), NULL), _tmp2_);
	self->saddr->sun_family = AF_UNIX;
	memcpy (self->saddr->sun_path, socket_name, (gsize) g_utf8_strlen (socket_name, -1));
	_tmp3_ = NULL;
	self->ioc = (_tmp3_ = g_io_channel_unix_new (self->fd), (self->ioc == NULL) ? NULL : (self->ioc = (g_io_channel_unref (self->ioc), NULL)), _tmp3_);
	g_io_channel_set_encoding (self->ioc, NULL, &_inner_error_);
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
	g_io_channel_set_buffered (self->ioc, FALSE);
	g_io_add_watch (self->ioc, G_IO_IN, _xsaa_socket_on_in_data_gio_func, self);
	return self;
}


XSAASocket* xsaa_socket_new (const char* socket_name, GError** error) {
	return xsaa_socket_construct (XSAA_TYPE_SOCKET, socket_name, error);
}


static gboolean xsaa_socket_on_in_data (XSAASocket* self, GIOChannel* client, GIOCondition condition) {
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (client != NULL, FALSE);
	g_signal_emit_by_name (self, "in");
	return TRUE;
}


gboolean xsaa_socket_send (XSAASocket* self, const char* message) {
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (message != NULL, FALSE);
	return write (self->fd, message, (gsize) (g_utf8_strlen (message, -1) + 1)) > 0;
}


gboolean xsaa_socket_recv (XSAASocket* self, char** message) {
	GError * _inner_error_;
	gchar* _tmp0_;
	gint buffer_size;
	gint buffer_length1;
	gchar* buffer;
	gsize bytes_read;
	gboolean _tmp5_;
	g_return_val_if_fail (self != NULL, FALSE);
	if (message != NULL) {
		*message = NULL;
	}
	_inner_error_ = NULL;
	_tmp0_ = NULL;
	buffer = (_tmp0_ = g_new0 (gchar, xsaa_socket_BUFFER_LENGTH), buffer_length1 = xsaa_socket_BUFFER_LENGTH, buffer_size = buffer_length1, _tmp0_);
	bytes_read = (gsize) 0;
	{
		gboolean _tmp1_;
		g_io_channel_read_chars (self->ioc, buffer, buffer_length1, &bytes_read, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch0_g_error;
			goto __finally0;
		}
		_tmp1_ = FALSE;
		if (bytes_read > 0) {
			_tmp1_ = bytes_read < 200;
		} else {
			_tmp1_ = FALSE;
		}
		if (_tmp1_) {
			char* _tmp3_;
			const char* _tmp2_;
			gboolean _tmp4_;
			buffer[bytes_read] = (gchar) 0;
			_tmp3_ = NULL;
			_tmp2_ = NULL;
			(*message) = (_tmp3_ = (_tmp2_ = (const char*) buffer, (_tmp2_ == NULL) ? NULL : g_strdup (_tmp2_)), (*message) = (g_free ((*message)), NULL), _tmp3_);
			return (_tmp4_ = TRUE, buffer = (g_free (buffer), NULL), _tmp4_);
		}
	}
	goto __finally0;
	__catch0_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on read socket\n");
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally0:
	if (_inner_error_ != NULL) {
		buffer = (g_free (buffer), NULL);
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return FALSE;
	}
	return (_tmp5_ = FALSE, buffer = (g_free (buffer), NULL), _tmp5_);
}


static void xsaa_socket_class_init (XSAASocketClass * klass) {
	xsaa_socket_parent_class = g_type_class_peek_parent (klass);
	G_OBJECT_CLASS (klass)->finalize = xsaa_socket_finalize;
	g_signal_new ("in", XSAA_TYPE_SOCKET, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
}


static void xsaa_socket_instance_init (XSAASocket * self) {
	self->fd = 0;
}


static void xsaa_socket_finalize (GObject* obj) {
	XSAASocket * self;
	self = XSAA_SOCKET (obj);
	{
		if (self->fd > 0) {
			close (self->fd);
		}
	}
	self->filename = (g_free (self->filename), NULL);
	self->saddr = (g_free (self->saddr), NULL);
	(self->ioc == NULL) ? NULL : (self->ioc = (g_io_channel_unref (self->ioc), NULL));
	G_OBJECT_CLASS (xsaa_socket_parent_class)->finalize (obj);
}


GType xsaa_socket_get_type (void) {
	static GType xsaa_socket_type_id = 0;
	if (xsaa_socket_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAASocketClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_socket_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAASocket), 0, (GInstanceInitFunc) xsaa_socket_instance_init, NULL };
		xsaa_socket_type_id = g_type_register_static (G_TYPE_OBJECT, "XSAASocket", &g_define_type_info, 0);
	}
	return xsaa_socket_type_id;
}




