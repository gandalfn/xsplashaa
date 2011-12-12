include $(top_srcdir)/build/common.am

noinst_LTLIBRARIES = libxsaa-face-authentification.la

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

EXTRA_DIST = \
    xsaa-face-authentification.vapi

