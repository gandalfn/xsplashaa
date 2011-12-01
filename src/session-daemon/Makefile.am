XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi \
    $(top_builddir)/src/socket/xsaa-socket.vapi \
    $(top_builddir)/src/graphics/xsaa-graphics.vapi

include $(top_srcdir)/build/vala.am

bin_PROGRAMS = xsplashaa-session-daemon

xsplashaa_session_daemon_VALAFLAGS = \
    --thread \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

xsplashaa_session_daemon_CFLAGS = \
    $(XSPLASHAA_SESSION_DAEMON_CFLAGS)

xsplashaa_session_daemon_SOURCES = \
    freedesktop.vala \
    users.vala \
    pam.vala \
    session.vala \
    session-daemon.vala

xsplashaa_session_daemon_LDFLAGS = -static

xsplashaa_session_daemon_LDADD = \
    $(XSPLASHAA_SESSION_DAEMON_LIBS) -lpam $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(xsplashaa_session_daemon_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_session_daemon_vala.stamp

