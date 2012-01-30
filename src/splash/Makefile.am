XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi \
    $(top_srcdir)/src/xml/xsaa-xml.vapi \
    $(top_srcdir)/src/input/xsaa-input.vapi \
    $(top_srcdir)/src/socket/xsaa-socket.vapi \
    $(top_srcdir)/src/graphics/xsaa-graphics.vapi \
    $(top_srcdir)/src/timeline/xsaa-timeline.vapi \
    $(top_srcdir)/src/engine/xsaa-engine.vapi

include $(top_srcdir)/build/vala.am

bin_PROGRAMS = xsplashaa

xsplashaa_SOURCES = \
    imanager.vala \
    isession.vala \
    iuser.vala \
    iservice.vala \
    ipanel.vala \
    issidab.vala \
    itouchscreen.vala \
    state-machine.vala \
    state-check-peripherals.vala \
    state-service-check.vala \
    state-check-touchscreen.vala \
    state-configure-touchscreen.vala \
    state-calibrate-touchscreen.vala \
    state-check-panel.vala \
    state-check-panel-firmware.vala \
    state-configure-panel.vala \
    state-check-ssidab.vala \
    display.vala \
    devices.vala \
    splash.vala \
    main.vala

xsplashaa_VALAFLAGS = \
    --thread \
    --pkg=source \
    --pkg=gdk-x11-2.0 \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

if HAVE_LOGON
xsplashaa_VALAFLAGS += \
    -D HAVE_LOGON
endif

xsplashaa_LDADD = \
    $(XSPLASHAA_LIBS) \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(xsplashaa_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    xsplashaa_vala.stamp

