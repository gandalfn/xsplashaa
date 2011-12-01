INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

VALAFLAGS = \
    --thread \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=os \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

bin_PROGRAMS = xsplashaa

xsplashaa_SOURCES = \
    server.vala \
    display.vala \
    splash.vala \
    main.vala

xsplashaa_VALAFLAGS = \
    --thread \
    --vapidir=${top_srcdir}/vapi \
    --vapidir=$(top_builddir)/src/log \
    --vapidir=$(top_builddir)/src/socket \
    --vapidir=$(top_builddir)/src/graphics \
    --vapidir=$(top_builddir)/src/timeline \
    --vapidir=$(top_builddir)/src/widgets \
    --pkg=config \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=os \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp \
    --pkg=xsaa-log \
    --pkg=xsaa-socket \
    --pkg=xsaa-graphics \
    --pkg=xsaa-timeline \
    --pkg=xsaa-widgets

xsplashaa_CFLAGS = \
    -I$(top_builddir)/src/log \
    -I$(top_builddir)/src/socket \
    -I$(top_builddir)/src/graphics \
    -I$(top_builddir)/src/timeline \
    -I$(top_builddir)/src/widgets

xsplashaa_LDADD = \
    $(XSPLASHAA_LIBS) \
    $(top_builddir)/src/log/libxsaa-log.la \
    $(top_builddir)/src/socket/libxsaa-socket.la \
    $(top_builddir)/src/graphics/libxsaa-graphics.la \
    $(top_builddir)/src/timeline/libxsaa-timeline.la \
    $(top_builddir)/src/widgets/libxsaa-widgets.la

VALAFILES = \
    $(filter %.vala,$(xsplashaa_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_vala.stamp

