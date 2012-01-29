if HAVE_LOGON
SUBDIRS = logon
endif

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
    --pkg=config \
    --pkg=os

if HAVE_LOGON
libxsaa_log_la_VALAFLAGS += \
    -D HAVE_LOGON \
    --vapidir=${top_srcdir}/src/log/logon \
    --pkg=logon
endif

libxsaa_log_la_SOURCES = \
    log.vala

if HAVE_LOGON
libxsaa_log_la_LIBADD = \
    logon/liblogon-glue.la
endif

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

