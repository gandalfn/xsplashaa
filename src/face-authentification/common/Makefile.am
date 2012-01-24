SUBDIRS = cpp

XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/log/xsaa-log.vapi \
    $(top_srcdir)/src/timeline/xsaa-timeline.vapi \
    $(top_srcdir)/src/graphics/xsaa-graphics.vapi

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
    --pkg=gtk+-2.0 \
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

noinst_PROGRAMS = \
    test-face-authentification

test_face_authentification_CFLAGS = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_CFLAGS)

test_face_authentification_VALAFLAGS = \
    --pkg=gobject-2.0 \
    --pkg=gtk+-2.0 \
    --pkg=pam \
    --pkg=opencv \
    --pkg=posix \
    --pkg=opencv \
    --vapidir=. \
    --pkg=xsaa-face-authentification

test_face_authentification_SOURCES = \
    test-face-authentification.vala

test_face_authentification_LDADD = \
    $(XSPLASHAA_LIBS) \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_LIBS) \
    libxsaa-face-authentification.la

VALAFILES = \
    $(filter %.vala,$(libxsaa_face_authentification_la_SOURCES)) \
    $(filter %.vala,$(test_face_authentification_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_face_authentification_la.stamp \
    xsaa-face-authentification.vapi \
    xsaa-face-authentification.h

EXTRA_DIST = \
    xsaa-face-authentification.vapi \
    xsaa-face-authentification.h

