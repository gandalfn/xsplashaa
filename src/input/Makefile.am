XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-input.la

libxsaa_input_la_VALAFLAGS = \
    --thread \
    --header=xsaa-input.h \
    --library=xsaa-input \
    --vapi=xsaa-input.vapi \
    --pkg=linux

libxsaa_input_la_SOURCES = \
    event-file.vala \
    event.vala

libxsaa_input_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

noinst_PROGRAMS = \
    test-input

test_input_VALAFLAGS = \
    --thread \
    --pkg=gmodule-2.0 \
    --pkg=linux \
    --vapidir=. \
    --pkg=xsaa-input

test_input_SOURCES = \
    test-input.vala

test_input_LDADD = \
    $(XSPLASHAA_LIBS) \
    libxsaa-input.la

VALAFILES = \
    $(filter %.vala,$(libxsaa_input_la_SOURCES)) \
    $(filter %.vala,$(test_input_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_input_la_vala.stamp \
    xsaa-input.vapi \
    xsaa-input.h \
    test_input_vala.stamp

.NOTPARALLEL: libxsaa-input.la test-input

