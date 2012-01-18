XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi \
    $(top_builddir)/src/xml/xsaa-xml.vapi \
    $(top_builddir)/src/input/xsaa-input.vapi \
    $(top_builddir)/src/socket/xsaa-socket.vapi \
    $(top_builddir)/src/graphics/xsaa-graphics.vapi \
    $(top_builddir)/src/timeline/xsaa-timeline.vapi \
    $(top_builddir)/src/engine/xsaa-engine.vapi

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
    state-check-ssidab.vala \
    display.vala \
    devices.vala \
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

