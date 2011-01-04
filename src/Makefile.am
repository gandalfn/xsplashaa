INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

VALAFLAGS = \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=source \
    --pkg=vala-0.10 \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=posix \
    --pkg=posix-comp \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

noinst_LTLIBRARIES = libxsaa-private.la

bin_PROGRAMS = xsplashaa xsplashaa-client xsplashaa-session-daemon

libxsaa_private_la_VALAFLAGS = \
    --header=xsaa-private.h \
    --library=xsaa-private \
    --vapi=xsaa-private.vapi

libxsaa_private_la_SOURCES = \
    xsaa-cairo-context.vala \
    xsaa-log.vala \
    xsaa-socket.vala

noinst_HEADERS = xsaa-source.h

xsplashaa_SOURCES = \
    xsaa-source.c \
    xsaa-timeout-interval.vala \
    xsaa-timeout-pool.vala \
    xsaa-timeout.vala \
    xsaa-timeline.vala \
    xsaa-slide-notebook.vala \
    xsaa-server.vala \
    xsaa-display.vala \
    xsaa-throbber.vala \
    xsaa-splash.vala \
    xsaa-main.vala

xsplashaa_VALAFLAGS = \
    --vapidir=. \
    --pkg=xsaa-private

xsplashaa_LDADD = \
    $(XSPLASHAA_LIBS) libxsaa-private.la

xsplashaa_client_SOURCES = \
    xsaa-client.vala

xsplashaa_client_VALAFLAGS = \
    --vapidir=. \
    --pkg=xsaa-private

xsplashaa_client_LDFLAGS = -static

xsplashaa_client_LDADD = \
    $(XSPLASHAA_CLIENT_LIBS) libxsaa-private.la

xsplashaa_session_daemon_VALAFLAGS = \
    --vapidir=. \
    --pkg=xsaa-private

xsplashaa_session_daemon_CFLAGS = \
    $(XSPLASHAA_SESSION_DAEMON_CFLAGS)

xsplashaa_session_daemon_SOURCES = \
    xsaa-users.vala \
    xsaa-pam.vala \
    xsaa-session.vala \
    xsaa-session-daemon.vala

xsplashaa_session_daemon_LDFLAGS = -static

xsplashaa_session_daemon_LDADD = \
    $(XSPLASHAA_SESSION_DAEMON_LIBS) -lpam libxsaa-private.la

xsplashaa_vala.stamp: libxsaa_private_la_vala.stamp

xsplashaa_client_vala.stamp: libxsaa_private_la_vala.stamp

xsplashaa_session_daemon_vala.stamp: libxsaa_private_la_vala.stamp

VALAFILES = \
    $(filter %.vala,$(libxsaa_private_la_SOURCES)) \
    $(filter %.vala,$(xsplashaa_SOURCES)) \
    $(filter %.vala,$(xsplashaa_client_SOURCES)) \
    $(filter %.vala,$(xsplashaa_session_daemon_SOURCES))

EXTRA_DIST = \
    xsaa-private.h \
    xsaa-private.vapi \
    $(VALAFILES:.vala=.c) \
    libxsaa_private_la_vala.stamp \
    xsplashaa_vala.stamp \
    xsplashaa_client_vala.stamp \
    xsplashaa_session_daemon_vala.stamp

CLEANFILES = \
    $(EXTRA_DIST)

DISTCLEANFILES = \
    $(EXTRA_DIST)
