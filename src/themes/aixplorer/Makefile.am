XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi \
    $(top_builddir)/src/xml/xsaa-xml.vapi \
    $(top_builddir)/src/graphics/xsaa-graphics.vapi \
    $(top_builddir)/src/timeline/xsaa-timeline.vapi \
    $(top_builddir)/src/widgets/xsaa-widgets.vapi \
    $(top_builddir)/src/themes/xsaa-engine.vapi

include $(top_srcdir)/build/vala.am

aixplorerthemedir = $(libdir)/xsplashaa

aixplorertheme_LTLIBRARIES = aixplorer-engine.la

aixplorer_engine_la_VALAFLAGS = \
    --thread \
    --pkg=gmodule-2.0 \
    --pkg=gtk+-2.0 \
    --pkg=goocanvas \
    --pkg=librsvg-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp

aixplorer_engine_la_SOURCES = \
    item.vala \
    item-pack-options.vala \
    image.vala \
    text.vala \
    button.vala \
    check-button.vala \
    widget.vala \
    entry.vala \
    throbber.vala \
    progress-bar.vala \
    table.vala \
    notebook.vala \
    users.vala \
    face-authentification.vala \
    background.vala \
    logo.vala \
    engine.vala

aixplorer_engine_la_LDFLAGS = \
    -module -avoid-version -no-undefined -Wl,-z,muldefs

aixplorer_engine_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS) \
    $(XSPLASHAA_LIBS)

VALAFILES = \
    $(filter %.vala,$(aixplorer_engine_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    aixplorer_engine_la_vala.stamp

