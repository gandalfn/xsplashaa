AM_CPPFLAGS = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\"
    
VALA_CFLAGS = \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=vala-1.0 \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=posix \
    --pkg=posix-comp \
    --pkg=pam \
    --pkg=X-comp \
    --pkg=cairo-compmgr \
    -C

bin_PROGRAMS = xsplashaa xsplashaa-client xsplashaa-session-daemon

noinst_PROGRAMS = test-slide-notebook

xsplashaa_VALASOURCES = \
    xsaa-slide-notebook.vala \
	xsaa-socket.vala \
	xsaa-server.vala \
	xsaa-display.vala \
	xsaa-throbber.vala \
	xsaa-splash.vala \
	xsaa-main.vala
    
xsplashaa_SOURCES = \
    $(xsplashaa_VALASOURCES:.vala=.c)

xsplashaa.vala.stamp: $(xsplashaa_VALASOURCES)
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@

xsplashaa_LDADD = \
	$(XSPLASHAA_LIBS)

xsplashaa_client_VALASOURCES = \
    xsaa-socket.vala \
	xsaa-client.vala

xsplashaa_client_SOURCES = \
    $(xsplashaa_client_VALASOURCES:.vala=.c)

xsplashaa-client.vala.stamp: $(xsplashaa_client_VALASOURCES)
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@

xsplashaa_client_LDADD = \
	$(XSPLASHAA_LIBS)

xsplashaa_session_daemon_VALASOURCES = \
    xsaa-pam.vala \
    xsaa-session.vala \
    xsaa-session-daemon.vala

xsplashaa_session_daemon_SOURCES = \
    $(xsplashaa_session_daemon_VALASOURCES:.vala=.c)

xsplashaa-session-daemon.vala.stamp: $(xsplashaa_session_daemon_VALASOURCES)
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@

xsplashaa_session_daemon_LDADD = \
	$(XSPLASHAA_LIBS) -lpam

test_slide_notebook_VALASOURCES = \
    xsaa-slide-notebook.vala \
	test-slide-notebook.vala
    
test_slide_notebook_SOURCES = \
    $(test_slide_notebook_VALASOURCES:.vala=.c)

test-slide-notebook.vala.stamp: $(test_slide_notebook_VALASOURCES)
	$(VALAC) -C $(VALA_CFLAGS) $^
	touch $@

test_slide_notebook_LDADD = \
	$(XSPLASHAA_LIBS)

BUILT_SOURCES = \
    xsplashaa.vala.stamp \
    xsplashaa-client.vala.stamp \
    xsplashaa-session-daemon.vala.stamp \
    test-slide-notebook.vala.stamp

EXTRA_DIST = \
	$(xsplashaa_VALASOURCES) \
	$(xsplashaa_client_VALASOURCES) \
	$(xsplashaa_session_daemon_VALASOURCES) \
	$(test_slide_notebook_VALASOURCES)

CLEANFILES = $(BUILT_SOURCES)

DISTCLEANFILES = \
    $(xsplashaa_SOURCES) \
    $(xsplashaa_client_SOURCES) \
    $(xsplashaa_session_daemon_SOURCES) \
    $(test_slide_notebook_SOURCES)
    