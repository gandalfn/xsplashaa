/* xsaa-slide-notebook.vala
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
#include <ccm-timeline.h>
#include <cairo.h>
#include <gdk/gdk.h>


#define XSAA_TYPE_SLIDE_NOTEBOOK (xsaa_slide_notebook_get_type ())
#define XSAA_SLIDE_NOTEBOOK(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebook))
#define XSAA_SLIDE_NOTEBOOK_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebookClass))
#define XSAA_IS_SLIDE_NOTEBOOK(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_TYPE_SLIDE_NOTEBOOK))
#define XSAA_IS_SLIDE_NOTEBOOK_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_TYPE_SLIDE_NOTEBOOK))
#define XSAA_SLIDE_NOTEBOOK_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebookClass))

typedef struct _XSAASlideNotebook XSAASlideNotebook;
typedef struct _XSAASlideNotebookClass XSAASlideNotebookClass;
typedef struct _XSAASlideNotebookPrivate XSAASlideNotebookPrivate;

struct _XSAASlideNotebook {
	GtkNotebook parent_instance;
	XSAASlideNotebookPrivate * priv;
};

struct _XSAASlideNotebookClass {
	GtkNotebookClass parent_class;
};

struct _XSAASlideNotebookPrivate {
	CCMTimeline* timeline;
	cairo_surface_t* previous_surface;
	gint previous_page;
};



GType xsaa_slide_notebook_get_type (void);
#define XSAA_SLIDE_NOTEBOOK_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), XSAA_TYPE_SLIDE_NOTEBOOK, XSAASlideNotebookPrivate))
enum  {
	XSAA_SLIDE_NOTEBOOK_DUMMY_PROPERTY,
	XSAA_SLIDE_NOTEBOOK_DURATION
};
static void xsaa_slide_notebook_on_timeline_completed (XSAASlideNotebook* self);
static gboolean xsaa_slide_notebook_on_page_expose_event (XSAASlideNotebook* self, GtkEventBox* page, const GdkEventExpose* event);
static void _lambda0_ (GtkEventBox* p, XSAASlideNotebook* self);
static void __lambda0__gtk_widget_realize (GtkEventBox* _sender, gpointer self);
static gboolean _xsaa_slide_notebook_on_page_expose_event_gtk_widget_expose_event (GtkEventBox* _sender, const GdkEventExpose* event, gpointer self);
gint xsaa_slide_notebook_append_page (XSAASlideNotebook* self, GtkWidget* widget, GtkWidget* label);
static void xsaa_slide_notebook_real_switch_page (GtkNotebook* base, void* page, guint page_num);
static gboolean xsaa_slide_notebook_real_expose_event (GtkWidget* base, const GdkEventExpose* event);
XSAASlideNotebook* xsaa_slide_notebook_new (void);
XSAASlideNotebook* xsaa_slide_notebook_construct (GType object_type);
XSAASlideNotebook* xsaa_slide_notebook_new (void);
guint xsaa_slide_notebook_get_duration (XSAASlideNotebook* self);
void xsaa_slide_notebook_set_duration (XSAASlideNotebook* self, guint value);
static void _lambda1_ (XSAASlideNotebook* self);
static void __lambda1__ccm_timeline_new_frame (CCMTimeline* _sender, gint object, gpointer self);
static void _xsaa_slide_notebook_on_timeline_completed_ccm_timeline_completed (CCMTimeline* _sender, gpointer self);
static GObject * xsaa_slide_notebook_constructor (GType type, guint n_construct_properties, GObjectConstructParam * construct_properties);
static gpointer xsaa_slide_notebook_parent_class = NULL;
static void xsaa_slide_notebook_finalize (GObject* obj);
static void xsaa_slide_notebook_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec);
static void xsaa_slide_notebook_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec);



static void xsaa_slide_notebook_on_timeline_completed (XSAASlideNotebook* self) {
	GtkEventBox* _tmp0_;
	GtkEventBox* previous;
	cairo_t* cr;
	cairo_surface_t* _tmp1_;
	cairo_t* cr_previous;
	g_return_if_fail (self != NULL);
	self->priv->previous_page = gtk_notebook_get_current_page ((GtkNotebook*) self);
	_tmp0_ = NULL;
	previous = (_tmp0_ = GTK_EVENT_BOX (gtk_notebook_get_nth_page ((GtkNotebook*) self, self->priv->previous_page)), (_tmp0_ == NULL) ? NULL : g_object_ref (_tmp0_));
	cr = gdk_cairo_create ((GdkDrawable*) gtk_widget_get_window ((GtkWidget*) previous));
	_tmp1_ = NULL;
	self->priv->previous_surface = (_tmp1_ = cairo_surface_create_similar (cairo_get_target (cr), CAIRO_CONTENT_COLOR_ALPHA, ((GtkWidget*) previous)->allocation.width, ((GtkWidget*) previous)->allocation.height), (self->priv->previous_surface == NULL) ? NULL : (self->priv->previous_surface = (cairo_surface_destroy (self->priv->previous_surface), NULL)), _tmp1_);
	cr_previous = cairo_create (self->priv->previous_surface);
	cairo_set_operator (cr_previous, CAIRO_OPERATOR_SOURCE);
	cairo_set_source_surface (cr_previous, cairo_get_target (cr), (double) 0, (double) 0);
	cairo_paint (cr_previous);
	(previous == NULL) ? NULL : (previous = (g_object_unref (previous), NULL));
	(cr == NULL) ? NULL : (cr = (cairo_destroy (cr), NULL));
	(cr_previous == NULL) ? NULL : (cr_previous = (cairo_destroy (cr_previous), NULL));
}


static gboolean xsaa_slide_notebook_on_page_expose_event (XSAASlideNotebook* self, GtkEventBox* page, const GdkEventExpose* event) {
	cairo_t* cr;
	gboolean _tmp0_;
	g_return_val_if_fail (self != NULL, FALSE);
	g_return_val_if_fail (page != NULL, FALSE);
	cr = gdk_cairo_create ((GdkDrawable*) gtk_widget_get_window ((GtkWidget*) page));
	cairo_set_operator (cr, CAIRO_OPERATOR_CLEAR);
	cairo_paint (cr);
	return (_tmp0_ = FALSE, (cr == NULL) ? NULL : (cr = (cairo_destroy (cr), NULL)), _tmp0_);
}


static void _lambda0_ (GtkEventBox* p, XSAASlideNotebook* self) {
	g_return_if_fail (p != NULL);
	gdk_window_set_composited (gtk_widget_get_window ((GtkWidget*) p), TRUE);
}


static void __lambda0__gtk_widget_realize (GtkEventBox* _sender, gpointer self) {
	_lambda0_ (_sender, self);
}


static gboolean _xsaa_slide_notebook_on_page_expose_event_gtk_widget_expose_event (GtkEventBox* _sender, const GdkEventExpose* event, gpointer self) {
	return xsaa_slide_notebook_on_page_expose_event (self, _sender, event);
}


gint xsaa_slide_notebook_append_page (XSAASlideNotebook* self, GtkWidget* widget, GtkWidget* label) {
	GtkEventBox* page;
	GdkScreen* _tmp0_;
	GdkScreen* screen;
	gint _tmp1_;
	g_return_val_if_fail (self != NULL, 0);
	g_return_val_if_fail (widget != NULL, 0);
	page = g_object_ref_sink ((GtkEventBox*) gtk_event_box_new ());
	gtk_widget_show ((GtkWidget*) page);
	gtk_widget_set_app_paintable ((GtkWidget*) page, TRUE);
	g_signal_connect ((GtkWidget*) page, "realize", (GCallback) __lambda0__gtk_widget_realize, self);
	g_signal_connect_object ((GtkWidget*) page, "expose-event", (GCallback) _xsaa_slide_notebook_on_page_expose_event_gtk_widget_expose_event, self, 0);
	_tmp0_ = NULL;
	screen = (_tmp0_ = gtk_widget_get_screen ((GtkWidget*) page), (_tmp0_ == NULL) ? NULL : g_object_ref (_tmp0_));
	gtk_widget_set_colormap ((GtkWidget*) page, gdk_screen_get_rgba_colormap (screen));
	gtk_container_add ((GtkContainer*) page, widget);
	return (_tmp1_ = gtk_notebook_append_page (GTK_NOTEBOOK (self), (GtkWidget*) page, label), (page == NULL) ? NULL : (page = (g_object_unref (page), NULL)), (screen == NULL) ? NULL : (screen = (g_object_unref (screen), NULL)), _tmp1_);
}


static void xsaa_slide_notebook_real_switch_page (GtkNotebook* base, void* page, guint page_num) {
	XSAASlideNotebook * self;
	self = (XSAASlideNotebook*) base;
	self->priv->previous_page = gtk_notebook_get_current_page ((GtkNotebook*) self);
	if (self->priv->previous_page >= 0) {
		ccm_timeline_start (self->priv->timeline);
	}
	GTK_NOTEBOOK_CLASS (xsaa_slide_notebook_parent_class)->switch_page (GTK_NOTEBOOK (self), page, page_num);
}


static gboolean xsaa_slide_notebook_real_expose_event (GtkWidget* base, const GdkEventExpose* event) {
	XSAASlideNotebook * self;
	gboolean ret;
	cairo_t* cr;
	gint _tmp0_;
	gboolean _tmp10_;
	self = (XSAASlideNotebook*) base;
	ret = GTK_WIDGET_CLASS (xsaa_slide_notebook_parent_class)->expose_event ((GtkWidget*) GTK_NOTEBOOK (self), &(*event));
	cr = gdk_cairo_create ((GdkDrawable*) gtk_widget_get_window ((GtkWidget*) self));
	cairo_rectangle (cr, (double) (*event).area.x, (double) (*event).area.y, (double) (*event).area.width, (double) (*event).area.height);
	cairo_clip (cr);
	if ((g_object_get ((GtkNotebook*) self, "page", &_tmp0_, NULL), _tmp0_) >= 0) {
		GtkEventBox* _tmp2_;
		gint _tmp1_;
		GtkEventBox* current;
		GdkRectangle _tmp3_ = {0};
		GdkRegion* region;
		gboolean _tmp4_;
		gint _tmp5_;
		_tmp2_ = NULL;
		current = (_tmp2_ = GTK_EVENT_BOX (gtk_notebook_get_nth_page ((GtkNotebook*) self, (g_object_get ((GtkNotebook*) self, "page", &_tmp1_, NULL), _tmp1_))), (_tmp2_ == NULL) ? NULL : g_object_ref (_tmp2_));
		region = gdk_region_rectangle ((_tmp3_ = (GdkRectangle) ((GtkWidget*) current)->allocation, &_tmp3_));
		gdk_region_intersect (region, (*event).region);
		gdk_cairo_region (cr, region);
		cairo_clip (cr);
		_tmp4_ = FALSE;
		if (self->priv->previous_page != (g_object_get ((GtkNotebook*) self, "page", &_tmp5_, NULL), _tmp5_)) {
			_tmp4_ = self->priv->previous_page >= 0;
		} else {
			_tmp4_ = FALSE;
		}
		if (_tmp4_) {
			cairo_t* cr_current;
			gint x;
			gint _tmp6_;
			gint _tmp7_;
			gint _tmp8_;
			gint _tmp9_;
			cr_current = gdk_cairo_create ((GdkDrawable*) gtk_widget_get_window ((GtkWidget*) current));
			x = 0;
			if ((g_object_get ((GtkNotebook*) self, "page", &_tmp6_, NULL), _tmp6_) < self->priv->previous_page) {
				x = ((GtkWidget*) current)->allocation.x - (((GtkWidget*) current)->allocation.width - ((gint) (((double) ((GtkWidget*) current)->allocation.width) * ccm_timeline_get_progress (self->priv->timeline))));
			} else {
				x = ((GtkWidget*) current)->allocation.x - ((gint) (((double) ((GtkWidget*) current)->allocation.width) * ccm_timeline_get_progress (self->priv->timeline)));
			}
			cairo_save (cr);
			cairo_set_operator (cr, CAIRO_OPERATOR_OVER);
			if ((g_object_get ((GtkNotebook*) self, "page", &_tmp7_, NULL), _tmp7_) < self->priv->previous_page) {
				cairo_set_source_surface (cr, cairo_get_target (cr_current), (double) x, (double) ((GtkWidget*) current)->allocation.y);
			} else {
				cairo_set_source_surface (cr, self->priv->previous_surface, (double) x, (double) ((GtkWidget*) current)->allocation.y);
			}
			cairo_paint (cr);
			cairo_restore (cr);
			if ((g_object_get ((GtkNotebook*) self, "page", &_tmp8_, NULL), _tmp8_) < self->priv->previous_page) {
				x = ((GtkWidget*) current)->allocation.x + ((gint) (((double) ((GtkWidget*) current)->allocation.width) * ccm_timeline_get_progress (self->priv->timeline)));
			} else {
				x = ((GtkWidget*) current)->allocation.x + (((GtkWidget*) current)->allocation.width - ((gint) (((double) ((GtkWidget*) current)->allocation.width) * ccm_timeline_get_progress (self->priv->timeline))));
			}
			if ((g_object_get ((GtkNotebook*) self, "page", &_tmp9_, NULL), _tmp9_) < self->priv->previous_page) {
				cairo_set_source_surface (cr, self->priv->previous_surface, (double) x, (double) ((GtkWidget*) current)->allocation.y);
			} else {
				cairo_set_source_surface (cr, cairo_get_target (cr_current), (double) x, (double) ((GtkWidget*) current)->allocation.y);
			}
			cairo_save (cr);
			cairo_paint (cr);
			cairo_restore (cr);
			(cr_current == NULL) ? NULL : (cr_current = (cairo_destroy (cr_current), NULL));
		} else {
			gdk_cairo_set_source_pixmap (cr, (GdkPixmap*) gtk_widget_get_window ((GtkWidget*) current), (double) ((GtkWidget*) current)->allocation.x, (double) ((GtkWidget*) current)->allocation.y);
			cairo_set_operator (cr, CAIRO_OPERATOR_OVER);
			cairo_paint (cr);
			xsaa_slide_notebook_on_timeline_completed (self);
		}
		(current == NULL) ? NULL : (current = (g_object_unref (current), NULL));
		(region == NULL) ? NULL : (region = (gdk_region_destroy (region), NULL));
	}
	return (_tmp10_ = ret, (cr == NULL) ? NULL : (cr = (cairo_destroy (cr), NULL)), _tmp10_);
}


XSAASlideNotebook* xsaa_slide_notebook_construct (GType object_type) {
	XSAASlideNotebook * self;
	self = g_object_newv (object_type, 0, NULL);
	return self;
}


XSAASlideNotebook* xsaa_slide_notebook_new (void) {
	return xsaa_slide_notebook_construct (XSAA_TYPE_SLIDE_NOTEBOOK);
}


guint xsaa_slide_notebook_get_duration (XSAASlideNotebook* self) {
	g_return_val_if_fail (self != NULL, 0U);
	return ccm_timeline_get_duration (self->priv->timeline);
}


void xsaa_slide_notebook_set_duration (XSAASlideNotebook* self, guint value) {
	g_return_if_fail (self != NULL);
	ccm_timeline_set_duration (self->priv->timeline, value);
	g_object_notify ((GObject *) self, "duration");
}


static void _lambda1_ (XSAASlideNotebook* self) {
	gtk_widget_queue_draw ((GtkWidget*) self);
}


static void __lambda1__ccm_timeline_new_frame (CCMTimeline* _sender, gint object, gpointer self) {
	_lambda1_ (self);
}


static void _xsaa_slide_notebook_on_timeline_completed_ccm_timeline_completed (CCMTimeline* _sender, gpointer self) {
	xsaa_slide_notebook_on_timeline_completed (self);
}


static GObject * xsaa_slide_notebook_constructor (GType type, guint n_construct_properties, GObjectConstructParam * construct_properties) {
	GObject * obj;
	XSAASlideNotebookClass * klass;
	GObjectClass * parent_class;
	XSAASlideNotebook * self;
	klass = XSAA_SLIDE_NOTEBOOK_CLASS (g_type_class_peek (XSAA_TYPE_SLIDE_NOTEBOOK));
	parent_class = G_OBJECT_CLASS (g_type_class_peek_parent (klass));
	obj = parent_class->constructor (type, n_construct_properties, construct_properties);
	self = XSAA_SLIDE_NOTEBOOK (obj);
	{
		CCMTimeline* _tmp0_;
		_tmp0_ = NULL;
		self->priv->timeline = (_tmp0_ = ccm_timeline_new_for_duration ((guint) 400), (self->priv->timeline == NULL) ? NULL : (self->priv->timeline = (g_object_unref (self->priv->timeline), NULL)), _tmp0_);
		g_signal_connect (self->priv->timeline, "new-frame", (GCallback) __lambda1__ccm_timeline_new_frame, self);
		g_signal_connect_object (self->priv->timeline, "completed", (GCallback) _xsaa_slide_notebook_on_timeline_completed_ccm_timeline_completed, self, 0);
	}
	return obj;
}


static void xsaa_slide_notebook_class_init (XSAASlideNotebookClass * klass) {
	xsaa_slide_notebook_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (XSAASlideNotebookPrivate));
	GTK_NOTEBOOK_CLASS (klass)->switch_page = xsaa_slide_notebook_real_switch_page;
	GTK_WIDGET_CLASS (klass)->expose_event = xsaa_slide_notebook_real_expose_event;
	G_OBJECT_CLASS (klass)->get_property = xsaa_slide_notebook_get_property;
	G_OBJECT_CLASS (klass)->set_property = xsaa_slide_notebook_set_property;
	G_OBJECT_CLASS (klass)->constructor = xsaa_slide_notebook_constructor;
	G_OBJECT_CLASS (klass)->finalize = xsaa_slide_notebook_finalize;
	g_object_class_install_property (G_OBJECT_CLASS (klass), XSAA_SLIDE_NOTEBOOK_DURATION, g_param_spec_uint ("duration", "duration", "duration", 0, G_MAXUINT, 400, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));
}


static void xsaa_slide_notebook_instance_init (XSAASlideNotebook * self) {
	self->priv = XSAA_SLIDE_NOTEBOOK_GET_PRIVATE (self);
	self->priv->previous_surface = NULL;
	self->priv->previous_page = -1;
}


static void xsaa_slide_notebook_finalize (GObject* obj) {
	XSAASlideNotebook * self;
	self = XSAA_SLIDE_NOTEBOOK (obj);
	(self->priv->timeline == NULL) ? NULL : (self->priv->timeline = (g_object_unref (self->priv->timeline), NULL));
	(self->priv->previous_surface == NULL) ? NULL : (self->priv->previous_surface = (cairo_surface_destroy (self->priv->previous_surface), NULL));
	G_OBJECT_CLASS (xsaa_slide_notebook_parent_class)->finalize (obj);
}


GType xsaa_slide_notebook_get_type (void) {
	static GType xsaa_slide_notebook_type_id = 0;
	if (xsaa_slide_notebook_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (XSAASlideNotebookClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) xsaa_slide_notebook_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (XSAASlideNotebook), 0, (GInstanceInitFunc) xsaa_slide_notebook_instance_init, NULL };
		xsaa_slide_notebook_type_id = g_type_register_static (GTK_TYPE_NOTEBOOK, "XSAASlideNotebook", &g_define_type_info, 0);
	}
	return xsaa_slide_notebook_type_id;
}


static void xsaa_slide_notebook_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec) {
	XSAASlideNotebook * self;
	gpointer boxed;
	self = XSAA_SLIDE_NOTEBOOK (object);
	switch (property_id) {
		case XSAA_SLIDE_NOTEBOOK_DURATION:
		g_value_set_uint (value, xsaa_slide_notebook_get_duration (self));
		break;
		default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}


static void xsaa_slide_notebook_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec) {
	XSAASlideNotebook * self;
	self = XSAA_SLIDE_NOTEBOOK (object);
	switch (property_id) {
		case XSAA_SLIDE_NOTEBOOK_DURATION:
		xsaa_slide_notebook_set_duration (self, g_value_get_uint (value));
		break;
		default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}




