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
    --pkg=X-comp \
    --pkg=ssi-timeline \
    --pkg=ssi-vala-widgets

bin_PROGRAMS = xsplashaa xsplashaa-client xsplashaa-session-daemon

xsplashaa_SOURCES = \
	xsaa-server.vala \
	xsaa-display.vala \
	xsaa-throbber.vala \
	xsaa-splash.vala \
    	xsaa-socket.vala \
	xsaa-main.vala
    
xsplashaa_LDADD = \
	$(XSPLASHAA_LIBS)

xsplashaa_client_SOURCES = \
    	xsaa-socket.vala \
	xsaa-client.vala

xsplashaa_client_LDADD = \
	$(XSPLASHAA_LIBS)

xsplashaa_session_daemon_SOURCES = \
    xsaa-pam.vala \
    xsaa-session.vala \
    xsaa-session-daemon.vala

xsplashaa_session_daemon_LDADD = \
	$(XSPLASHAA_LIBS) -lpam

