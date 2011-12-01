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

bin_PROGRAMS = xsplashaa-session-daemon

xsplashaa_session_daemon_VALAFLAGS = \
    --thread \
    --vapidir=${top_srcdir}/vapi \
    --vapidir=$(top_builddir)/src/log \
    --vapidir=$(top_builddir)/src/socket \
    --vapidir=$(top_builddir)/src/graphics \
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
    --pkg=xsaa-graphics

xsplashaa_session_daemon_CFLAGS = \
    $(XSPLASHAA_SESSION_DAEMON_CFLAGS) \
    -I$(top_builddir)/src/log \
    -I$(top_builddir)/src/socket \
    -I$(top_builddir)/src/graphics

xsplashaa_session_daemon_SOURCES = \
    users.vala \
    pam.vala \
    session.vala \
    session-daemon.vala

xsplashaa_session_daemon_LDFLAGS = -static

xsplashaa_session_daemon_LDADD = \
    $(XSPLASHAA_SESSION_DAEMON_LIBS) -lpam \
    $(top_builddir)/src/log/libxsaa-log.la \
    $(top_builddir)/src/socket/libxsaa-socket.la \
    $(top_builddir)/src/graphics/libxsaa-graphics.la

VALAFILES = \
    $(filter %.vala,$(xsplashaa_session_daemon_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_session_daemon_vala.stamp

