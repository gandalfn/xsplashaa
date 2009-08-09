/* xsaa-splash.vala
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
#include <gtk/gtk.h>
#include <xsaa-private.h>
#include <vala-widgets/ssi-vala-widgets.h>
#include <stdlib.h>
#include <string.h>
#include <float.h>
#include <math.h>
#include <glib/gstdio.h>
#include <config.h>
#include <stdio.h>
#include <gdk/gdk.h>
#include <gdk-pixbuf/gdk-pixdata.h>


#define XSAA_TYPE_SPLASH (xsaa_splash_get_type ())
#define XSAA_SPLASH(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SPLASH, XSAASplash))
#define XSAA_SPLASH_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SPLASH, XSAASplashClass))
#define XSAA_IS_SPLASH(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SPLASH))
#define XSAA_IS_SPLASH_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SPLASH))
#define XSAA_SPLASH_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SPLASH, XSAASplashClass))

typedef struct _XSAASplash XSAASplash;
typedef struct _XSAASplashClass XSAASplashClass;
typedef struct _XSAASplashPrivate XSAASplashPrivate;

#define XSAA_TYPE_SERVER (xsaa_server_get_type ())
#define XSAA_SERVER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SERVER, XSAAServer))
#define XSAA_SERVER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SERVER, XSAAServerClass))
#define XSAA_IS_SERVER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SERVER))
#define XSAA_IS_SERVER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SERVER))
#define XSAA_SERVER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SERVER, XSAAServerClass))

typedef struct _XSAAServer XSAAServer;
typedef struct _XSAAServerClass XSAAServerClass;

#define XSAA_TYPE_THROBBER (xsaa_throbber_get_type ())
#define XSAA_THROBBER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_THROBBER, XSAAThrobber))
#define XSAA_THROBBER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_THROBBER, XSAAThrobberClass))
#define XSAA_IS_THROBBER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_THROBBER))
#define XSAA_IS_THROBBER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_THROBBER))
#define XSAA_THROBBER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_THROBBER, XSAAThrobberClass))

typedef struct _XSAAThrobber XSAAThrobber;
typedef struct _XSAAThrobberClass XSAAThrobberClass;

struct _XSAASplash {
	GtkWindow parent_instance;
	XSAASplashPrivate * priv;
};

struct _XSAASplashClass {
	GtkWindowClass parent_class;
};

struct _XSAASplashPrivate {
	XSAAServer* socket;
	XSAAThrobber** phase;
	gint phase_length1;
	gint phase_size;
	XSAAThrobber* throbber_session;
	XSAAThrobber* throbber_shutdown;
	gint current_phase;
	GtkProgressBar* progress;
	SSISlideNotebook* notebook;
	GtkLabel* label_prompt;
	GtkEntry* entry_prompt;
	char* username;
	GtkLabel* label_message;
	guint id_pulse;
	char* theme;
	char* bg;
	char* text;
	float yposition;
};


static gpointer xsaa_splash_parent_class = NULL;

GType xsaa_splash_get_type (void);
GType xsaa_server_get_type (void);
GType xsaa_throbber_get_type (void);
#define XSAA_SPLASH_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_SPLASH, XSAASplashPrivate))
enum  {
	XSAA_SPLASH_DUMMY_PROPERTY
};
static void xsaa_splash_on_phase_changed (XSAASplash* self, gint new_phase);
static void _xsaa_splash_on_phase_changed_xsaa_server_phase (XSAAServer* _sender, gint val, gpointer self);
static void xsaa_splash_on_start_pulse (XSAASplash* self);
static void _xsaa_splash_on_start_pulse_xsaa_server_pulse (XSAAServer* _sender, gpointer self);
static void xsaa_splash_on_progress (XSAASplash* self, gint val);
static void _xsaa_splash_on_progress_xsaa_server_progress (XSAAServer* _sender, gint val, gpointer self);
static void xsaa_splash_on_progress_orientation (XSAASplash* self, GtkProgressBarOrientation orientation);
static void _xsaa_splash_on_progress_orientation_xsaa_server_progress_orientation (XSAAServer* _sender, GtkProgressBarOrientation orientation, gpointer self);
XSAASplash* xsaa_splash_new (XSAAServer* server);
XSAASplash* xsaa_splash_construct (GType object_type, XSAAServer* server);
static void xsaa_splash_load_config (XSAASplash* self);
XSAAThrobber* xsaa_throbber_new (const char* name, guint interval, GError** error);
XSAAThrobber* xsaa_throbber_construct (GType object_type, const char* name, guint interval, GError** error);
void xsaa_throbber_start (XSAAThrobber* self);
static void xsaa_splash_construct_loading_page (XSAASplash* self);
static void xsaa_splash_on_restart_clicked (XSAASplash* self);
static void _xsaa_splash_on_restart_clicked_gtk_button_clicked (GtkButton* _sender, gpointer self);
static void xsaa_splash_on_shutdown_clicked (XSAASplash* self);
static void _xsaa_splash_on_shutdown_clicked_gtk_button_clicked (GtkButton* _sender, gpointer self);
static void xsaa_splash_construct_login_page (XSAASplash* self);
static void xsaa_splash_construct_launch_session_page (XSAASplash* self);
static void xsaa_splash_construct_shutdown_page (XSAASplash* self);
void xsaa_throbber_finished (XSAAThrobber* self);
static gboolean xsaa_splash_on_pulse (XSAASplash* self);
static gboolean _xsaa_splash_on_pulse_gsource_func (gpointer self);
static void xsaa_splash_on_login_enter (XSAASplash* self);
static void _xsaa_splash_on_login_enter_gtk_entry_activate (GtkEntry* _sender, gpointer self);
static void xsaa_splash_on_passwd_enter (XSAASplash* self);
static void _xsaa_splash_on_passwd_enter_gtk_entry_activate (GtkEntry* _sender, gpointer self);
static void xsaa_splash_real_realize (GtkWidget* base);
void xsaa_splash_show_launch (XSAASplash* self);
void xsaa_splash_show_shutdown (XSAASplash* self);
void xsaa_splash_ask_for_login (XSAASplash* self);
void xsaa_splash_login_message (XSAASplash* self, const char* msg);
static void _gtk_main_quit_gtk_object_destroy (XSAASplash* _sender, gpointer self);
static GObject * xsaa_splash_constructor (GType type, guint n_construct_properties, GObjectConstructParam * construct_properties);
static void xsaa_splash_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);


static void g_cclosure_user_marshal_VOID__STRING_STRING (GClosure * closure, GValue * return_value, guint n_param_values, const GValue * param_values, gpointer invocation_hint, gpointer marshal_data);

static void _xsaa_splash_on_phase_changed_xsaa_server_phase (XSAAServer* _sender, gint val, gpointer self) {
	xsaa_splash_on_phase_changed (self, val);
}


static void _xsaa_splash_on_start_pulse_xsaa_server_pulse (XSAAServer* _sender, gpointer self) {
	xsaa_splash_on_start_pulse (self);
}


static void _xsaa_splash_on_progress_xsaa_server_progress (XSAAServer* _sender, gint val, gpointer self) {
	xsaa_splash_on_progress (self, val);
}


static void _xsaa_splash_on_progress_orientation_xsaa_server_progress_orientation (XSAAServer* _sender, GtkProgressBarOrientation orientation, gpointer self) {
	xsaa_splash_on_progress_orientation (self, orientation);
}


XSAASplash* xsaa_splash_construct (GType object_type, XSAAServer* server) {
	XSAASplash * self;
	XSAAServer* _tmp1_;
	XSAAServer* _tmp0_;
	g_return_val_if_fail (server != NULL, NULL);
	self = g_object_newv (object_type, 0, NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->socket = (_tmp1_ = (_tmp0_ = server, (_tmp0_ == NULL) ? NULL : g_object_ref (_tmp0_)), (self->priv->socket == NULL) ? NULL : (self->priv->socket = (g_object_unref (self->priv->socket), NULL)), _tmp1_);
	g_signal_connect_object (self->priv->socket, "phase", (GCallback) _xsaa_splash_on_phase_changed_xsaa_server_phase, self, 0);
	g_signal_connect_object (self->priv->socket, "pulse", (GCallback) _xsaa_splash_on_start_pulse_xsaa_server_pulse, self, 0);
	g_signal_connect_object (self->priv->socket, "progress", (GCallback) _xsaa_splash_on_progress_xsaa_server_progress, self, 0);
	g_signal_connect_object (self->priv->socket, "progress-orientation", (GCallback) _xsaa_splash_on_progress_orientation_xsaa_server_progress_orientation, self, 0);
	return self;
}


XSAASplash* xsaa_splash_new (XSAAServer* server) {
	return xsaa_splash_construct (XSAA_TYPE_SPLASH, server);
}


static void xsaa_splash_load_config (XSAASplash* self) {
	GError * _inner_error_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	if (g_file_test (PACKAGE_CONFIG_FILE, G_FILE_TEST_EXISTS)) {
		{
			GKeyFile* config;
			char* _tmp0_;
			char* _tmp1_;
			char* _tmp2_;
			char* _tmp3_;
			char* _tmp4_;
			char* _tmp5_;
			double _tmp6_;
			config = g_key_file_new ();
			g_key_file_load_from_file (config, PACKAGE_CONFIG_FILE, G_KEY_FILE_NONE, &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch6_g_error;
				goto __finally6;
			}
			_tmp0_ = g_key_file_get_string (config, "splash", "theme", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch6_g_error;
				goto __finally6;
			}
			_tmp1_ = NULL;
			self->priv->theme = (_tmp1_ = _tmp0_, self->priv->theme = (g_free (self->priv->theme), NULL), _tmp1_);
			_tmp2_ = g_key_file_get_string (config, "splash", "background", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch6_g_error;
				goto __finally6;
			}
			_tmp3_ = NULL;
			self->priv->bg = (_tmp3_ = _tmp2_, self->priv->bg = (g_free (self->priv->bg), NULL), _tmp3_);
			_tmp4_ = g_key_file_get_string (config, "splash", "text", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch6_g_error;
				goto __finally6;
			}
			_tmp5_ = NULL;
			self->priv->text = (_tmp5_ = _tmp4_, self->priv->text = (g_free (self->priv->text), NULL), _tmp5_);
			_tmp6_ = g_key_file_get_double (config, "splash", "yposition", &_inner_error_);
			if (_inner_error_ != NULL) {
				(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
				goto __catch6_g_error;
				goto __finally6;
			}
			self->priv->yposition = (float) _tmp6_;
			(config == NULL) ? NULL : (config = (g_key_file_free (config), NULL));
		}
		goto __finally6;
		__catch6_g_error:
		{
			GError * err;
			err = _inner_error_;
			_inner_error_ = NULL;
			{
				fprintf (stderr, "Error on read %s: %s", PACKAGE_CONFIG_FILE, err->message);
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
			}
		}
		__finally6:
		if (_inner_error_ != NULL) {
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
			return;
		}
	}
}


static void xsaa_splash_construct_loading_page (XSAASplash* self) {
	GError * _inner_error_;
	GtkTable* table;
	char* _tmp1_;
	char* _tmp0_;
	GtkLabel* _tmp2_;
	GtkLabel* label;
	GtkLabel* _tmp7_;
	char* _tmp6_;
	char* _tmp5_;
	GtkLabel* _tmp12_;
	char* _tmp11_;
	char* _tmp10_;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	table = g_object_ref_sink ((GtkTable*) gtk_table_new ((guint) 3, (guint) 2, FALSE));
	gtk_widget_show ((GtkWidget*) table);
	ssi_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) table, NULL);
	gtk_container_set_border_width ((GtkContainer*) table, (guint) 12);
	gtk_table_set_col_spacings (table, (guint) 12);
	gtk_table_set_row_spacings (table, (guint) 12);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	_tmp2_ = NULL;
	label = (_tmp2_ = g_object_ref_sink ((GtkLabel*) gtk_label_new (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Loading  ...</span>", NULL))), _tmp1_ = (g_free (_tmp1_), NULL), _tmp0_ = (g_free (_tmp0_), NULL), _tmp2_);
	gtk_label_set_use_markup (label, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) label, 0.0f, 0.5f);
	gtk_widget_show ((GtkWidget*) label);
	gtk_table_attach_defaults (table, (GtkWidget*) label, (guint) 0, (guint) 1, (guint) 0, (guint) 1);
	{
		XSAAThrobber* _tmp3_;
		XSAAThrobber* _tmp4_;
		_tmp3_ = g_object_ref_sink (xsaa_throbber_new (self->priv->theme, (guint) 83, &_inner_error_));
		if (_inner_error_ != NULL) {
			goto __catch7_g_error;
			goto __finally7;
		}
		_tmp4_ = NULL;
		self->priv->phase[0] = (_tmp4_ = g_object_ref_sink (_tmp3_), (self->priv->phase[0] == NULL) ? NULL : (self->priv->phase[0] = (g_object_unref (self->priv->phase[0]), NULL)), _tmp4_);
		gtk_widget_show ((GtkWidget*) self->priv->phase[0]);
		xsaa_throbber_start (self->priv->phase[0]);
		gtk_table_attach_defaults (table, (GtkWidget*) self->priv->phase[0], (guint) 1, (guint) 2, (guint) 0, (guint) 1);
	}
	goto __finally7;
	__catch7_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on loading throbber %s", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally7:
	if (_inner_error_ != NULL) {
		(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
		(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	_tmp7_ = NULL;
	_tmp6_ = NULL;
	_tmp5_ = NULL;
	label = (_tmp7_ = g_object_ref_sink ((GtkLabel*) gtk_label_new (_tmp6_ = g_strconcat (_tmp5_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Check filesystem ...</span>", NULL))), (label == NULL) ? NULL : (label = (g_object_unref (label), NULL)), _tmp7_);
	_tmp6_ = (g_free (_tmp6_), NULL);
	_tmp5_ = (g_free (_tmp5_), NULL);
	gtk_label_set_use_markup (label, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) label, 0.0f, 0.5f);
	gtk_widget_show ((GtkWidget*) label);
	gtk_table_attach_defaults (table, (GtkWidget*) label, (guint) 0, (guint) 1, (guint) 1, (guint) 2);
	{
		XSAAThrobber* _tmp8_;
		XSAAThrobber* _tmp9_;
		_tmp8_ = g_object_ref_sink (xsaa_throbber_new (self->priv->theme, (guint) 83, &_inner_error_));
		if (_inner_error_ != NULL) {
			goto __catch8_g_error;
			goto __finally8;
		}
		_tmp9_ = NULL;
		self->priv->phase[1] = (_tmp9_ = g_object_ref_sink (_tmp8_), (self->priv->phase[1] == NULL) ? NULL : (self->priv->phase[1] = (g_object_unref (self->priv->phase[1]), NULL)), _tmp9_);
		gtk_widget_show ((GtkWidget*) self->priv->phase[1]);
		gtk_table_attach_defaults (table, (GtkWidget*) self->priv->phase[1], (guint) 1, (guint) 2, (guint) 1, (guint) 2);
	}
	goto __finally8;
	__catch8_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on loading throbber %s", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally8:
	if (_inner_error_ != NULL) {
		(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
		(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	_tmp12_ = NULL;
	_tmp11_ = NULL;
	_tmp10_ = NULL;
	label = (_tmp12_ = g_object_ref_sink ((GtkLabel*) gtk_label_new (_tmp11_ = g_strconcat (_tmp10_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Start System ...</span>", NULL))), (label == NULL) ? NULL : (label = (g_object_unref (label), NULL)), _tmp12_);
	_tmp11_ = (g_free (_tmp11_), NULL);
	_tmp10_ = (g_free (_tmp10_), NULL);
	gtk_label_set_use_markup (label, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) label, 0.0f, 0.5f);
	gtk_widget_show ((GtkWidget*) label);
	gtk_table_attach_defaults (table, (GtkWidget*) label, (guint) 0, (guint) 1, (guint) 2, (guint) 3);
	{
		XSAAThrobber* _tmp13_;
		XSAAThrobber* _tmp14_;
		_tmp13_ = g_object_ref_sink (xsaa_throbber_new (self->priv->theme, (guint) 83, &_inner_error_));
		if (_inner_error_ != NULL) {
			goto __catch9_g_error;
			goto __finally9;
		}
		_tmp14_ = NULL;
		self->priv->phase[2] = (_tmp14_ = g_object_ref_sink (_tmp13_), (self->priv->phase[2] == NULL) ? NULL : (self->priv->phase[2] = (g_object_unref (self->priv->phase[2]), NULL)), _tmp14_);
		gtk_widget_show ((GtkWidget*) self->priv->phase[2]);
		gtk_table_attach_defaults (table, (GtkWidget*) self->priv->phase[2], (guint) 1, (guint) 2, (guint) 2, (guint) 3);
	}
	goto __finally9;
	__catch9_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on loading throbber %s", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally9:
	if (_inner_error_ != NULL) {
		(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
		(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
	(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
}


static void _xsaa_splash_on_restart_clicked_gtk_button_clicked (GtkButton* _sender, gpointer self) {
	xsaa_splash_on_restart_clicked (self);
}


static void _xsaa_splash_on_shutdown_clicked_gtk_button_clicked (GtkButton* _sender, gpointer self) {
	xsaa_splash_on_shutdown_clicked (self);
}


static void xsaa_splash_construct_login_page (XSAASplash* self) {
	GtkAlignment* alignment;
	GtkVBox* box;
	GtkTable* table;
	GtkLabel* _tmp2_;
	char* _tmp1_;
	char* _tmp0_;
	GtkEntry* _tmp3_;
	GtkLabel* _tmp4_;
	GtkHButtonBox* button_box;
	GtkButton* button;
	GtkButton* _tmp5_;
	g_return_if_fail (self != NULL);
	alignment = g_object_ref_sink ((GtkAlignment*) gtk_alignment_new (0.5f, 1.0f, (float) 0, (float) 0));
	gtk_widget_show ((GtkWidget*) alignment);
	ssi_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) alignment, NULL);
	box = g_object_ref_sink ((GtkVBox*) gtk_vbox_new (FALSE, 12));
	gtk_widget_show ((GtkWidget*) box);
	gtk_container_add ((GtkContainer*) alignment, (GtkWidget*) box);
	table = g_object_ref_sink ((GtkTable*) gtk_table_new ((guint) 3, (guint) 3, FALSE));
	gtk_container_set_border_width ((GtkContainer*) table, (guint) 12);
	gtk_table_set_col_spacings (table, (guint) 12);
	gtk_table_set_row_spacings (table, (guint) 24);
	gtk_widget_show ((GtkWidget*) table);
	gtk_box_pack_start ((GtkBox*) box, (GtkWidget*) table, TRUE, TRUE, (guint) 0);
	_tmp2_ = NULL;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->label_prompt = (_tmp2_ = g_object_ref_sink ((GtkLabel*) gtk_label_new (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Login :</span>", NULL))), (self->priv->label_prompt == NULL) ? NULL : (self->priv->label_prompt = (g_object_unref (self->priv->label_prompt), NULL)), _tmp2_);
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	gtk_label_set_use_markup (self->priv->label_prompt, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) self->priv->label_prompt, 0.0f, 0.5f);
	gtk_widget_show ((GtkWidget*) self->priv->label_prompt);
	gtk_table_attach_defaults (table, (GtkWidget*) self->priv->label_prompt, (guint) 1, (guint) 2, (guint) 0, (guint) 1);
	_tmp3_ = NULL;
	self->priv->entry_prompt = (_tmp3_ = g_object_ref_sink ((GtkEntry*) gtk_entry_new ()), (self->priv->entry_prompt == NULL) ? NULL : (self->priv->entry_prompt = (g_object_unref (self->priv->entry_prompt), NULL)), _tmp3_);
	gtk_widget_show ((GtkWidget*) self->priv->entry_prompt);
	gtk_table_attach_defaults (table, (GtkWidget*) self->priv->entry_prompt, (guint) 2, (guint) 3, (guint) 0, (guint) 1);
	_tmp4_ = NULL;
	self->priv->label_message = (_tmp4_ = g_object_ref_sink ((GtkLabel*) gtk_label_new ("")), (self->priv->label_message == NULL) ? NULL : (self->priv->label_message = (g_object_unref (self->priv->label_message), NULL)), _tmp4_);
	gtk_label_set_use_markup (self->priv->label_message, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) self->priv->label_message, 0.5f, 0.5f);
	gtk_widget_show ((GtkWidget*) self->priv->label_message);
	gtk_table_attach_defaults (table, (GtkWidget*) self->priv->label_message, (guint) 0, (guint) 4, (guint) 1, (guint) 2);
	button_box = g_object_ref_sink ((GtkHButtonBox*) gtk_hbutton_box_new ());
	gtk_widget_show ((GtkWidget*) button_box);
	gtk_box_set_spacing ((GtkBox*) button_box, 12);
	gtk_button_box_set_layout ((GtkButtonBox*) button_box, GTK_BUTTONBOX_END);
	gtk_box_pack_start ((GtkBox*) box, (GtkWidget*) button_box, FALSE, FALSE, (guint) 0);
	button = g_object_ref_sink ((GtkButton*) gtk_button_new_with_label ("Restart"));
	gtk_widget_show ((GtkWidget*) button);
	g_signal_connect_object (button, "clicked", (GCallback) _xsaa_splash_on_restart_clicked_gtk_button_clicked, self, 0);
	gtk_box_pack_start ((GtkBox*) button_box, (GtkWidget*) button, FALSE, FALSE, (guint) 0);
	_tmp5_ = NULL;
	button = (_tmp5_ = g_object_ref_sink ((GtkButton*) gtk_button_new_with_label ("Shutdown")), (button == NULL) ? NULL : (button = (g_object_unref (button), NULL)), _tmp5_);
	gtk_widget_show ((GtkWidget*) button);
	g_signal_connect_object (button, "clicked", (GCallback) _xsaa_splash_on_shutdown_clicked_gtk_button_clicked, self, 0);
	gtk_box_pack_start ((GtkBox*) button_box, (GtkWidget*) button, FALSE, FALSE, (guint) 0);
	(alignment == NULL) ? NULL : (alignment = (g_object_unref (alignment), NULL));
	(box == NULL) ? NULL : (box = (g_object_unref (box), NULL));
	(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
	(button_box == NULL) ? NULL : (button_box = (g_object_unref (button_box), NULL));
	(button == NULL) ? NULL : (button = (g_object_unref (button), NULL));
}


static void xsaa_splash_construct_launch_session_page (XSAASplash* self) {
	GError * _inner_error_;
	GtkTable* table;
	char* _tmp1_;
	char* _tmp0_;
	GtkLabel* _tmp2_;
	GtkLabel* label;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	table = g_object_ref_sink ((GtkTable*) gtk_table_new ((guint) 1, (guint) 2, FALSE));
	gtk_widget_show ((GtkWidget*) table);
	ssi_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) table, NULL);
	gtk_container_set_border_width ((GtkContainer*) table, (guint) 12);
	gtk_table_set_col_spacings (table, (guint) 12);
	gtk_table_set_row_spacings (table, (guint) 12);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	_tmp2_ = NULL;
	label = (_tmp2_ = g_object_ref_sink ((GtkLabel*) gtk_label_new (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Launch session ...</span>", NULL))), _tmp1_ = (g_free (_tmp1_), NULL), _tmp0_ = (g_free (_tmp0_), NULL), _tmp2_);
	gtk_label_set_use_markup (label, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) label, 0.0f, 0.5f);
	gtk_widget_show ((GtkWidget*) label);
	gtk_table_attach_defaults (table, (GtkWidget*) label, (guint) 0, (guint) 1, (guint) 0, (guint) 1);
	{
		XSAAThrobber* _tmp3_;
		XSAAThrobber* _tmp4_;
		_tmp3_ = g_object_ref_sink (xsaa_throbber_new (self->priv->theme, (guint) 83, &_inner_error_));
		if (_inner_error_ != NULL) {
			goto __catch10_g_error;
			goto __finally10;
		}
		_tmp4_ = NULL;
		self->priv->throbber_session = (_tmp4_ = g_object_ref_sink (_tmp3_), (self->priv->throbber_session == NULL) ? NULL : (self->priv->throbber_session = (g_object_unref (self->priv->throbber_session), NULL)), _tmp4_);
		gtk_widget_show ((GtkWidget*) self->priv->throbber_session);
		gtk_table_attach_defaults (table, (GtkWidget*) self->priv->throbber_session, (guint) 1, (guint) 2, (guint) 0, (guint) 1);
	}
	goto __finally10;
	__catch10_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on loading throbber %s", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally10:
	if (_inner_error_ != NULL) {
		(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
		(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
	(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
}


static void xsaa_splash_construct_shutdown_page (XSAASplash* self) {
	GError * _inner_error_;
	GtkTable* table;
	char* _tmp1_;
	char* _tmp0_;
	GtkLabel* _tmp2_;
	GtkLabel* label;
	g_return_if_fail (self != NULL);
	_inner_error_ = NULL;
	table = g_object_ref_sink ((GtkTable*) gtk_table_new ((guint) 1, (guint) 2, FALSE));
	gtk_widget_show ((GtkWidget*) table);
	ssi_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) table, NULL);
	gtk_container_set_border_width ((GtkContainer*) table, (guint) 12);
	gtk_table_set_col_spacings (table, (guint) 12);
	gtk_table_set_row_spacings (table, (guint) 12);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	_tmp2_ = NULL;
	label = (_tmp2_ = g_object_ref_sink ((GtkLabel*) gtk_label_new (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Shutdown in progress ...</span>", NULL))), _tmp1_ = (g_free (_tmp1_), NULL), _tmp0_ = (g_free (_tmp0_), NULL), _tmp2_);
	gtk_label_set_use_markup (label, TRUE);
	gtk_misc_set_alignment ((GtkMisc*) label, 0.0f, 0.5f);
	gtk_widget_show ((GtkWidget*) label);
	gtk_table_attach_defaults (table, (GtkWidget*) label, (guint) 0, (guint) 1, (guint) 0, (guint) 1);
	{
		XSAAThrobber* _tmp3_;
		XSAAThrobber* _tmp4_;
		_tmp3_ = g_object_ref_sink (xsaa_throbber_new (self->priv->theme, (guint) 83, &_inner_error_));
		if (_inner_error_ != NULL) {
			goto __catch11_g_error;
			goto __finally11;
		}
		_tmp4_ = NULL;
		self->priv->throbber_shutdown = (_tmp4_ = g_object_ref_sink (_tmp3_), (self->priv->throbber_shutdown == NULL) ? NULL : (self->priv->throbber_shutdown = (g_object_unref (self->priv->throbber_shutdown), NULL)), _tmp4_);
		gtk_widget_show ((GtkWidget*) self->priv->throbber_shutdown);
		gtk_table_attach_defaults (table, (GtkWidget*) self->priv->throbber_shutdown, (guint) 1, (guint) 2, (guint) 0, (guint) 1);
	}
	goto __finally11;
	__catch11_g_error:
	{
		GError * err;
		err = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stderr, "Error on loading throbber %s", err->message);
			(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
		}
	}
	__finally11:
	if (_inner_error_ != NULL) {
		(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
		(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
		g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
		g_clear_error (&_inner_error_);
		return;
	}
	(table == NULL) ? NULL : (table = (g_object_unref (table), NULL));
	(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
}


static void xsaa_splash_on_phase_changed (XSAASplash* self, gint new_phase) {
	g_return_if_fail (self != NULL);
	if (self->priv->current_phase != new_phase) {
		gboolean _tmp0_;
		gboolean _tmp1_;
		_tmp0_ = FALSE;
		if (self->priv->current_phase < 3) {
			_tmp0_ = self->priv->current_phase >= 0;
		} else {
			_tmp0_ = FALSE;
		}
		if (_tmp0_) {
			xsaa_throbber_finished (self->priv->phase[self->priv->current_phase]);
		}
		_tmp1_ = FALSE;
		if (new_phase < 3) {
			_tmp1_ = new_phase >= 0;
		} else {
			_tmp1_ = FALSE;
		}
		if (_tmp1_) {
			xsaa_throbber_start (self->priv->phase[new_phase]);
		}
		self->priv->current_phase = new_phase;
	}
}


static gboolean xsaa_splash_on_pulse (XSAASplash* self) {
	gboolean result;
	g_return_val_if_fail (self != NULL, FALSE);
	gtk_progress_bar_pulse (self->priv->progress);
	result = TRUE;
	return result;
}


static gboolean _xsaa_splash_on_pulse_gsource_func (gpointer self) {
	return xsaa_splash_on_pulse (self);
}


static void xsaa_splash_on_start_pulse (XSAASplash* self) {
	g_return_if_fail (self != NULL);
	if (self->priv->id_pulse == 0) {
		self->priv->id_pulse = g_timeout_add ((guint) 83, _xsaa_splash_on_pulse_gsource_func, self);
	}
}


static void xsaa_splash_on_progress (XSAASplash* self, gint val) {
	g_return_if_fail (self != NULL);
	if (self->priv->id_pulse > 0) {
		g_source_remove (self->priv->id_pulse);
	}
	self->priv->id_pulse = (guint) 0;
	gtk_progress_bar_set_fraction (self->priv->progress, ((double) val) / ((double) 100));
}


static void xsaa_splash_on_progress_orientation (XSAASplash* self, GtkProgressBarOrientation orientation) {
	g_return_if_fail (self != NULL);
	gtk_progress_bar_set_orientation (self->priv->progress, orientation);
}


static void _xsaa_splash_on_login_enter_gtk_entry_activate (GtkEntry* _sender, gpointer self) {
	xsaa_splash_on_login_enter (self);
}


static void _xsaa_splash_on_passwd_enter_gtk_entry_activate (GtkEntry* _sender, gpointer self) {
	xsaa_splash_on_passwd_enter (self);
}


static void xsaa_splash_on_login_enter (XSAASplash* self) {
	char* _tmp1_;
	const char* _tmp0_;
	g_return_if_fail (self != NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	self->priv->username = (_tmp1_ = (_tmp0_ = gtk_entry_get_text (self->priv->entry_prompt), (_tmp0_ == NULL) ? NULL : g_strdup (_tmp0_)), self->priv->username = (g_free (self->priv->username), NULL), _tmp1_);
	if (g_utf8_strlen (self->priv->username, -1) > 0) {
		guint _tmp2_;
		char* _tmp4_;
		char* _tmp3_;
		gtk_window_set_focus ((GtkWindow*) self, (GtkWidget*) self->priv->entry_prompt);
		g_signal_handlers_disconnect_matched (self->priv->entry_prompt, G_SIGNAL_MATCH_ID | G_SIGNAL_MATCH_FUNC | G_SIGNAL_MATCH_DATA, (g_signal_parse_name ("activate", GTK_TYPE_ENTRY, &_tmp2_, NULL, FALSE), _tmp2_), 0, NULL, (GCallback) _xsaa_splash_on_login_enter_gtk_entry_activate, self);
		gtk_entry_set_visibility (self->priv->entry_prompt, FALSE);
		gtk_entry_set_text (self->priv->entry_prompt, "");
		g_signal_connect_object (self->priv->entry_prompt, "activate", (GCallback) _xsaa_splash_on_passwd_enter_gtk_entry_activate, self, 0);
		_tmp4_ = NULL;
		_tmp3_ = NULL;
		gtk_label_set_markup (self->priv->label_prompt, _tmp4_ = g_strconcat (_tmp3_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Password :</span>", NULL));
		_tmp4_ = (g_free (_tmp4_), NULL);
		_tmp3_ = (g_free (_tmp3_), NULL);
		gtk_label_set_text (self->priv->label_message, "");
	}
}


static void xsaa_splash_on_passwd_enter (XSAASplash* self) {
	guint _tmp0_;
	g_return_if_fail (self != NULL);
	gtk_widget_set_sensitive ((GtkWidget*) self->priv->entry_prompt, FALSE);
	g_signal_handlers_disconnect_matched (self->priv->entry_prompt, G_SIGNAL_MATCH_ID | G_SIGNAL_MATCH_FUNC | G_SIGNAL_MATCH_DATA, (g_signal_parse_name ("activate", GTK_TYPE_ENTRY, &_tmp0_, NULL, FALSE), _tmp0_), 0, NULL, (GCallback) _xsaa_splash_on_passwd_enter_gtk_entry_activate, self);
	g_signal_emit_by_name (self, "login", self->priv->username, gtk_entry_get_text (self->priv->entry_prompt));
}


static void xsaa_splash_on_restart_clicked (XSAASplash* self) {
	g_return_if_fail (self != NULL);
	g_signal_emit_by_name (self, "restart");
}


static void xsaa_splash_on_shutdown_clicked (XSAASplash* self) {
	g_return_if_fail (self != NULL);
	g_signal_emit_by_name (self, "shutdown");
}


static void xsaa_splash_real_realize (GtkWidget* base) {
	XSAASplash * self;
	GdkColor color = {0};
	GdkScreen* _tmp0_;
	GdkScreen* screen;
	GdkWindow* _tmp1_;
	GdkWindow* root;
	self = (XSAASplash*) base;
	GTK_WIDGET_CLASS (xsaa_splash_parent_class)->realize ((GtkWidget*) GTK_WINDOW (self));
	gdk_color_parse (self->priv->bg, &color);
	gtk_widget_modify_bg ((GtkWidget*) self, GTK_STATE_NORMAL, &color);
	gtk_widget_modify_bg ((GtkWidget*) self->priv->notebook, GTK_STATE_NORMAL, &color);
	_tmp0_ = NULL;
	screen = (_tmp0_ = gdk_drawable_get_screen ((GdkDrawable*) gtk_widget_get_window ((GtkWidget*) self)), (_tmp0_ == NULL) ? NULL : g_object_ref (_tmp0_));
	_tmp1_ = NULL;
	root = (_tmp1_ = gdk_screen_get_root_window (screen), (_tmp1_ == NULL) ? NULL : g_object_ref (_tmp1_));
	gdk_window_set_background (root, &color);
	(screen == NULL) ? NULL : (screen = (g_object_unref (screen), NULL));
	(root == NULL) ? NULL : (root = (g_object_unref (root), NULL));
}


void xsaa_splash_show_launch (XSAASplash* self) {
	GdkCursor* cursor;
	g_return_if_fail (self != NULL);
	cursor = gdk_cursor_new (GDK_BLANK_CURSOR);
	gdk_window_set_cursor (gtk_widget_get_window ((GtkWidget*) self), cursor);
	gtk_notebook_set_current_page ((GtkNotebook*) self->priv->notebook, 2);
	xsaa_throbber_start (self->priv->throbber_session);
	(cursor == NULL) ? NULL : (cursor = (gdk_cursor_unref (cursor), NULL));
}


void xsaa_splash_show_shutdown (XSAASplash* self) {
	GdkCursor* cursor;
	g_return_if_fail (self != NULL);
	cursor = gdk_cursor_new (GDK_BLANK_CURSOR);
	gdk_window_set_cursor (gtk_widget_get_window ((GtkWidget*) self), cursor);
	gtk_notebook_set_current_page ((GtkNotebook*) self->priv->notebook, 3);
	gtk_widget_show ((GtkWidget*) self->priv->progress);
	xsaa_splash_on_start_pulse (self);
	xsaa_throbber_start (self->priv->throbber_shutdown);
	(cursor == NULL) ? NULL : (cursor = (gdk_cursor_unref (cursor), NULL));
}


void xsaa_splash_ask_for_login (XSAASplash* self) {
	GdkCursor* cursor;
	char* _tmp1_;
	char* _tmp0_;
	g_return_if_fail (self != NULL);
	cursor = gdk_cursor_new (GDK_LEFT_PTR);
	gdk_window_set_cursor (gtk_widget_get_window ((GtkWidget*) self), cursor);
	gtk_notebook_set_current_page ((GtkNotebook*) self->priv->notebook, 1);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	gtk_label_set_markup (self->priv->label_prompt, _tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>Login :</span>", NULL));
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
	gtk_window_set_focus ((GtkWindow*) self, (GtkWidget*) self->priv->entry_prompt);
	gtk_widget_grab_focus ((GtkWidget*) self->priv->entry_prompt);
	gtk_widget_set_sensitive ((GtkWidget*) self->priv->entry_prompt, TRUE);
	gtk_entry_set_visibility (self->priv->entry_prompt, TRUE);
	gtk_entry_set_text (self->priv->entry_prompt, "");
	g_signal_connect_object (self->priv->entry_prompt, "activate", (GCallback) _xsaa_splash_on_login_enter_gtk_entry_activate, self, 0);
	if (self->priv->id_pulse > 0) {
		g_source_remove (self->priv->id_pulse);
	}
	self->priv->id_pulse = (guint) 0;
	gtk_widget_hide ((GtkWidget*) self->priv->progress);
	(cursor == NULL) ? NULL : (cursor = (gdk_cursor_unref (cursor), NULL));
}


void xsaa_splash_login_message (XSAASplash* self, const char* msg) {
	char* _tmp3_;
	char* _tmp2_;
	char* _tmp1_;
	char* _tmp0_;
	g_return_if_fail (self != NULL);
	g_return_if_fail (msg != NULL);
	_tmp3_ = NULL;
	_tmp2_ = NULL;
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	gtk_label_set_markup (self->priv->label_message, _tmp3_ = g_strconcat (_tmp2_ = g_strconcat (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat ("<span size='xx-large' color='", self->priv->text, NULL), "'>", NULL), msg, NULL), "</span>", NULL));
	_tmp3_ = (g_free (_tmp3_), NULL);
	_tmp2_ = (g_free (_tmp2_), NULL);
	_tmp1_ = (g_free (_tmp1_), NULL);
	_tmp0_ = (g_free (_tmp0_), NULL);
}


static void _gtk_main_quit_gtk_object_destroy (XSAASplash* _sender, gpointer self) {
	gtk_main_quit ();
}


static GObject * xsaa_splash_constructor (GType type, guint n_construct_properties, GObjectConstructParam * construct_properties) {
	GObject * obj;
	XSAASplashClass * klass;
	GObjectClass * parent_class;
	XSAASplash * self;
	GError * _inner_error_;
	klass = XSAA_SPLASH_CLASS (g_type_class_peek (XSAA_TYPE_SPLASH));
	parent_class = G_OBJECT_CLASS (g_type_class_peek_parent (klass));
	obj = parent_class->constructor (type, n_construct_properties, construct_properties);
	self = XSAA_SPLASH (obj);
	_inner_error_ = NULL;
	{
		GdkScreen* _tmp0_;
		GdkScreen* screen;
		GdkRectangle geometry = {0};
		GtkAlignment* alignment;
		GtkVBox* vbox;
		GtkHBox* hbox;
		GtkVBox* vbox_right;
		GtkAlignment* _tmp17_;
		SSISlideNotebook* _tmp18_;
		GtkTable* table_progress;
		GtkProgressBar* _tmp19_;
		xsaa_splash_load_config (self);
		_tmp0_ = NULL;
		screen = (_tmp0_ = gdk_screen_get_default (), (_tmp0_ == NULL) ? NULL : g_object_ref (_tmp0_));
		gdk_screen_get_monitor_geometry (screen, 0, &geometry);
		gtk_widget_set_app_paintable ((GtkWidget*) self, TRUE);
		gtk_window_set_default_size ((GtkWindow*) self, geometry.width, geometry.height);
		gtk_window_fullscreen ((GtkWindow*) self);
		g_signal_connect ((GtkObject*) self, "destroy", (GCallback) _gtk_main_quit_gtk_object_destroy, NULL);
		alignment = g_object_ref_sink ((GtkAlignment*) gtk_alignment_new (0.5f, self->priv->yposition, (float) 0, (float) 0));
		gtk_widget_show ((GtkWidget*) alignment);
		gtk_container_add ((GtkContainer*) self, (GtkWidget*) alignment);
		vbox = g_object_ref_sink ((GtkVBox*) gtk_vbox_new (FALSE, 75));
		gtk_container_set_border_width ((GtkContainer*) vbox, (guint) 25);
		gtk_widget_show ((GtkWidget*) vbox);
		gtk_container_add ((GtkContainer*) alignment, (GtkWidget*) vbox);
		hbox = g_object_ref_sink ((GtkHBox*) gtk_hbox_new (FALSE, 25));
		gtk_widget_show ((GtkWidget*) hbox);
		gtk_box_pack_start ((GtkBox*) vbox, (GtkWidget*) hbox, FALSE, FALSE, (guint) 0);
		{
			char* _tmp2_;
			char* _tmp1_;
			GdkPixbuf* _tmp3_;
			GdkPixbuf* pixbuf;
			gint _tmp4_;
			gint width;
			gint height;
			GdkPixbuf* _tmp5_;
			GtkImage* _tmp6_;
			GtkImage* image;
			_tmp2_ = NULL;
			_tmp1_ = NULL;
			_tmp3_ = NULL;
			pixbuf = (_tmp3_ = gdk_pixbuf_new_from_file (_tmp2_ = g_strconcat (_tmp1_ = g_strconcat (PACKAGE_DATA_DIR "/", self->priv->theme, NULL), "/distrib-logo.png", NULL), &_inner_error_), _tmp2_ = (g_free (_tmp2_), NULL), _tmp1_ = (g_free (_tmp1_), NULL), _tmp3_);
			if (_inner_error_ != NULL) {
				goto __catch12_g_error;
				goto __finally12;
			}
			_tmp4_ = 0;
			if ((geometry.width / 3) > gdk_pixbuf_get_width (pixbuf)) {
				_tmp4_ = gdk_pixbuf_get_width (pixbuf);
			} else {
				_tmp4_ = geometry.width / 3;
			}
			width = _tmp4_;
			height = (gint) (((double) width) * (((double) gdk_pixbuf_get_height (pixbuf)) / ((double) gdk_pixbuf_get_width (pixbuf))));
			_tmp5_ = NULL;
			_tmp6_ = NULL;
			image = (_tmp6_ = g_object_ref_sink ((GtkImage*) gtk_image_new_from_pixbuf (_tmp5_ = gdk_pixbuf_scale_simple (pixbuf, width, height, GDK_INTERP_BILINEAR))), (_tmp5_ == NULL) ? NULL : (_tmp5_ = (g_object_unref (_tmp5_), NULL)), _tmp6_);
			gtk_widget_show ((GtkWidget*) image);
			gtk_box_pack_start ((GtkBox*) hbox, (GtkWidget*) image, FALSE, FALSE, (guint) 0);
			(pixbuf == NULL) ? NULL : (pixbuf = (g_object_unref (pixbuf), NULL));
			(image == NULL) ? NULL : (image = (g_object_unref (image), NULL));
		}
		goto __finally12;
		__catch12_g_error:
		{
			GError * err;
			err = _inner_error_;
			_inner_error_ = NULL;
			{
				char* _tmp8_;
				char* _tmp7_;
				_tmp8_ = NULL;
				_tmp7_ = NULL;
				fprintf (stderr, "Error on loading %s: %s", _tmp8_ = g_strconcat (_tmp7_ = g_strconcat (PACKAGE_DATA_DIR "/", self->priv->theme, NULL), "/distrib-logo.png", NULL), err->message);
				_tmp8_ = (g_free (_tmp8_), NULL);
				_tmp7_ = (g_free (_tmp7_), NULL);
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
			}
		}
		__finally12:
		if (_inner_error_ != NULL) {
			(screen == NULL) ? NULL : (screen = (g_object_unref (screen), NULL));
			(alignment == NULL) ? NULL : (alignment = (g_object_unref (alignment), NULL));
			(vbox == NULL) ? NULL : (vbox = (g_object_unref (vbox), NULL));
			(hbox == NULL) ? NULL : (hbox = (g_object_unref (hbox), NULL));
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
		}
		vbox_right = g_object_ref_sink ((GtkVBox*) gtk_vbox_new (FALSE, 25));
		gtk_widget_show ((GtkWidget*) vbox_right);
		gtk_box_pack_start ((GtkBox*) hbox, (GtkWidget*) vbox_right, FALSE, FALSE, (guint) 0);
		{
			char* _tmp10_;
			char* _tmp9_;
			GdkPixbuf* _tmp11_;
			GdkPixbuf* pixbuf;
			gint _tmp12_;
			gint width;
			gint height;
			GdkPixbuf* _tmp13_;
			GtkImage* _tmp14_;
			GtkImage* image;
			_tmp10_ = NULL;
			_tmp9_ = NULL;
			_tmp11_ = NULL;
			pixbuf = (_tmp11_ = gdk_pixbuf_new_from_file (_tmp10_ = g_strconcat (_tmp9_ = g_strconcat (PACKAGE_DATA_DIR "/", self->priv->theme, NULL), "/logo.png", NULL), &_inner_error_), _tmp10_ = (g_free (_tmp10_), NULL), _tmp9_ = (g_free (_tmp9_), NULL), _tmp11_);
			if (_inner_error_ != NULL) {
				goto __catch13_g_error;
				goto __finally13;
			}
			_tmp12_ = 0;
			if ((geometry.width / 3) > gdk_pixbuf_get_width (pixbuf)) {
				_tmp12_ = gdk_pixbuf_get_width (pixbuf);
			} else {
				_tmp12_ = geometry.width / 3;
			}
			width = _tmp12_;
			height = (gint) (((double) width) * (((double) gdk_pixbuf_get_height (pixbuf)) / ((double) gdk_pixbuf_get_width (pixbuf))));
			_tmp13_ = NULL;
			_tmp14_ = NULL;
			image = (_tmp14_ = g_object_ref_sink ((GtkImage*) gtk_image_new_from_pixbuf (_tmp13_ = gdk_pixbuf_scale_simple (pixbuf, width, height, GDK_INTERP_BILINEAR))), (_tmp13_ == NULL) ? NULL : (_tmp13_ = (g_object_unref (_tmp13_), NULL)), _tmp14_);
			gtk_widget_show ((GtkWidget*) image);
			gtk_box_pack_start ((GtkBox*) vbox_right, (GtkWidget*) image, TRUE, TRUE, (guint) 0);
			(pixbuf == NULL) ? NULL : (pixbuf = (g_object_unref (pixbuf), NULL));
			(image == NULL) ? NULL : (image = (g_object_unref (image), NULL));
		}
		goto __finally13;
		__catch13_g_error:
		{
			GError * err;
			err = _inner_error_;
			_inner_error_ = NULL;
			{
				char* _tmp16_;
				char* _tmp15_;
				_tmp16_ = NULL;
				_tmp15_ = NULL;
				fprintf (stderr, "Error on loading %s: %s", _tmp16_ = g_strconcat (_tmp15_ = g_strconcat (PACKAGE_DATA_DIR "/", self->priv->theme, NULL), "/logo.png", NULL), err->message);
				_tmp16_ = (g_free (_tmp16_), NULL);
				_tmp15_ = (g_free (_tmp15_), NULL);
				(err == NULL) ? NULL : (err = (g_error_free (err), NULL));
			}
		}
		__finally13:
		if (_inner_error_ != NULL) {
			(screen == NULL) ? NULL : (screen = (g_object_unref (screen), NULL));
			(alignment == NULL) ? NULL : (alignment = (g_object_unref (alignment), NULL));
			(vbox == NULL) ? NULL : (vbox = (g_object_unref (vbox), NULL));
			(hbox == NULL) ? NULL : (hbox = (g_object_unref (hbox), NULL));
			(vbox_right == NULL) ? NULL : (vbox_right = (g_object_unref (vbox_right), NULL));
			g_critical ("file %s: line %d: uncaught error: %s", __FILE__, __LINE__, _inner_error_->message);
			g_clear_error (&_inner_error_);
		}
		_tmp17_ = NULL;
		alignment = (_tmp17_ = g_object_ref_sink ((GtkAlignment*) gtk_alignment_new (0.5f, 0.5f, (float) 0, (float) 0)), (alignment == NULL) ? NULL : (alignment = (g_object_unref (alignment), NULL)), _tmp17_);
		gtk_widget_show ((GtkWidget*) alignment);
		gtk_box_pack_start ((GtkBox*) vbox_right, (GtkWidget*) alignment, TRUE, TRUE, (guint) 0);
		_tmp18_ = NULL;
		self->priv->notebook = (_tmp18_ = g_object_ref_sink (ssi_slide_notebook_new ()), (self->priv->notebook == NULL) ? NULL : (self->priv->notebook = (g_object_unref (self->priv->notebook), NULL)), _tmp18_);
		gtk_widget_show ((GtkWidget*) self->priv->notebook);
		gtk_container_add ((GtkContainer*) alignment, (GtkWidget*) self->priv->notebook);
		gtk_notebook_set_show_tabs ((GtkNotebook*) self->priv->notebook, FALSE);
		gtk_notebook_set_show_border ((GtkNotebook*) self->priv->notebook, FALSE);
		xsaa_splash_construct_loading_page (self);
		xsaa_splash_construct_login_page (self);
		xsaa_splash_construct_launch_session_page (self);
		xsaa_splash_construct_shutdown_page (self);
		table_progress = g_object_ref_sink ((GtkTable*) gtk_table_new ((guint) 5, (guint) 1, FALSE));
		gtk_widget_show ((GtkWidget*) table_progress);
		gtk_container_set_border_width ((GtkContainer*) table_progress, (guint) 24);
		gtk_table_set_col_spacings (table_progress, (guint) 12);
		gtk_table_set_row_spacings (table_progress, (guint) 12);
		gtk_box_pack_start ((GtkBox*) vbox, (GtkWidget*) table_progress, FALSE, FALSE, (guint) 12);
		_tmp19_ = NULL;
		self->priv->progress = (_tmp19_ = g_object_ref_sink ((GtkProgressBar*) gtk_progress_bar_new ()), (self->priv->progress == NULL) ? NULL : (self->priv->progress = (g_object_unref (self->priv->progress), NULL)), _tmp19_);
		gtk_widget_show ((GtkWidget*) self->priv->progress);
		gtk_table_attach (table_progress, (GtkWidget*) self->priv->progress, (guint) 2, (guint) 3, (guint) 0, (guint) 1, GTK_EXPAND | GTK_FILL, 0, (guint) 0, (guint) 0);
		xsaa_splash_on_start_pulse (self);
		(screen == NULL) ? NULL : (screen = (g_object_unref (screen), NULL));
		(alignment == NULL) ? NULL : (alignment = (g_object_unref (alignment), NULL));
		(vbox == NULL) ? NULL : (vbox = (g_object_unref (vbox), NULL));
		(hbox == NULL) ? NULL : (hbox = (g_object_unref (hbox), NULL));
		(vbox_right == NULL) ? NULL : (vbox_right = (g_object_unref (vbox_right), NULL));
		(table_progress == NULL) ? NULL : (table_progress = (g_object_unref (table_progress), NULL));
	}
	return obj;
}


static void xsaa_splash_class_init (XSAASplashClass * klass) {
	xsaa_splash_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAASplashPrivate));
	GTK_WIDGET_CLASS (klass)->realize = xsaa_splash_real_realize;
	G_OBJECT_CLASS (klass)->constructor = xsaa_splash_constructor;
	G_OBJECT_CLASS (klass)->finalize = xsaa_splash_finalize;
	g_signal_new ("login", XSAA_TYPE_SPLASH, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_user_marshal_VOID__STRING_STRING, G_TYPE_NONE, 2, G_TYPE_STRING, G_TYPE_STRING);
	g_signal_new ("restart", XSAA_TYPE_SPLASH, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
	g_signal_new ("shutdown", XSAA_TYPE_SPLASH, G_SIGNAL_RUN_LAST, 0, NULL, NULL, g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
}


static void xsaa_splash_instance_init (XSAASplash * self) {
	self->priv = XSAA_SPLASH_GET_PRIVATE (self);
	self->priv->phase = g_new0 (XSAAThrobber*, 3 + 1);
	self->priv->phase_length1 = 3;
	self->priv->current_phase = 0;
	self->priv->id_pulse = (guint) 0;
	self->priv->theme = g_strdup ("chicken-curie");
	self->priv->bg = g_strdup ("#1B242D");
	self->priv->text = g_strdup ("#7BC4F5");
	self->priv->yposition = 0.5f;
}


static void xsaa_splash_finalize (GObject* obj) {
	XSAASplash * self;
	self = XSAA_SPLASH (obj);
	(self->priv->socket == NULL) ? NULL : (self->priv->socket = (g_object_unref (self->priv->socket), NULL));
	self->priv->phase = (_vala_array_free (self->priv->phase, self->priv->phase_length1, (GDestroyNotify) g_object_unref), NULL);
	(self->priv->throbber_session == NULL) ? NULL : (self->priv->throbber_session = (g_object_unref (self->priv->throbber_session), NULL));
	(self->priv->throbber_shutdown == NULL) ? NULL : (self->priv->throbber_shutdown = (g_object_unref (self->priv->throbber_shutdown), NULL));
	(self->priv->progress == NULL) ? NULL : (self->priv->progress = (g_object_unref (self->priv->progress), NULL));
	(self->priv->notebook == NULL) ? NULL : (self->priv->notebook = (g_object_unref (self->priv->notebook), NULL));
	(self->priv->label_prompt == NULL) ? NULL : (self->priv->label_prompt = (g_object_unref (self->priv->label_prompt), NULL));
	(self->priv->entry_prompt == NULL) ? NULL : (self->priv->entry_prompt = (g_object_unref (self->priv->entry_prompt), NULL));
	self->priv->username = (g_free (self->priv->username), NULL);
	(self->priv->label_message == NULL) ? NULL : (self->priv->label_message = (g_object_unref (self->priv->label_message), NULL));
	self->priv->theme = (g_free (self->priv->theme), NULL);
	self->priv->bg = (g_free (self->priv->bg), NULL);
	self->priv->text = (g_free (self->priv->text), NULL);
	G_OBJECT_CLASS (xsaa_splash_parent_class)->finalize (obj);
}


GType xsaa_splash_get_type (void) {
	static GType xsaa_splash_type_id = 0;
	if (xsaa_splash_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAASplashClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_splash_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAASplash), 0, (GInstanceInitFunc) xsaa_splash_instance_init, NULL };
		xsaa_splash_type_id = g_type_register_static (GTK_TYPE_WINDOW, "XSAASplash", &g_define_type_info, 0);
	}
	return xsaa_splash_type_id;
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



static void g_cclosure_user_marshal_VOID__STRING_STRING (GClosure * closure, GValue * return_value, guint n_param_values, const GValue * param_values, gpointer invocation_hint, gpointer marshal_data) {
	typedef void (*GMarshalFunc_VOID__STRING_STRING) (gpointer data1, const char* arg_1, const char* arg_2, gpointer data2);
	register GMarshalFunc_VOID__STRING_STRING callback;
	register GCClosure * cc;
	register gpointer data1, data2;
	cc = (GCClosure *) closure;
	g_return_if_fail (n_param_values == 3);
	if (G_CCLOSURE_SWAP_DATA (closure)) {
		data1 = closure->data;
		data2 = param_values->data[0].v_pointer;
	} else {
		data1 = param_values->data[0].v_pointer;
		data2 = closure->data;
	}
	callback = (GMarshalFunc_VOID__STRING_STRING) (marshal_data ? marshal_data : cc->callback);
	callback (data1, g_value_get_string (param_values + 1), g_value_get_string (param_values + 2), data2);
}



