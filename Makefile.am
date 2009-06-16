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

DISTCHECK_CONFIGURE_FLAGS = --with-init-dir='$${prefix}/lib/init'

EXTRA_DIST = \
	$(xsplashaadoc_DATA) \
	intltool-extract.in \
	intltool-merge.in \
	intltool-update.in \
	vapi/config.vapi \
	vapi/pam.vapi \
	vapi/posix-comp.vapi \
	vapi/X-comp.vapi

DISTCLEANFILES = \
	intltool-extract \
	intltool-merge \
	intltool-update
	po/.intltool-merge-cache

