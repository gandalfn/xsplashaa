/* test-slide-notebook.vala
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
#include <stdlib.h>
#include <string.h>


#define XSAA_TYPE_TEST_SLIDE_WINDOW (xsaa_test_slide_window_get_type ())
#define XSAA_TEST_SLIDE_WINDOW(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_TEST_SLIDE_WINDOW, XSAATestSlideWindow))
#define XSAA_TEST_SLIDE_WINDOW_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_TEST_SLIDE_WINDOW, XSAATestSlideWindowClass))
#define XSAA_IS_TEST_SLIDE_WINDOW(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_TEST_SLIDE_WINDOW))
#define XSAA_IS_TEST_SLIDE_WINDOW_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_TEST_SLIDE_WINDOW))
#define XSAA_TEST_SLIDE_WINDOW_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_TEST_SLIDE_WINDOW, XSAATestSlideWindowClass))

typedef struct _XSAATestSlideWindow XSAATestSlideWindow;
typedef struct _XSAATestSlideWindowClass XSAATestSlideWindowClass;
typedef struct _XSAATestSlideWindowPrivate XSAATestSlideWindowPrivate;

#define XSAA_TYPE_SLIDE_NOTEBOOK (xsaa_slide_notebook_get_type ())
#define XSAA_SLIDE_NOTEBOOK(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebook))
#define XSAA_SLIDE_NOTEBOOK_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebookClass))
#define XSAA_IS_SLIDE_NOTEBOOK(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SLIDE_NOTEBOOK))
#define XSAA_IS_SLIDE_NOTEBOOK_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SLIDE_NOTEBOOK))
#define XSAA_SLIDE_NOTEBOOK_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebookClass))

typedef struct _XSAASlideNotebook XSAASlideNotebook;
typedef struct _XSAASlideNotebookClass XSAASlideNotebookClass;

struct _XSAATestSlideWindow {
	GtkWindow parent_instance;
	XSAATestSlideWindowPrivate * priv;
};

struct _XSAATestSlideWindowClass {
	GtkWindowClass parent_class;
};

struct _XSAATestSlideWindowPrivate {
	XSAASlideNotebook* notebook;
};



GType xsaa_test_slide_window_get_type (void);
GType xsaa_slide_notebook_get_type (void);
#define XSAA_TEST_SLIDE_WINDOW_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_TEST_SLIDE_WINDOW, XSAATestSlideWindowPrivate))
enum  {
	XSAA_TEST_SLIDE_WINDOW_DUMMY_PROPERTY
};
XSAATestSlideWindow* xsaa_test_slide_window_new (void);
XSAATestSlideWindow* xsaa_test_slide_window_construct (GType object_type);
XSAATestSlideWindow* xsaa_test_slide_window_new (void);
void xsaa_test_slide_window_run (XSAATestSlideWindow* self);
static void _gtk_main_quit_gtk_object_destroy (XSAATestSlideWindow* _sender, gpointer self);
XSAASlideNotebook* xsaa_slide_notebook_new (void);
XSAASlideNotebook* xsaa_slide_notebook_construct (GType object_type);
gint xsaa_slide_notebook_append_page (XSAASlideNotebook* self, GtkWidget* widget, GtkWidget* label);
static GObject * xsaa_test_slide_window_constructor (GType type, guint n_construct_properties, GObjectConstructParam * construct_properties);
static gpointer xsaa_test_slide_window_parent_class = NULL;
static void xsaa_test_slide_window_finalize (GObject* obj);
gint xsaa_main (char** args, int args_length1);



XSAATestSlideWindow* xsaa_test_slide_window_construct (GType object_type) {
	XSAATestSlideWindow * self;
	self = g_object_newv (object_type, 0, NULL);
	gtk_window_set_title ((GtkWindow*) self, "Test Slide Notebook");
	return self;
}


XSAATestSlideWindow* xsaa_test_slide_window_new (void) {
	return xsaa_test_slide_window_construct (XSAA_TYPE_TEST_SLIDE_WINDOW);
}


void xsaa_test_slide_window_run (XSAATestSlideWindow* self) {
	g_return_if_fail (self != NULL);
	gtk_widget_show ((GtkWidget*) self);
	gtk_main ();
}


static void _gtk_main_quit_gtk_object_destroy (XSAATestSlideWindow* _sender, gpointer self) {
	gtk_main_quit ();
}


static GObject * xsaa_test_slide_window_constructor (GType type, guint n_construct_properties, GObjectConstructParam * construct_properties) {
	GObject * obj;
	XSAATestSlideWindowClass * klass;
	GObjectClass * parent_class;
	XSAATestSlideWindow * self;
	klass = XSAA_TEST_SLIDE_WINDOW_CLASS (g_type_class_peek (XSAA_TYPE_TEST_SLIDE_WINDOW));
	parent_class = G_OBJECT_CLASS (g_type_class_peek_parent (klass));
	obj = parent_class->constructor (type, n_construct_properties, construct_properties);
	self = XSAA_TEST_SLIDE_WINDOW (obj);
	{
		XSAASlideNotebook* _tmp0_;
		GtkLabel* label;
		GtkLabel* _tmp1_;
		GtkLabel* _tmp2_;
		/*set_default_size (600, 400);*/
		g_signal_connect ((GtkObject*) self, "destroy", (GCallback) _gtk_main_quit_gtk_object_destroy, NULL);
		_tmp0_ = NULL;
		self->priv->notebook = (_tmp0_ = g_object_ref_sink (xsaa_slide_notebook_new ()), (self->priv->notebook == NULL) ? NULL : (self->priv->notebook = (g_object_unref (self->priv->notebook), NULL)), _tmp0_);
		gtk_widget_show ((GtkWidget*) self->priv->notebook);
		gtk_container_add ((GtkContainer*) self, (GtkWidget*) self->priv->notebook);
		label = g_object_ref_sink ((GtkLabel*) gtk_label_new ("<span size='xx-large'>Page 1</span>"));
		gtk_label_set_use_markup (label, TRUE);
		gtk_widget_show ((GtkWidget*) label);
		xsaa_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) label, NULL);
		_tmp1_ = NULL;
		label = (_tmp1_ = g_object_ref_sink ((GtkLabel*) gtk_label_new ("<span size='xx-large'>Page 2</span>")), (label == NULL) ? NULL : (label = (g_object_unref (label), NULL)), _tmp1_);
		gtk_label_set_use_markup (label, TRUE);
		gtk_widget_show ((GtkWidget*) label);
		xsaa_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) label, NULL);
		_tmp2_ = NULL;
		label = (_tmp2_ = g_object_ref_sink ((GtkLabel*) gtk_label_new ("<span size='xx-large'>Page 3</span>")), (label == NULL) ? NULL : (label = (g_object_unref (label), NULL)), _tmp2_);
		gtk_label_set_use_markup (label, TRUE);
		gtk_widget_show ((GtkWidget*) label);
		xsaa_slide_notebook_append_page (self->priv->notebook, (GtkWidget*) label, NULL);
		(label == NULL) ? NULL : (label = (g_object_unref (label), NULL));
	}
	return obj;
}


static void xsaa_test_slide_window_class_init (XSAATestSlideWindowClass * klass) {
	xsaa_test_slide_window_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAATestSlideWindowPrivate));
	G_OBJECT_CLASS (klass)->constructor = xsaa_test_slide_window_constructor;
	G_OBJECT_CLASS (klass)->finalize = xsaa_test_slide_window_finalize;
}


static void xsaa_test_slide_window_instance_init (XSAATestSlideWindow * self) {
	self->priv = XSAA_TEST_SLIDE_WINDOW_GET_PRIVATE (self);
}


static void xsaa_test_slide_window_finalize (GObject* obj) {
	XSAATestSlideWindow * self;
	self = XSAA_TEST_SLIDE_WINDOW (obj);
	(self->priv->notebook == NULL) ? NULL : (self->priv->notebook = (g_object_unref (self->priv->notebook), NULL));
	G_OBJECT_CLASS (xsaa_test_slide_window_parent_class)->finalize (obj);
}


GType xsaa_test_slide_window_get_type (void) {
	static GType xsaa_test_slide_window_type_id = 0;
	if (xsaa_test_slide_window_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAATestSlideWindowClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_test_slide_window_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAATestSlideWindow), 0, (GInstanceInitFunc) xsaa_test_slide_window_instance_init, NULL };
		xsaa_test_slide_window_type_id = g_type_register_static (GTK_TYPE_WINDOW, "XSAATestSlideWindow", &g_define_type_info, 0);
	}
	return xsaa_test_slide_window_type_id;
}


gint xsaa_main (char** args, int args_length1) {
	XSAATestSlideWindow* window;
	gint _tmp0_;
	gtk_init (&args_length1, &args);
	window = g_object_ref_sink (xsaa_test_slide_window_new ());
	xsaa_test_slide_window_run (window);
	return (_tmp0_ = 0, (window == NULL) ? NULL : (window = (g_object_unref (window), NULL)), _tmp0_);
}


int main (int argc, char ** argv) {
	g_type_init ();
	return xsaa_main (argv, argc);
}




