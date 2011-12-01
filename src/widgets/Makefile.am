INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

noinst_LTLIBRARIES = libxsaa-widgets.la

libxsaa_widgets_la_VALAFLAGS = \
    --thread \
    --header=widgets.h \
    --library=xsaa-widgets \
    --vapi=xsaa-widgets.vapi \
    --vapidir=${top_srcdir}/vapi \
    --vapidir=$(top_builddir)/src/log \
    --vapidir=$(top_builddir)/src/graphics \
    --vapidir=$(top_builddir)/src/timeline \
    --pkg=config \
    --pkg=source \
    --pkg=gtk+-2.0 \
    --pkg=dbus-glib-1 \
    --pkg=os \
    --pkg=pam \
    --pkg=x11 \
    --pkg=X-comp \
    --pkg=xsaa-log \
    --pkg=xsaa-graphics \
    --pkg=xsaa-timeline

libxsaa_widgets_la_CFLAGS = \
    -I${top_builddir}/src/timeline

libxsaa_widgets_la_SOURCES = \
    slide-notebook.vala \
    throbber.vala

VALAFILES = \
    $(filter %.vala,$(libxsaa_widgets_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_widgets_la_vala.stamp \
    xsaa-widgets.vapi \
    widgets.h

