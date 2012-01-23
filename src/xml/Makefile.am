XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = libxsaa-xml.la

libxsaa_xml_la_VALAFLAGS = \
    --thread \
    --header=xsaa-xml.h \
    --library=xsaa-xml \
    --vapi=xsaa-xml.vapi \
    --pkg=gobject-2.0

libxsaa_xml_la_SOURCES = \
    value.vala \
    parser.vala \
    xml-parser.vala

libxsaa_xml_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_xml_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_xml_la_vala.stamp \
    xsaa-xml.vapi \
    xsaa-xml.h

EXTRA_DIST = \
    xsaa-xml.vapi \
    xsaa-xml.h

