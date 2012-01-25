include $(top_srcdir)/build/common.am

noinst_LTLIBRARIES = liblogon-glue.la

INCLUDES = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_CFLAGS) \
    $(AM_CPPFLAGS)

liblogon_glue_la_CPPFLAGS = \
    -std=c++0x

liblogon_glue_la_SOURCES = \
    logon-glue.cpp

noinst_HEADERS = \
    logon-glue.h

noinst_DATA = \
    logon.vapi

EXTRA_DIST = \
    logon.vapi

