# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools multilib-minimal vcs-snapshot virtualx

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="https://wxwidgets.org/"
VIRTUALX_REQUIRED="X test"

MY_PV="3b6a9f7"
[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
SRC_URI="
	mirror://githubcl/wxwidgets/wxwidgets/tar.gz/${MY_PV} -> ${P}.tar.gz
"
RESTRICT=primaryuri

KEYWORDS="~amd64 ~x86"
IUSE="+X debug gstreamer libnotify chm opengl pch sdl test tiff webkit"

SLOT="${PV:0:3}-gtk3"

RDEPEND="
	dev-libs/expat[${MULTILIB_USEDEP}]
	sdl? ( media-libs/libsdl2[${MULTILIB_USEDEP}] )
	X? (
		>=dev-libs/glib-2.22:2[${MULTILIB_USEDEP}]
		media-libs/libpng:0=[${MULTILIB_USEDEP}]
		sys-libs/zlib[${MULTILIB_USEDEP}]
		virtual/jpeg:0=[${MULTILIB_USEDEP}]
		x11-libs/cairo[${MULTILIB_USEDEP}]
		x11-libs/gtk+:3[${MULTILIB_USEDEP}]
		x11-libs/gdk-pixbuf[${MULTILIB_USEDEP}]
		x11-libs/libSM[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
		x11-libs/pango[${MULTILIB_USEDEP}]
		gstreamer? (
			media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
			media-libs/gst-plugins-base:1.0[${MULTILIB_USEDEP}]
		)
		libnotify? ( x11-libs/libnotify[${MULTILIB_USEDEP}] )
		opengl? ( virtual/opengl[${MULTILIB_USEDEP}] )
		tiff?   ( media-libs/tiff:0[${MULTILIB_USEDEP}] )
		webkit? ( net-libs/webkit-gtk:4 )
	)
	chm? ( dev-libs/libmspack )
"
DEPEND="
	${RDEPEND}
	virtual/pkgconfig
	opengl? ( virtual/glu[${MULTILIB_USEDEP}] )
	X?  ( x11-base/xorg-proto )
	test? ( dev-util/cppunit )
"
PDEPEND=">=app-eselect/eselect-wxwidgets-20131230"
LICENSE="wxWinLL-3 GPL-2"
DOCS=(
	docs/{changes,readme}.txt
	docs/{base,gtk}
)

src_prepare() {
	mv -f configure.{in,ac}
	sed -e 's:AC_CONFIG_SUBDIRS(\[.*:no=subdirs:' -i configure.ac
	default
	AT_M4DIR="${S}/build/aclocal" eautoreconf

	# Versionating
	sed -i \
		-e "s:\(WX_RELEASE = \).*:\1${SLOT}:" \
		-e "s:\(WX_RELEASE_NODOT = \).*:\1${SLOT//.}:" \
		-e "s:\(WX_VERSION = \).*:\1${PV:0:5}:" \
		-e "s:aclocal):aclocal/wxwin${SLOT//.}.m4):" \
		-e "s:wxstd.mo:wxstd${SLOT//.}:" \
		-e "s:wxmsw.mo:wxmsw${SLOT//.}:" \
		Makefile.in || die

	sed -i \
		-e "s:\(WX_RELEASE = \).*:\1${SLOT}:"\
		utils/wxrc/Makefile.in || die

	sed -i \
		-e "s:\(WX_VERSION=\).*:\1${PV:0:5}:" \
		-e "s:\(WX_RELEASE=\).*:\1${SLOT}:" \
		-e "s:\(WX_SUBVERSION=\).*:\1${PV}-gtk3:" \
		-e "/WX_VERSION_TAG=/ s:\${WX_RELEASE}:${PV:0:3}:" \
		configure || die
}

multilib_src_configure() {
	# X independent options
	local myeconfargs=(
		$(use_enable pch precomp-headers)
		--with-zlib=sys
		--with-expat=sys
		--enable-compat28
		$(use_with sdl)
		--enable-debug=$(usex debug max $(usex test))
	)

	# wxGTK options
	#   --enable-graphics_ctx - needed for webkit, editra
	#   --without-gnomevfs - bug #203389
	use X && myeconfargs+=(
			--enable-graphics_ctx
			--with-gtkprint
			--enable-gui
			--with-gtk=3
			--with-libpng=sys
			--with-libjpeg=sys
			--without-gnomevfs
			$(use_enable gstreamer mediactrl)
			$(multilib_native_use_enable webkit webview)
			$(use_with libnotify)
			$(use_with opengl)
			$(use_with tiff libtiff sys)
			$(use_with chm libmspack)
	)

	# wxBase options
	use X || myeconfargs+=( --disable-gui )

	ECONF_SOURCE="${S}" econf ${myeconfargs[@]}
}

multilib_src_compile() {
	default
	use test && emake -C tests WX_RELEASE="${SLOT}"
}

multilib_src_test() {
	local -x LD_LIBRARY_PATH="${BUILD_DIR}/lib:${BUILD_DIR}/tests"
	cd tests
	./test -t || die "non-GUI tests failed"
	use X && virtx ./test_gui -t || die "GUI tests failed"
}

multilib_src_install_all() {
	einstalldocs
	# Unversioned links
	rm "${ED}"/usr/bin/wx{-config,rc}

	# version bakefile presets
	pushd "${ED}"/usr/share/bakefile/presets/ > /dev/null
	local f
	for f in wx*; do
		mv "${f}" "wx${SLOT//.}${f#wx}"
	done
	popd > /dev/null
}

pkg_postinst() {
	has_version app-eselect/eselect-wxwidgets \
		&& eselect wxwidgets update
}

pkg_postrm() {
	has_version app-eselect/eselect-wxwidgets \
		&& eselect wxwidgets update
}
