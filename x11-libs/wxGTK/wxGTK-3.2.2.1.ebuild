# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools multilib-minimal virtualx

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="https://wxwidgets.org/"
VIRTUALX_REQUIRED="X test"

MY_PN="wxWidgets"
MY_PV="204db7e"
[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
MY_CA="Catch-5f5e4ce"
MY_NS="nanosvg-ccdb199"
SRC_URI="
	mirror://githubcl/${MY_PN}/${MY_PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	mirror://githubcl/${MY_PN}/${MY_NS%-*}/tar.gz/${MY_NS##*-}
	-> ${MY_NS}.tar.gz
	test? (
		mirror://githubcl/${MY_PN}/${MY_CA%-*}/tar.gz/${MY_CA##*-}
		-> ${MY_CA}.tar.gz
	)
"
S="${WORKDIR}/${MY_PN}-${MY_PV#v}"
RESTRICT=primaryuri

KEYWORDS="~amd64 ~x86"
IUSE="+X curl doc debug gnome-keyring gstreamer libnotify +lzma opengl pch sdl +spell test tiff wayland webkit"
IUSE+=" chm egl pcre svg threads"
REQUIRED_USE="
	egl? ( opengl )
	test? ( tiff )
	tiff? ( X )
	spell? ( X )
	gnome-keyring? ( X )
"

SLOT="$(ver_cut 1-2)"

RDEPEND="
	app-eselect/eselect-wxwidgets
	dev-libs/expat[${MULTILIB_USEDEP}]
	pcre? ( dev-libs/libpcre2[pcre16,pcre32,unicode] )
	sdl? ( media-libs/libsdl2[${MULTILIB_USEDEP}] )
	curl? ( net-misc/curl )
	lzma? ( app-arch/xz-utils )
	X? (
		>=dev-libs/glib-2.22:2[${MULTILIB_USEDEP}]
		media-libs/libjpeg-turbo:=[${MULTILIB_USEDEP}]
		media-libs/libpng:0=[${MULTILIB_USEDEP}]
		sys-libs/zlib[${MULTILIB_USEDEP}]
		x11-libs/cairo[${MULTILIB_USEDEP}]
		x11-libs/gtk+:3[wayland?,${MULTILIB_USEDEP}]
		x11-libs/gdk-pixbuf:2[${MULTILIB_USEDEP}]
		x11-libs/libSM[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXtst
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
		media-libs/fontconfig
		x11-libs/pango[${MULTILIB_USEDEP}]
		gnome-keyring? ( app-crypt/libsecret )
		gstreamer? (
			media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
			media-libs/gst-plugins-base:1.0[${MULTILIB_USEDEP}]
			media-libs/gst-plugins-bad:1.0[${MULTILIB_USEDEP}]
		)
		libnotify? ( x11-libs/libnotify[${MULTILIB_USEDEP}] )
		opengl? (
			virtual/opengl[${MULTILIB_USEDEP}]
			wayland? ( dev-libs/wayland )
		)
		spell? ( app-text/gspell:= )
		tiff? ( media-libs/tiff:=[${MULTILIB_USEDEP}] )
		webkit? ( net-libs/webkit-gtk:4 )
	)
	chm? ( dev-libs/libmspack )
"
DEPEND="
	${RDEPEND}
	opengl? ( virtual/glu[${MULTILIB_USEDEP}] )
	X?  ( x11-base/xorg-proto )
"
BDEPEND="
	test? ( dev-util/cppunit )
	app-eselect/eselect-wxwidgets
	virtual/pkgconfig
"
LICENSE="wxWinLL-3 GPL-2"
DOCS=(
	docs/{changes,readme}.txt
	docs/{base,gtk}
)
PATCHES=(
)

src_prepare() {
	mv "${WORKDIR}"/${MY_NS}/* 3rdparty/nanosvg
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
		--with-zlib=sys
		--with-expat=sys
		$(use_enable pch)
		$(use_enable threads)
		$(use_with sdl)
		$(use_with pcre regex sys)
		$(use_with lzma liblzma)
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
		$(use_enable gnome-keyring secretstore)
		$(use_enable spell spellcheck)
		$(multilib_native_use_enable test tests)
		$(use_enable svg)
		$(use_enable egl glcanvasegl)
		$(use_with chm libmspack)
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
	rm -f "${ED}"/usr/bin/wx{-config,rc}

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
