INCLUDES = \
    $(XSPLASHAA_CFLAGS) \
    --include $(CONFIG_HEADER) \
    -DPACKAGE_CONFIG_FILE=\""$(sysconfdir)/xsplashaa/xsplashaa.conf"\" \
    -DPACKAGE_DATA_DIR=\""$(datadir)/xsplashaa"\" \
    -D_GNU_SOURCE

noinst_LTLIBRARIES = libxsaa-log.la

libxsaa_log_la_VALAFLAGS = \
    --thread \
    --header=log.h \
    --library=xsaa-log \
    --vapi=xsaa-log.vapi \
    --vapidir=${top_srcdir}/vapi \
    --pkg=config \
    --pkg=os

libxsaa_log_la_SOURCES = \
    log.vala

VALAFILES = \
    $(filter %.vala,$(libxsaa_log_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_log_la_vala.stamp \
    xsaa-log.vapi \
    log.h

