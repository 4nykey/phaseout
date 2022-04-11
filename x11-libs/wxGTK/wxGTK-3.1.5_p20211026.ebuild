# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools multilib-minimal vcs-snapshot virtualx

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="https://wxwidgets.org/"
VIRTUALX_REQUIRED="X test"

MY_PV="204db7e"
[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
MY_CA="catch-ee4acb6"
SRC_URI="
	mirror://githubcl/wxWidgets/wxWidgets/tar.gz/${MY_PV} -> ${P}.tar.gz
	test? (
		mirror://githubcl/wxWidgets/${MY_CA%-*}/tar.gz/${MY_CA##*-}
		-> ${MY_CA}.tar.gz
	)
"
RESTRICT=primaryuri

KEYWORDS="~amd64 ~x86"
IUSE="+X chm curl debug gstreamer libnotify lzma opengl pch sdl test tiff webkit"

SLOT="$(ver_cut 1-2)/$(ver_cut 3)"

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
	lzma? ( app-arch/xz-utils )
	curl? ( net-misc/curl )
"
DEPEND="
	${RDEPEND}
	virtual/pkgconfig
	opengl? ( virtual/glu[${MULTILIB_USEDEP}] )
	X?  ( x11-base/xorg-proto )
"
PDEPEND=">=app-eselect/eselect-wxwidgets-20131230"
LICENSE="wxWinLL-3 GPL-2"
DOCS=(
	docs/{changes,readme}.txt
	docs/{base,gtk}
)

src_prepare() {
	use test && mv "${WORKDIR}"/${MY_CA}/* 3rdparty/catch
	mv -f configure.{in,ac}
	sed -e 's:AC_CONFIG_SUBDIRS(\[.*:no=subdirs:' -i configure.ac
	default
	AT_M4DIR="${S}/build/aclocal" eautoreconf

	# Versionating
	local _s="${SLOT%/*}"
	sed -i \
		-e "s:aclocal):aclocal/wxwin${_s//.}.m4):" \
		-e "/\.\<mo\>/s:wx\(std\|msw\):wx\1${_s//.}:" \
		Makefile.in || die
}

multilib_src_configure() {
	# X independent options
	local myeconfargs=(
		$(use_enable pch)
		$(use_with sdl)
		$(use_with lzma liblzma)
		--with-zlib=sys
		--with-expat=sys
		$(use_with curl libcurl)
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
			$(multilib_native_use_enable test tests)
	)

	# wxBase options
	use X || myeconfargs+=( --disable-gui )

	ECONF_SOURCE="${S}" econf ${myeconfargs[@]}
}

multilib_src_compile() {
	default
	use test && emake -C tests
}

multilib_src_test() {
	local -x LD_LIBRARY_PATH="${BUILD_DIR}/lib:${BUILD_DIR}/tests"
	cd tests
	./test --reporter compact || die "non-GUI tests failed"
	use X && virtx ./test_gui --reporter compact || die "GUI tests failed"
}

multilib_src_install_all() {
	einstalldocs
	# Unversioned links
	rm "${ED}"/usr/bin/wx{-config,rc}

	# version bakefile presets
	pushd "${ED}"/usr/share/bakefile/presets/ > /dev/null
	local f _s="${SLOT%/*}"
	for f in wx*; do
		mv "${f}" "wx${_s//.}${f#wx}"
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
