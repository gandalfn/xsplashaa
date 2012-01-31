AC_INIT([xsplashaa], [0.5.2], [nicolas.bruguier@supersonicimagine.fr], [xsplashaa])
AC_CONFIG_SRCDIR(src/splash/main.vala)

AC_CONFIG_AUX_DIR([build])
AC_CONFIG_MACRO_DIR([build])
AC_CONFIG_HEADERS(build/config.h)

AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])
AM_MAINTAINER_MODE

dnl ****************************************************************************
dnl Check for build
dnl ****************************************************************************
AC_LANG([C])
AC_LANG([C++])
AM_PROG_CC_C_O
AC_SEARCH_LIBS([strerror],[cposix])

dnl ****************************************************************************
dnl Check for libtool
dnl ****************************************************************************
LT_PREREQ([2.2])
LT_INIT([disable-static])

dnl ****************************************************************************
dnl Packages version required
dnl ****************************************************************************
GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.10.0
VALA_REQUIRED=0.12.0
SSIGTKEXTRAS_REQUIRED=0.5.0
GOOCANVAS_REQUIRED=0.15
OPENCV_REQUIRED=2.1.0
LOGON_REQUIRED=0.4.70

dnl ****************************************************************************
dnl Check for vala
dnl ****************************************************************************
AM_PROG_VALAC($VALA_REQUIRED)

dnl ****************************************************************************
dnl Internationalization
dnl ****************************************************************************
AH_TEMPLATE([GETTEXT_PACKAGE], [Package name for gettext])
GETTEXT_PACKAGE=xsplashaa
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

dnl ****************************************************************************
dnl Check for packages
dnl ****************************************************************************
PKG_CHECK_MODULES(XSPLASHAA_LOGON, [logon >= $LOGON_REQUIRED], [have_logon=yes], [have_logon=no])
AM_CONDITIONAL([HAVE_LOGON], test "x$have_logon" = "xyes")

PKG_CHECK_MODULES(XSPLASHAA, [x11
                              glib-2.0 >= $GLIB_REQUIRED
                              gthread-2.0 >= $GLIB_REQUIRED
                              gobject-2.0 >= $GLIB_REQUIRED
                              gmodule-2.0 >= $GLIB_REQUIRED
                              gtk+-2.0 >= $GTK_REQUIRED
                              goocanvas >= $GOOCANVAS_REQUIRED
                              librsvg-2.0
                              dbus-glib-1])
if test "x$have_logon" = "xyes"; then
    XSPLASHAA_CFLAGS="$XSPLASHAA_CFLAGS $XSPLASHAA_LOGON_CFLAGS"
    XSPLASHAA_LIBS="$XSPLASHAA_LIBS $XSPLASHAA_LOGON_LIBS"
fi

PKG_CHECK_MODULES(XSPLASHAA_SESSION_DAEMON, [glib-2.0 >= $GLIB_REQUIRED,
                                             gobject-2.0 >= $GLIB_REQUIRED
                                             gthread-2.0 >= $GLIB_REQUIRED
                                             gtk+-2.0 >= $GTK_REQUIRED
                                             dbus-glib-1
                                             xau])
if test "x$have_logon" = "xyes"; then
    XSPLASHAA_SESSION_DAEMON_CFLAGS="$XSPLASHAA_SESSION_DAEMON_CFLAGS $XSPLASHAA_LOGON_CFLAGS"
    XSPLASHAA_SESSION_DAEMON_LIBS="$XSPLASHAA_SESSION_DAEMON_LIBS $XSPLASHAA_LOGON_LIBS"
fi

PKG_CHECK_MODULES(XSPLASHAA_CLIENT, [glib-2.0 >= $GLIB_REQUIRED,
                                     gthread-2.0 >= $GLIB_REQUIRED
                                     gobject-2.0 >= $GLIB_REQUIRED])

if test "x$have_logon" = "xyes"; then
    XSPLASHAA_CLIENT_CFLAGS="$XSPLASHAA_CLIENT_CFLAGS $XSPLASHAA_LOGON_CFLAGS"
    XSPLASHAA_CLIENT_LIBS="$XSPLASHAA_CLIENT_LIBS $XSPLASHAA_LOGON_LIBS"
fi

PKG_CHECK_MODULES(XSPLASHAA_FACE_AUTHENTIFICATION, [opencv2 >= $OPENCV_REQUIRED])

AC_SUBST(XSPLASHAA_CFLAGS)
AC_SUBST(XSPLASHAA_LIBS)

AC_SUBST(XSPLASHAA_SESSION_DAEMON_CFLAGS)
AC_SUBST(XSPLASHAA_SESSION_DAEMON_LIBS)

AC_SUBST(XSPLASHAA_CLIENT_CFLAGS)
AC_SUBST(XSPLASHAA_CLIENT_LIBS)

dnl ****************************************************************************
dnl Check for chroot-dir
dnl ****************************************************************************
AC_ARG_WITH(chroot-dir,
            AC_HELP_STRING([--with-chroot-dir=DIR],
                           [Default chroot dir [[default=/dev/.xsplashaa]]]),
            [chrootdir="$withval"],
            [chrootdir="/dev/.xsplashaa"])
AC_SUBST(chrootdir)

dnl ****************************************************************************
dnl Check for init-dir
dnl ****************************************************************************
AC_ARG_WITH(init-dir,
            AC_HELP_STRING([--with-init-dir=DIR],
                           [Default functions init dir [[default=/lib/init]]]),
            [initdir="$withval"],
            [initdir="/lib/init"])
AC_SUBST(initdir)

dnl ****************************************************************************
dnl Check for engine-dir
dnl ****************************************************************************
AC_ARG_WITH(engine-dir,
            AC_HELP_STRING([--with-engine-dir=DIR],
                           [Default engine dir [[default=${libdir}/xsplashaa]]]),
            [enginedir="$withval"],
            [enginedir="${libdir}/xsplashaa"])
AC_SUBST(enginedir)

dnl ****************************************************************************
dnl Check for pam-dir
dnl ****************************************************************************
AC_CHECK_HEADER([security/pam_modules.h],, [AC_MSG_ERROR([*** Sorry, you have to install the PAM development files ***])])
AC_ARG_WITH(pam-dir,
            AC_HELP_STRING([--with-pam-dir=DIR],
                           [Default engine dir [[default=/lib/security]]]),
            [pamdir="$withval"],
            [pamdir="/lib/security"])
AC_SUBST(pamdir)

dnl ****************************************************************************
dnl Define directory
dnl ****************************************************************************
idbusdir=${datadir}/xsplashaa/dbus
faceauthdatadir=${datadir}/xsplashaa/face-authentification
iconsdir=${datadir}/xsplashaa/icons
logondir=${datadir}/xsplashaa/logon
AC_SUBST(idbusdir)
AC_SUBST(faceauthdatadir)
AC_SUBST(iconsdir)
AC_SUBST(logondir)

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/log/Makefile
    src/log/logon/Makefile
    src/socket/Makefile
    src/netlink/Makefile
    src/input/Makefile
    src/xml/Makefile
    src/client/Makefile
    src/graphics/Makefile
    src/session-daemon/Makefile
    src/timeline/Makefile
    src/splash/Makefile
    src/engine/Makefile
    src/engine/aixplorer/Makefile
    src/face-authentification/Makefile
    src/face-authentification/common/Makefile
    src/face-authentification/common/cpp/Makefile
    src/face-authentification/pam/Makefile
    po/Makefile.in
    data/Makefile
    data/xsplashaa.desktop
    data/icons/Makefile
    data/dbus/Makefile
    data/dbus/fr.supersonicimagine.XSAA.Manager.service
    data/face-authentification/Makefile
    data/init/Makefile
    data/init/splash-functions
    data/init/xsplashaa-functions
    data/init/xsplashaa
    data/init/xsplashaa-phase2
    data/init/xsplashaa-phase3
    data/initramfs/Makefile
    data/initramfs/hooks/Makefile
    data/initramfs/hooks/xsplashaa
    data/initramfs/modules/Makefile
    data/initramfs/scripts/Makefile
    data/initramfs/scripts/xsplashaa
    data/initramfs/scripts/functions
    data/logon/Makefile
    data/pam/Makefile
    data/jail-mount.d/Makefile
    data/themes/Makefile
    data/themes/aixplorer/Makefile
    data/themes/chicken-curie/Makefile
    data/themes/debian/Makefile
    data/themes/donut-doppler/Makefile
    data/themes/leaves/Makefile])

AC_OUTPUT

