INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

noinst_HEADERS = source.h

noinst_LTLIBRARIES = libxsaa-timeline.la

libxsaa_timeline_la_VALAFLAGS = \
    --thread \
    --header=timeline.h \
    --library=xsaa-timeline \
    --vapi=xsaa-timeline.vapi \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=os \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

libxsaa_timeline_la_CFLAGS = \
    -I$(top_builddir)/src/graphics

libxsaa_timeline_la_SOURCES = \
    source.c \
    timeout-interval.vala \
    timeout-pool.vala \
    timeout.vala \
    timeline.vala \
    animator.vala

VALAFILES = \
    $(filter %.vala,$(libxsaa_timeline_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_timeline_la_vala.stamp \
    xsaa-timeline.vapi \
    timeline.h

