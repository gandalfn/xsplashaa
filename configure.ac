AC_INIT([xsplashaa], [0.1.0], [nicolas.bruguier@supersonicimagine.fr], [xsplashaa])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

VALA_PROG_VALAC([0.1.3])

AH_TEMPLATE([GETTEXT_PACKAGE], [Package name for gettext])
GETTEXT_PACKAGE=xsplashaa
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.12.0
GTK_REQUIRED=2.10.0

PKG_CHECK_MODULES(XSPLASHAA, [glib-2.0 >= $GLIB_REQUIRED 
                              gobject-2.0 >= $GLIB_REQUIRED 
                              gtk+-2.0 >= $GTK_REQUIRED
                              dbus-glib-1
                              vala-1.0
                              cairo-compmgr])
AC_SUBST(XSPLASHAA_CFLAGS)
AC_SUBST(XSPLASHAA_LIBS)

AC_ARG_WITH(chroot-dir,
            AC_HELP_STRING([--with-chroot-dir=DIR],
                           [Default chroot dir [[default=/dev/.xsplashaa]]]),
            [chrootdir="$withval"],
            [chrootdir="/dev/.xsplashaa"])
AC_SUBST(chrootdir)

AC_ARG_WITH(init-dir,
            AC_HELP_STRING([--with-init-dir=DIR],
                           [Default functions init dir [[default=/lib/init]]]),
            [initdir="$withval"],
            [initdir="/lib/init"])
AC_SUBST(initdir)

AC_CONFIG_FILES([Makefile
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
	data/themes/chicken-curie/Makefile])

AC_OUTPUT
