SUBDIRS = logon

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-log.la

libxsaa_log_la_CFLAGS = \
    -I${top_srcdir}/src/log/logon

libxsaa_log_la_VALAFLAGS = \
    --thread \
    --header=xsaa-log.h \
    --library=xsaa-log \
    --vapi=xsaa-log.vapi \
    --vapidir=${top_srcdir}/vapi \
    --vapidir=${top_srcdir}/src/log/logon \
    --pkg=config \
    --pkg=os \
    --pkg=logon

libxsaa_log_la_SOURCES = \
    log.vala

libxsaa_log_la_LIBADD = \
    logon/liblogon-glue.la

VALAFILES = \
    $(filter %.vala,$(libxsaa_log_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_log_la_vala.stamp \
    xsaa-log.vapi \
    xsaa-log.h

EXTRA_DIST = \
    xsaa-log.vapi \
    xsaa-log.h

