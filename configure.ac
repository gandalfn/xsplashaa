AC_INIT([xsplashaa], [0.4.1], [nicolas.bruguier@supersonicimagine.fr], [xsplashaa])
AC_CONFIG_SRCDIR(src/xsaa-main.vala)
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])
AM_MAINTAINER_MODE

dnl ****************************************************************************
dnl Check for build
dnl ****************************************************************************
AC_PROG_CC
AM_PROG_CC_C_O
dnl AC_DISABLE_STATIC

dnl ****************************************************************************
dnl Check for libtool
dnl ****************************************************************************
AM_PROG_LIBTOOL

dnl ****************************************************************************
dnl Packages version required
dnl ****************************************************************************
GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.10.0
VALA_REQUIRED=0.10.0
SSIGTKEXTRAS_REQUIRED=0.5.0

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
PKG_CHECK_MODULES(XSPLASHAA, [glib-2.0 >= $GLIB_REQUIRED 
                              gobject-2.0 >= $GLIB_REQUIRED 
                              gtk+-2.0 >= $GTK_REQUIRED
                              dbus-glib-1
                              vala-0.10 >= $VALA_REQUIRED])

PKG_CHECK_MODULES(XSPLASHAA_SESSION_DAEMON, [glib-2.0 >= $GLIB_REQUIRED,
                                             gobject-2.0 >= $GLIB_REQUIRED
                                             dbus-glib-1
                                             vala-0.10 >= $VALA_REQUIRED
                                             xau])

PKG_CHECK_MODULES(XSPLASHAA_CLIENT, [glib-2.0 >= $GLIB_REQUIRED,
                                     gobject-2.0 >= $GLIB_REQUIRED])

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

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    po/Makefile.in
    data/Makefile
    data/xsplashaa.desktop
    data/dbus/Makefile
    data/dbus/fr.supersonicimagine.XSAA.Manager.service
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
    data/pam/Makefile
    data/jail-mount.d/Makefile
    data/themes/Makefile
    data/themes/aixplorer/Makefile
    data/themes/chicken-curie/Makefile
    data/themes/debian/Makefile
    data/themes/donut-doopler/Makefile])

AC_OUTPUT
