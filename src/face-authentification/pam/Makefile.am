XSPLASHAA_VAPI_DEPS = \
    $(top_srcdir)/src/face-authentification/common/cpp/xsaa-face-authentification.vapi

include $(top_srcdir)/build/vala.am

pam_LTLIBRARIES = pam-xsplashaa-face-authentification.la

pam_xsplashaa_face_authentification_la_CFLAGS = \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_CFLAGS)

pam_xsplashaa_face_authentification_la_VALAFLAGS = \
    --pkg=gobject-2.0 \
    --pkg=pam \
    --pkg=opencv \
    --pkg=posix

pam_xsplashaa_face_authentification_la_SOURCES = \
    pam-module.c \
    pam-face-authentification.vala

pam_xsplashaa_face_authentification_la_LDFLAGS = \
    -module -avoid-version

pam_xsplashaa_face_authentification_la_LIBADD = \
    $(XSPLASHAA_LIBS_DEPS) \
    $(XSPLASHAA_FACE_AUTHENTIFICATION_LIBS)

VALAFILES = \
    $(filter %.vala,$(pam_xsplashaa_face_authentification_la_SOURCES))

CLEANFILES = \
    $(VALAFILES:.vala=.c) \
    pam_xsplashaa_face_authentification_la_vala.stamp

