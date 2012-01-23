SUBDIRS = cpp

XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = \
    libxsaa-face-authentification.la

libxsaa_face_authentification_la_CFLAGS = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_CFLAGS)

libxsaa_face_authentification_la_VALAFLAGS = \
    --header=xsaa-face-authentification.h \
    --library=xsaa-face-authentification \
    --vapi=xsaa-face-authentification.vapi \
    --pkg=gobject-2.0 \
    --pkg=pam \
    --pkg=opencv \
    --pkg=posix

libxsaa_face_authentification_la_SOURCES = \
    defines.vala \
    utils.vala \
    webcam.vala \
    tracker.vala \
    eyes-detector.vala \
    face-detector.vala \
    detector.vala \
    verifier.vala

libxsaa_face_authentification_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_face_authentification_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_face_authentification_la.stamp \
    xsaa-face-authentification.vapi \
    xsaa-face-authentification.h

EXTRA_DIST = \
    xsaa-face-authentification.vapi \
    xsaa-face-authentification.h

