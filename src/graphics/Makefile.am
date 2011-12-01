INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

noinst_LTLIBRARIES = libxsaa-graphics.la

libxsaa_graphics_la_VALAFLAGS = \
    --thread \
    --header=graphics.h \
    --library=xsaa-graphics \
    --vapi=xsaa-graphics.vapi \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=os \
    --pkg=gtk+-2.0

libxsaa_graphics_la_SOURCES = \
    cairo-context.vala

VALAFILES = \
    $(filter %.vala,$(libxsaa_graphics_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_graphics_la_vala.stamp \
    xsaa-graphics.vapi \
    graphics.h

