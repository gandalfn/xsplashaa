XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-graphics.la

libxsaa_graphics_la_VALAFLAGS = \
    --header=xsaa-graphics.h \
    --library=xsaa-graphics \
    --vapi=xsaa-graphics.vapi \
    --pkg=gtk+-2.0

libxsaa_graphics_la_SOURCES = \
    cairo-color.vala \
    cairo-pattern.vala \
    cairo-context.vala

libxsaa_graphics_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_graphics_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_graphics_la_vala.stamp \
    xsaa-graphics.vapi \
    xsaa-graphics.h

EXTRA_DIST = \
    xsaa-graphics.vapi \
    xsaa-graphics.h

