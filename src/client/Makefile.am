INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

bin_PROGRAMS = xsplashaa-client

xsplashaa_client_SOURCES = \
    client.vala

xsplashaa_client_VALAFLAGS = \
    --thread \
    --vapidir=${top_srcdir}/vapi \
    --vapidir=$(top_builddir)/src/log \
    --vapidir=$(top_builddir)/src/socket \
    --pkg=config \
    --pkg=os \
    --pkg=xsaa-log \
    --pkg=xsaa-socket

xsplashaa_client_CFLAGS = \
    -I$(top_builddir)/src/log \
    -I$(top_builddir)/src/socket

xsplashaa_client_LDFLAGS = -static

xsplashaa_client_LDADD = \
    $(XSPLASHAA_CLIENT_LIBS) \
    $(top_builddir)/src/log/libxsaa-log.la \
    $(top_builddir)/src/socket/libxsaa-socket.la

VALAFILES = \
    $(filter %.vala,$(xsplashaa_client_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_client_vala.stamp

