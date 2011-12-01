XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-socket.la

libxsaa_socket_la_VALAFLAGS = \
    --thread \
    --header=socket.h \
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
    socket.h

