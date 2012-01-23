XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-netlink.la

libxsaa_netlink_la_VALAFLAGS = \
    --thread \
    --header=xsaa-netlink.h \
    --library=xsaa-netlink \
    --vapi=xsaa-netlink.vapi \
    --pkg=linux

libxsaa_netlink_la_SOURCES = \
    socket.vala \
    message.vala

libxsaa_netlink_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

noinst_PROGRAMS = \
    test-netlink

test_netlink_VALAFLAGS = \
    --thread \
    --pkg=gmodule-2.0 \
    --pkg=linux \
    --vapidir=. \
    --pkg=xsaa-netlink

test_netlink_SOURCES = \
    test-netlink.vala

test_netlink_LDADD = \
    $(XSPLASHAA_LIBS) \
    libxsaa-netlink.la

VALAFILES = \
    $(filter %.vala,$(libxsaa_netlink_la_SOURCES)) \
    $(filter %.vala,$(test_netlink_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_netlink_la_vala.stamp \
    xsaa-netlink.vapi \
    xsaa-netlink.h \
    test_netlink_vala.stamp

EXTRA_DIST = \
    xsaa-netlink.vapi \
    xsaa-netlink.h

.NOTPARALLEL: libxsaa-netlink.la test-netlink

