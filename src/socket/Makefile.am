INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

noinst_LTLIBRARIES = libxsaa-socket.la

libxsaa_socket_la_VALAFLAGS = \
    --thread \
    --header=socket.h \
    --library=xsaa-socket \
    --vapi=xsaa-socket.vapi \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=os

libxsaa_socket_la_SOURCES = \
    socket.vala

VALAFILES = \
    $(filter %.vala,$(libxsaa_socket_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_socket_la_vala.stamp \
    xsaa-socket.vapi \
    socket.h

