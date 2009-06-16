/* xsaa-throbber.vala
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
#include <gdk-pixbuf/gdk-pixdata.h>
#include <config.h>
#include <stdlib.h>
#include <string.h>


#define XSAA_TYPE_THROBBER (xsaa_throbber_get_type ())
#define XSAA_THROBBER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_THROBBER, XSAAThrobber))
#define XSAA_THROBBER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_THROBBER, XSAAThrobberClass))
#define XSAA_IS_THROBBER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_THROBBER))
#define XSAA_IS_THROBBER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_THROBBER))
#define XSAA_THROBBER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_THROBBER, XSAAThrobberClass))

typedef struct _XSAAThrobber XSAAThrobber;
typedef struct _XSAAThrobberClass XSAAThrobberClass;
typedef struct _XSAAThrobberPrivate XSAAThrobberPrivate;

struct _XSAAThrobber {
	GtkImage parent_instance;
	XSAAThrobberPrivate * priv;
};

struct _XSAAThrobberClass {
	GtkImageClass parent_class;
};

struct _XSAAThrobberPrivate {
	guint interval;
	guint id_timeout;
	gint steps;
	gint current;
	GdkPixbuf* initial;
	GdkPixbuf* finish;
	GdkPixbuf** pixbufs;
	gint pixbufs_length1;
	gint pixbufs_size;
};



GType xsaa_throbber_get_type (void);
#define XSAA_THROBBER_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_THROBBER, XSAAThrobberPrivate))
enum  {
	XSAA_THROBBER_DUMMY_PROPERTY
};
XSAAThrobber* xsaa_throbber_new (const char* name, guint interval, GError** error);
XSAAThrobber* xsaa_throbber_construct (GType object_type, const char* name, guint interval, GError** error);
XSAAThrobber* xsaa_throbber_new (const char* name, guint interval, GError** error);
static gboolean xsaa_throbber_on_timer (XSAAThrobber* self);
static gboolean _xsaa_throbber_on_timer_gsource_func (gpointer self);
void xsaa_throbber_start (XSAAThrobber* self);
void xsaa_throbber_stop (XSAAThrobber* self);
void xsaa_throbber_finished (XSAAThrobber* self);
static gpointer xsaa_throbber_parent_class = NULL;
static void xsaa_throbber_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);



XSAAThrobber* xsaa_throbber_construct (GType object_type, const char* name, guint interval, GError** error) {
	GError * _inner_error_;
	XSAAThrobber * self;
	char* _tmp1_;
	char* _tmp0_;
	GdkPixbuf* _tmp2_;
	GdkPixbuf* spinner;
	GdkPixbuf* _tmp5_;
	char* _tmp4_;
	char* _tmp3_;
	GdkPixbuf* _tmp8_;
	char* _tmp7_;
	char* _tmp6_;
	gint _tmp9_;
	guint size;
	gint nb_steps;
	GdkPixbuf** _tmp10_;
	g_return_val_if_fail (name != NULL, NULL);
	_inner_error_ = NULL;
	self = g_object_newv (object_type, 0, NULL);
	_tmp1_ = NULL;
	_tmp0_ = NULL;
	_tmp2_ = NULL;
	spinner = (_tmp2_ = gdk_pixbuf_new_from_file (_tmp1_ = g_strconcat (_tmp0_ = g_strconcat (PACKAGE_DATA_DIR "/", name, NULL), "/throbber-spinner.png", NULL), &_inner_error_), _tmp1_ = (g_free (_tmp1_), NULL), _tmp0_ = (g_free (_tmp0_), NULL), _tmp2_);
	if (_inner_error_ != NULL) {
		g_propagate_error (error, _inner_error_);
		return;
	}
	_tmp5_ = NULL;
	_tmp4_ = NULL;
	_tmp3_ = NULL;
	self->priv->initial = (_tmp5_ = gdk_pixbuf_new_from_file (_tmp4_ = g_strconcat (_tmp3_ = g_strconcat (PACKAGE_DATA_DIR "/", name, NULL), "/throbber-initial.png", NULL), &_inner_error_), (self->priv->initial == NULL) ? NULL : (self->priv->initial = (g_object_unref (self->priv->initial), NULL)), _tmp5_);
	if (_inner_error_ != NULL) {
		g_propagate_error (error, _inner_error_);
		(spinner == NULL) ? NULL : (spinner = (g_object_unref (spinner), NULL));
		return;
	}
	_tmp4_ = (g_free (_tmp4_), NULL);
	_tmp3_ = (g_free (_tmp3_), NULL);
	_tmp8_ = NULL;
	_tmp7_ = NULL;
	_tmp6_ = NULL;
	self->priv->finish = (_tmp8_ = gdk_pixbuf_new_from_file (_tmp7_ = g_strconcat (_tmp6_ = g_strconcat (PACKAGE_DATA_DIR "/", name, NULL), "/throbber-finish.png", NULL), &_inner_error_), (self->priv->finish == NULL) ? NULL : (self->priv->finish = (g_object_unref (self->priv->finish), NULL)), _tmp8_);
	if (_inner_error_ != NULL) {
		g_propagate_error (error, _inner_error_);
		(spinner == NULL) ? NULL : (spinner = (g_object_unref (spinner), NULL));
		return;
	}
	_tmp7_ = (g_free (_tmp7_), NULL);
	_tmp6_ = (g_free (_tmp6_), NULL);
	_tmp9_ = 0;
	if (gdk_pixbuf_get_width (self->priv->initial) > gdk_pixbuf_get_height (self->priv->initial)) {
		_tmp9_ = gdk_pixbuf_get_width (self->priv->initial);
	} else {
		_tmp9_ = gdk_pixbuf_get_height (self->priv->initial);
	}
	size = (guint) _tmp9_;
	nb_steps = (gdk_pixbuf_get_height (spinner) * gdk_pixbuf_get_width (spinner)) / ((gint) size);
	_tmp10_ = NULL;
	self->priv->pixbufs = (_tmp10_ = g_new0 (GdkPixbuf*, nb_steps + 1), self->priv->pixbufs = (_vala_array_free (self->priv->pixbufs, self->priv->pixbufs_length1, (GDestroyNotify) g_object_unref), NULL), self->priv->pixbufs_length1 = nb_steps, self->priv->pixbufs_size = self->priv->pixbufs_length1, _tmp10_);
	{
		guint i;
		i = (guint) 0;
		for (; i < gdk_pixbuf_get_height (spinner); i = i + size) {
			{
				guint j;
				j = (guint) 0;
				for (; j < gdk_pixbuf_get_width (spinner); j = j + size, self->priv->steps++) {
					GdkPixbuf* _tmp11_;
					_tmp11_ = NULL;
					self->priv->pixbufs[self->priv->steps] = (_tmp11_ = gdk_pixbuf_new_subpixbuf (spinner, (gint) j, (gint) i, (gint) size, (gint) size), (self->priv->pixbufs[self->priv->steps] == NULL) ? NULL : (self->priv->pixbufs[self->priv->steps] = (g_object_unref (self->priv->pixbufs[self->priv->steps]), NULL)), _tmp11_);
				}
			}
		}
	}
	self->priv->interval = interval;
	gtk_image_set_from_pixbuf ((GtkImage*) self, self->priv->initial);
	(spinner == NULL) ? NULL : (spinner = (g_object_unref (spinner), NULL));
	return self;
}


XSAAThrobber* xsaa_throbber_new (const char* name, guint interval, GError** error) {
	return xsaa_throbber_construct (XSAA_TYPE_THROBBER, name, interval, error);
}


static gboolean _xsaa_throbber_on_timer_gsource_func (gpointer self) {
	return xsaa_throbber_on_timer (self);
}


void xsaa_throbber_start (XSAAThrobber* self) {
	g_return_if_fail (self != NULL);
	if (self->priv->id_timeout == 0) {
		self->priv->id_timeout = g_timeout_add (self->priv->interval, _xsaa_throbber_on_timer_gsource_func, self);
	}
}


void xsaa_throbber_stop (XSAAThrobber* self) {
	g_return_if_fail (self != NULL);
	if (self->priv->id_timeout != 0) {
		g_source_remove (self->priv->id_timeout);
		self->priv->id_timeout = (guint) 0;
	}
}


void xsaa_throbber_finished (XSAAThrobber* self) {
	g_return_if_fail (self != NULL);
	xsaa_throbber_stop (self);
	gtk_image_set_from_pixbuf ((GtkImage*) self, self->priv->finish);
}


static gboolean xsaa_throbber_on_timer (XSAAThrobber* self) {
	g_return_val_if_fail (self != NULL, FALSE);
	if ((self->priv->current = self->priv->current + 1) == self->priv->steps) {
		self->priv->current = 1;
	}
	gtk_image_set_from_pixbuf ((GtkImage*) self, self->priv->pixbufs[self->priv->current]);
	return TRUE;
}


static void xsaa_throbber_class_init (XSAAThrobberClass * klass) {
	xsaa_throbber_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAAThrobberPrivate));
	G_OBJECT_CLASS (klass)->finalize = xsaa_throbber_finalize;
}


static void xsaa_throbber_instance_init (XSAAThrobber * self) {
	self->priv = XSAA_THROBBER_GET_PRIVATE (self);
	self->priv->current = 0;
}


static void xsaa_throbber_finalize (GObject* obj) {
	XSAAThrobber * self;
	self = XSAA_THROBBER (obj);
	{
		xsaa_throbber_stop (self);
	}
	(self->priv->initial == NULL) ? NULL : (self->priv->initial = (g_object_unref (self->priv->initial), NULL));
	(self->priv->finish == NULL) ? NULL : (self->priv->finish = (g_object_unref (self->priv->finish), NULL));
	self->priv->pixbufs = (_vala_array_free (self->priv->pixbufs, self->priv->pixbufs_length1, (GDestroyNotify) g_object_unref), NULL);
	G_OBJECT_CLASS (xsaa_throbber_parent_class)->finalize (obj);
}


GType xsaa_throbber_get_type (void) {
	static GType xsaa_throbber_type_id = 0;
	if (xsaa_throbber_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAAThrobberClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_throbber_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAAThrobber), 0, (GInstanceInitFunc) xsaa_throbber_instance_init, NULL };
		xsaa_throbber_type_id = g_type_register_static (GTK_TYPE_IMAGE, "XSAAThrobber", &g_define_type_info, 0);
	}
	return xsaa_throbber_type_id;
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




