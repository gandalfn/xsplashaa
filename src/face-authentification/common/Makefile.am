XSPLASHAA_VAPI_DEPS = \
    $(top_builddir)/src/log/xsaa-log.vapi

include $(top_srcdir)/build/vala.am

noinst_LTLIBRARIES = \
    libxsaa-face-authentification.la \
    libxsaa-face-authentification-vala.la

libxsaa_face_authentification_la_CPPFLAGS = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_CFLAGS) \
    $(AM_CPPFLAGS)

libxsaa_face_authentification_la_SOURCES = \
    detector.cpp \
    detector.h \
    eyesDetector.cpp \
    eyesDetector.h \
    faceDetector.cpp \
    faceDetector.h \
    opencvWebcam.cpp \
    opencvWebcam.h \
    tracker.cpp \
    tracker.h \
    utils.cpp \
    utils.h \
    verifier.cpp \
    verifier.h \
    webcamImagePaint.cpp \
    webcamImagePaint.h \
    face-authentification.cpp \
    face-authentification.h

libxsaa_face_authentification_la_LIBADD = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_LIBS)

libxsaa_face_authentification_vala_la_CFLAGS = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_CFLAGS)

libxsaa_face_authentification_vala_la_VALAFLAGS = \
    --pkg=gobject-2.0 \
    --pkg=pam \
    --pkg=opencv \
    --pkg=posix

libxsaa_face_authentification_vala_la_SOURCES = \
    defines.vala \
    utils.vala \
    webcam.vala \
    tracker.vala \
    eyes-detector.vala \
    face-detector.vala \
    verifier.vala

libxsaa_face_authentification_vala_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS)

VALAFILES = \
    $(filter %.vala,$(libxsaa_face_authentification_vala_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    libxsaa_face_authentification_vala_la_vala.stamp

EXTRA_DIST = \
    xsaa-face-authentification.vapi

