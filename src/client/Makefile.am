XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi \
    $(top_srcdir)/src/socket/xsaa-socket.vapi

include $(top_srcdir)/build/vala.am

bin_PROGRAMS = xsplashaa-client

xsplashaa_client_SOURCES = \
    client.vala

xsplashaa_client_LDFLAGS = -static

xsplashaa_client_LDADD = \
    $(XSPLASHAA_CLIENT_LIBS) \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(xsplashaa_client_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_client_vala.stamp

