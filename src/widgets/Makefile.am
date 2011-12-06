XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi \
    $(top_builddir)/src/graphics/xsaa-graphics.vapi \
    $(top_builddir)/src/timeline/xsaa-timeline.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-widgets.la

libxsaa_widgets_la_VALAFLAGS = \
    --thread \
    --header=widgets.h \
    --library=xsaa-widgets \
    --vapi=xsaa-widgets.vapi \
    --pkg=source \
    --pkg=gdk-x11-2.0 \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

libxsaa_widgets_la_SOURCES = \
    slide-notebook.vala \
    throbber.vala \
    segmented-bar.vala

libxsaa_widgets_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_widgets_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_widgets_la_vala.stamp \
    xsaa-widgets.vapi \
    widgets.h

