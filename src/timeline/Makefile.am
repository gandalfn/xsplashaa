XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi \
    $(top_srcdir)/src/graphics/xsaa-graphics.vapi

include $(top_srcdir)/build/vala.am

noinst_HEADERS = source.h

noinst_LTLIBRARIES = libxsaa-timeline.la

libxsaa_timeline_la_VALAFLAGS = \
    --thread \
    --header=xsaa-timeline.h \
    --library=xsaa-timeline \
    --vapi=xsaa-timeline.vapi \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

libxsaa_timeline_la_SOURCES = \
    source.c \
    timeout-interval.vala \
    timeout-pool.vala \
    timeout.vala \
    timeline.vala \
    animator.vala

libxsaa_timeline_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_timeline_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_timeline_la_vala.stamp \
    xsaa-timeline.vapi \
    xsaa-timeline.h

EXTRA_DIST = \
    xsaa-timeline.vapi \
    xsaa-timeline.h

