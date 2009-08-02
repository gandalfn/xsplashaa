/* xsaa-display.vala
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
#include <signal.h>
#include <sys/wait.h>
#include <stdio.h>
#include <fcntl.h>
#include <stropts.h>
#include <linux/kd.h>
#include <termios.h>
#include <unistd.h>


#define XSAA_TYPE_DISPLAY (xsaa_display_get_type ())
#define XSAA_DISPLAY(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_DISPLAY, XSAADisplay))
#define XSAA_DISPLAY_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_DISPLAY, XSAADisplayClass))
#define XSAA_IS_DISPLAY(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_DISPLAY))
#define XSAA_IS_DISPLAY_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_DISPLAY))
#define XSAA_DISPLAY_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_DISPLAY, XSAADisplayClass))

typedef struct _XSAADisplay XSAADisplay;
typedef struct _XSAADisplayClass XSAADisplayClass;
typedef struct _XSAADisplayPrivate XSAADisplayPrivate;

typedef enum  {
	XSAA_DISPLAY_ERROR_COMMAND,
	XSAA_DISPLAY_ERROR_LAUNCH
} XSAADisplayError;
#define XSAA_DISPLAY_ERROR xsaa_display_error_quark ()
struct _XSAADisplay {
	GObject parent_instance;
	XSAADisplayPrivate * priv;
};

struct _XSAADisplayClass {
	GObjectClass parent_class;
};

struct _XSAADisplayPrivate {
	guint sig_handled;
	GPid pid;
	gint number;
};


static gboolean xsaa_display_is_ready;
static gboolean xsaa_display_is_ready = FALSE;
static gpointer xsaa_display_parent_class = NULL;

GQuark xsaa_display_error_quark (void);
GType xsaa_display_get_type (void);
#define XSAA_DISPLAY_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_DISPLAY, XSAADisplayPrivate))
enum  {
	XSAA_DISPLAY_DUMMY_PROPERTY
};
static gboolean xsaa_display_get_running_pid (XSAADisplay* self);
static gboolean xsaa_display_on_wait_is_ready (XSAADisplay* self);
static gboolean _xsaa_display_on_wait_is_ready_gsource_func (gpointer self);
static void xsaa_display_on_sig_usr1 (gint signum);
static void _xsaa_display_on_sig_usr1_sighandler_t (gint signal);
static void xsaa_display_on_child_setup (XSAADisplay* self);
static void _xsaa_display_on_child_setup_gspawn_child_setup_func (gpointer self);
static void xsaa_display_on_child_watch (XSAADisplay* self, GPid pid, gint status);
static void _xsaa_display_on_child_watch_gchild_watch_func (GPid pid, gint status, gpointer self);
XSAADisplay* xsaa_display_new (const char* cmd, gint number, GError** error);
XSAADisplay* xsaa_display_construct (GType object_type, const char* cmd, gint number, GError** error);
char* xsaa_display_get_device (XSAADisplay* self);
static void xsaa_display_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);



GQuark xsaa_display_error_quark (void) {
	return g_quark_from_static_string ("xsaa_display_error-quark");
}


static gboolean _xsaa_display_on_wait_is_ready_gsource_func (gpointer self) {
	return xsaa_display_on_wait_is_ready (self);
}


static void _xsaa_display_on_sig_usr1_sighandler_t (gint signal) {
	xsaa_display_on_sig_usr1 (signal);
}


static void _xsaa_display_on_child_setup_gspawn_child_setup_func (gpointer self) {
	xsaa_display_on_child_setup (self);
}


static void _xsaa_display_on_child_watch_gchild_watch_func (GPid pid, gint status, gpointer self) {
	xsaa_display_on_child_watch (self, pid, status);
}


XSAADisplay* xsaa_display_construct (GType object_type, const char* cmd, gint number, GError** error) {
	GError * _inner_error_;
	XSAADisplay * self;
	g_return_val_if_fail (cmd != NULL, NULL);
	_inner_error_ = NULL;
	self = g_object_newv (object_type, 0, NULL);
	self->priv->number = number;
	if (self->priv->sig_handled == 0) {
		if (!xsaa_display_get_running_pid (self)) {
			gint argvp_size;
			gint argvp_length1;
			char** argvp;
			argvp = (argvp_length1 = 0, NULL);
			{
				g_shell_parse_argv (cmd, &argvp_length1, &argvp, &_inner_error_);
				if (_inner_error_ != NULL) {
					if (_inner_error_->domain == G_SHELL_ERROR) {
						goto __catch2_g_shell_error;
					}
					goto __finally2;
				}
			}
			goto __finally2;
			__catch2_g_shell_error:
			{
				GError * err;
				err = _inner_error_;
				_inner_error_ = NULL;
				{
					_inner_error_ = g_error_new (XSAA_DISPLAY_ERROR, XSAA_DISPLAY_ERROR_COMMAND, "Invalid %s command !!", cmd);
					if (_inner_error_ != NULL) {
						(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
						argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
						goto __finally2;
					}
					(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
				}
			}
			__finally2:
			if (_inner_error_ != NULL) {
				if (_inner_error_->domain == XSAA_DISPLAY_ERROR) {
					g_propagate_error (error, _inner_error_);
					argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
					return;
				} else {
					argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
					g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
					g_clear_error (&_inner_error_);
					return NULL;
				}
			}
			self->priv->sig_handled = g_idle_add (_xsaa_display_on_wait_is_ready_gsource_func, self);
			signal (SIGUSR1, _xsaa_display_on_sig_usr1_sighandler_t);
			{
				g_spawn_async (NULL, argvp, NULL, G_SPAWN_SEARCH_PATH | G_SPAWN_DO_NOT_REAP_CHILD, _xsaa_display_on_child_setup_gspawn_child_setup_func, self, &self->priv->pid, &_inner_error_);
				if (_inner_error_ != NULL) {
					if (_inner_error_->domain == G_SPAWN_ERROR) {
						goto __catch3_g_spawn_error;
					}
					goto __finally3;
				}
				g_child_watch_add ((GPid) self->priv->pid, _xsaa_display_on_child_watch_gchild_watch_func, self);
			}
			goto __finally3;
			__catch3_g_spawn_error:
			{
				GError * err;
				err = _inner_error_;
				_inner_error_ = NULL;
				{
					g_source_remove (self->priv->sig_handled);
					self->priv->sig_handled = (guint) (-1);
					signal (SIGUSR1, SIG_IGN);
					_inner_error_ = g_error_new_literal (XSAA_DISPLAY_ERROR, XSAA_DISPLAY_ERROR_LAUNCH, err->message);
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
				if (_inner_error_->domain == XSAA_DISPLAY_ERROR) {
					g_propagate_error (error, _inner_error_);
					argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
					return;
				} else {
					argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
					g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
					g_clear_error (&_inner_error_);
					return NULL;
				}
			}
			argvp = (_vala_array_free (argvp, argvp_length1, (GDestroyNotify) g_free), NULL);
		} else {
			self->priv->sig_handled = g_idle_add (_xsaa_display_on_wait_is_ready_gsource_func, self);
			xsaa_display_is_ready = TRUE;
		}
	}
	return self;
}


XSAADisplay* xsaa_display_new (const char* cmd, gint number, GError** error) {
	return xsaa_display_construct (XSAA_TYPE_DISPLAY, cmd, number, error);
}


static void xsaa_display_on_child_setup (XSAADisplay* self) {
	g_return_if_fail (self != NULL);
	signal (SIGTERM, SIG_IGN);
	signal (SIGUSR1, SIG_IGN);
	signal (SIGINT, SIG_IGN);
	signal (SIGTTIN, SIG_IGN);
	signal (SIGTTOU, SIG_IGN);
}


static void xsaa_display_on_child_watch (XSAADisplay* self, GPid pid, gint status) {
	g_return_if_fail (self != NULL);
	if (WIFEXITED (status)) {
		fprintf (stderr, "Display exited : %i", status);
		g_signal_emit_by_name (self, "exited");
	} else {
		if (WIFSIGNALED (status)) {
			fprintf (stderr, "Display signaled : %i", status);
			g_signal_emit_by_name (self, "died");
		}
	}
	g_spawn_close_pid (pid);
	self->priv->pid = (GPid) 0;
}


static gboolean xsaa_display_on_wait_is_ready (XSAADisplay* self) {
	gboolean result;
	g_return_val_if_fail (self != NULL, FALSE);
	if (xsaa_display_is_ready) {
		g_signal_emit_by_name (self, "ready");
	}
	self->priv->sig_handled = (guint) 0;
	result = !xsaa_display_is_ready;
	return result;
}


static void xsaa_display_on_sig_usr1 (gint signum) {
	if (signum == SIGUSR1) {
		xsaa_display_is_ready = TRUE;
	}
}


static gboolean xsaa_display_get_running_pid (XSAADisplay* self) {
	gboolean result;
	GError * _inner_error_;
	char* spid;
	g_return_val_if_fail (self != NULL, FALSE);
	_inner_error_ = NULL;
	spid = NULL;
	{
		char* _tmp1_;
		char* _tmp0_;
		char* _tmp4_;
		gboolean _tmp3_;
		char* _tmp2_;
		_tmp1_ = NULL;
		_tmp0_ = NULL;
		setenv ("DISPLAY", _tmp1_ = g_strconcat (":", _tmp0_ = g_strdup_printf ("%i", self->priv->number), NULL), 1);
		_tmp1_ = (g_free (_tmp1_), NULL);
		_tmp0_ = (g_free (_tmp0_), NULL);
		_tmp4_ = NULL;
		_tmp2_ = NULL;
		_tmp3_ = g_spawn_command_line_sync ("/usr/lib/ConsoleKit/ck-get-x11-server-pid", &_tmp2_, NULL, NULL, &_inner_error_);
		spid = (_tmp4_ = _tmp2_, spid = (g_free (spid), NULL), _tmp4_);
		_tmp3_;
		if (_inner_error_ != NULL) {
			goto __catch4_g_error;
			goto __finally4;
		}
		g_strstrip (spid);
		fprintf (stderr, "Found X server at pid %s\n", spid);
		if (spid != NULL) {
			self->priv->pid = (GPid) atoi (spid);
			result = ((gint) self->priv->pid) > 0;
			spid = (g_free (spid), NULL);
			return result;
		}
	}
	goto __finally4;
	__catch4_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on get display pid: %s\n", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally4:
	if (_inner_error_ != NULL) {
		spid = (g_free (spid), NULL);
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return FALSE;
	}
	result = FALSE;
	spid = (g_free (spid), NULL);
	return result;
}


char* xsaa_display_get_device (XSAADisplay* self) {
	char* result;
	GError * _inner_error_;
	char* device;
	g_return_val_if_fail (self != NULL, NULL);
	_inner_error_ = NULL;
	device = NULL;
	{
		char* _tmp4_;
		gboolean _tmp3_;
		char* _tmp2_;
		char* _tmp1_;
		char* _tmp0_;
		gint fd;
		_tmp4_ = NULL;
		_tmp2_ = NULL;
		_tmp1_ = NULL;
		_tmp0_ = NULL;
		_tmp3_ = g_spawn_command_line_sync (_tmp1_ = g_strconcat ("/usr/lib/ConsoleKit/ck-get-x11-display-device --display=:", _tmp0_ = g_strdup_printf ("%i", self->priv->number), NULL), &_tmp2_, NULL, NULL, &_inner_error_);
		device = (_tmp4_ = _tmp2_, device = (g_free (device), NULL), _tmp4_);
		_tmp3_;
		if (_inner_error_ != NULL) {
			goto __catch5_g_error;
			goto __finally5;
		}
		_tmp1_ = (g_free (_tmp1_), NULL);
		_tmp0_ = (g_free (_tmp0_), NULL);
		g_strstrip (device);
		fd = open (device, O_RDWR, 0);
		if (fd > 0) {
			struct termios tty_attr = {0};
			if (ioctl (fd, KDSETMODE, KD_GRAPHICS) < 0) {
				fprintf (stderr, "KDSETMODE KD_GRAPHICS failed !");
			}
			if (ioctl (fd, KDSKBMODE, K_RAW) < 0) {
				fprintf (stderr, "KDSETMODE KD_RAW failed !");
			}
			ioctl (fd, KDGKBMODE, &tty_attr);
			tty_attr.c_iflag = ((IGNPAR | IGNBRK) & (~PARMRK)) & (~ISTRIP);
			tty_attr.c_oflag = (tcflag_t) 0;
			tty_attr.c_cflag = CREAD | CS8;
			tty_attr.c_lflag = (tcflag_t) 0;
			tty_attr.c_cc[VTIME] = (cc_t) 0;
			tty_attr.c_cc[VMIN] = (cc_t) 1;
			cfsetispeed (&tty_attr, (speed_t) 9600);
			cfsetospeed (&tty_attr, (speed_t) 9600);
			tcsetattr (fd, TCSANOW, &tty_attr);
			close (fd);
		}
	}
	goto __finally5;
	__catch5_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on get display device: %s\n", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally5:
	if (_inner_error_ != NULL) {
		device = (g_free (device), NULL);
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return NULL;
	}
	result = device;
	return result;
}


static void xsaa_display_class_init (XSAADisplayClass * klass) {
	xsaa_display_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAADisplayPrivate));
	G_OBJECT_CLASS (klass)->finalize = xsaa_display_finalize;
	g_signal_new ("ready", XSAA_TYPE_DISPLAY, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("exited", XSAA_TYPE_DISPLAY, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("died", XSAA_TYPE_DISPLAY, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
}


static void xsaa_display_instance_init (XSAADisplay * self) {
	self->priv = XSAA_DISPLAY_GET_PRIVATE (self);
	self->priv->sig_handled = (guint) 0;
	self->priv->pid = (GPid) 0;
}


static void xsaa_display_finalize (GObject* obj) {
	XSAADisplay * self;
	self = XSAA_DISPLAY (obj);
	{
		if (((gint) self->priv->pid) > 0) {
			kill ((pid_t) self->priv->pid, SIGTERM);
		}
	}
	G_OBJECT_CLASS (xsaa_display_parent_class)->finalize (obj);
}


GType xsaa_display_get_type (void) {
	static GType xsaa_display_type_id = 0;
	if (xsaa_display_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAADisplayClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_display_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAADisplay), 0, (GInstanceInitFunc) xsaa_display_instance_init, NULL };
		xsaa_display_type_id = g_type_register_static (G_TYPE_OBJECT, "XSAADisplay", &g_define_type_info, 0);
	}
	return xsaa_display_type_id;
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




