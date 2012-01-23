XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-socket.la

libxsaa_socket_la_VALAFLAGS = \
    --thread \
    --header=xsaa-socket.h \
    --library=xsaa-socket \
    --vapi=xsaa-socket.vapi

libxsaa_socket_la_SOURCES = \
    message.vala \
    socket.vala \
    client.vala \
    server.vala

libxsaa_socket_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_socket_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_socket_la_vala.stamp \
    xsaa-socket.vapi \
    xsaa-socket.h

EXTRA_DIST = \
    xsaa-socket.vapi \
    xsaa-socket.h

