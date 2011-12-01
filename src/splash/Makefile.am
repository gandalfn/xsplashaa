XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi \
    $(top_builddir)/src/socket/xsaa-socket.vapi \
    $(top_builddir)/src/graphics/xsaa-graphics.vapi \
    $(top_builddir)/src/timeline/xsaa-timeline.vapi \
    $(top_builddir)/src/widgets/xsaa-widgets.vapi

include $(top_srcdir)/build/vala.am

bin_PROGRAMS = xsplashaa

xsplashaa_SOURCES = \
    display.vala \
    splash.vala \
    main.vala

xsplashaa_VALAFLAGS = \
    --thread \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

xsplashaa_LDADD = \
    $(XSPLASHAA_LIBS) \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(xsplashaa_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_vala.stamp

