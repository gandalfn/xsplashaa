SUBDIRS = \
    src \
    po \
    data

xsplashaadocdir = ${prefix}/doc/xsplashaa
xsplashaadoc_DATA = \
    ChangeLog \
    README \
    COPYING \
    AUTHORS \
    INSTALL \
    NEWS

DISTCHECK_CONFIGURE_FLAGS = --with-init-dir='$${prefix}/lib/init' --with-pam-dir='$${prefix}/lib/security' VALAC="/usr/bin/valac-0.12"

EXTRA_DIST = \
    $(xsplashaadoc_DATA) \
    intltool-extract.in \
    intltool-merge.in \
    intltool-update.in \
    vapi/config.vapi \
    vapi/source.vapi \
    vapi/pam.vapi \
    vapi/posix-comp.vapi \
    vapi/X-comp.vapi

DISTCLEANFILES = \
    intltool-extract \
    intltool-merge \
    intltool-update \
    po/.intltool-merge-cache

