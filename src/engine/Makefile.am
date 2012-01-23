SUBDIRS = . aixplorer

XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi \
    $(top_srcdir)/src/xml/xsaa-xml.vapi \
    $(top_srcdir)/src/graphics/xsaa-graphics.vapi \
    $(top_srcdir)/src/timeline/xsaa-timeline.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-engine.la

libxsaa_engine_la_VALAFLAGS = \
    --thread \
    --header=xsaa-engine.h \
    --library=xsaa-engine \
    --vapi=xsaa-engine.vapi \
    --pkg=gmodule-2.0 \
    --pkg=gtk+-2.0 \
    --pkg=goocanvas \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

libxsaa_engine_la_SOURCES = \
    event.vala \
    event-prompt.vala \
    event-boot.vala \
    event-progress.vala \
    event-session.vala \
    event-user.vala \
    event-system.vala \
    event-message.vala \
    engine-item.vala \
    engine.vala \
    engine-loader.vala

libxsaa_engine_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

noinst_PROGRAMS = \
    test-engine

test_engine_VALAFLAGS = \
    --thread \
    --pkg=gmodule-2.0 \
    --pkg=gtk+-2.0 \
    --pkg=goocanvas \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp \
    --vapidir=. \
    --pkg=xsaa-engine

test_engine_SOURCES = \
    test-engine.vala

test_engine_LDADD = \
    $(XSPLASHAA_LIBS) \
    libxsaa-engine.la

VALAFILES = \
    $(filter %.vala,$(libxsaa_engine_la_SOURCES)) \
    $(filter %.vala,$(test_engine_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_engine_la_vala.stamp \
    xsaa-engine.vapi \
    xsaa-engine.h

EXTRA_DIST = \
    xsaa-engine.vapi \
    xsaa-engine.h

.NOTPARALLEL: libxsaa-engine.la test-engine

