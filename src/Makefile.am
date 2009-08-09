INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\"
    
VALAFLAGS = \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=vala-1.0 \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=posix \
    --pkg=posix-comp \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp \
    --pkg=ssi-timeline \
    --pkg=ssi-vala-widgets

bin_PROGRAMS = xsplashaa xsplashaa-client xsplashaa-session-daemon

noinst_LTLIBRARIES = libxsaa-private.la

libxsaa_private_la_VALAFLAGS = \
    --header=xsaa-private.h \
   	--library=xsaa-private \
   	--vapi=xsaa-private.vapi

libxsaa_private_la_SOURCES = \
   	xsaa-socket.vala

xsplashaa_SOURCES = \
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

xsplashaa_client_LDADD = \
	$(XSPLASHAA_LIBS) libxsaa-private.la

xsplashaa_session_daemon_SOURCES = \
    xsaa-pam.vala \
    xsaa-session.vala \
    xsaa-session-daemon.vala

xsplashaa_session_daemon_LDADD = \
	$(XSPLASHAA_LIBS) -lpam

CLEANFILES = \
    xsaa-private.h \
    xsaa-private.vapi \
    $(libxsaa_private_la_SOURCES:.vala=.c) \
    libxsaa_private_la_vala.stamp \
    $(xsplashaa_SOURCES:.vala=.c) \
    xsplashaa_vala.stamp \
    $(xsplashaa_client_SOURCES:.vala=.c) \
    xsplashaa_client_vala.stamp \
    $(xsplashaa_session_daemon_SOURCES:.vala=.c) \
    xsplashaa_session_daemon_vala.stamp
