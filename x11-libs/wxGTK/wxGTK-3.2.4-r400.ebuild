# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake virtualx

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="https://wxwidgets.org/"
VIRTUALX_REQUIRED="X test"

MY_PN="wxWidgets"
MY_PV="204db7e"
[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV/_rc/-rc}"
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

KEYWORDS= #"~amd64"
IUSE="+X curl doc debug gnome-keyring gstreamer libnotify +lzma opengl pch sdl +spell test tiff wayland webkit"
IUSE+=" chm egl pcre svg threads"
REQUIRED_USE="
	egl? ( opengl )
	test? ( tiff )
	tiff? ( X )
	spell? ( X )
	gnome-keyring? ( X )
"

SLOT="$(ver_cut 1-2)-gtk4/$(ver_cut 3)"

RDEPEND="
	app-eselect/eselect-wxwidgets
	dev-libs/expat
	pcre? ( dev-libs/libpcre2[pcre16,pcre32,unicode] )
	sdl? ( media-libs/libsdl2 )
	curl? ( net-misc/curl )
	lzma? ( app-arch/xz-utils )
	X? (
		>=dev-libs/glib-2.22:2
		media-libs/libjpeg-turbo:=
		media-libs/libpng:0=
		sys-libs/zlib
		x11-libs/cairo
		gui-libs/gtk:4[wayland?]
		x11-libs/gdk-pixbuf:2
		x11-libs/libSM
		x11-libs/libX11
		x11-libs/libXtst
		x11-libs/libXxf86vm
		media-libs/fontconfig
		x11-libs/pango
		gnome-keyring? ( app-crypt/libsecret )
		gstreamer? (
			media-libs/gstreamer:1.0
			media-libs/gst-plugins-base:1.0
			media-libs/gst-plugins-bad:1.0
		)
		libnotify? ( x11-libs/libnotify )
		opengl? (
			virtual/opengl
			wayland? ( dev-libs/wayland )
		)
		spell? ( app-text/gspell:= )
		tiff? ( media-libs/tiff:= )
		webkit? ( net-libs/webkit-gtk:4 )
	)
	chm? ( dev-libs/libmspack )
"
DEPEND="
	${RDEPEND}
	opengl? ( virtual/glu )
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
	"${FILESDIR}"/libdir.diff
)

src_prepare() {
	mv "${WORKDIR}"/${MY_NS}/* 3rdparty/nanosvg
	use test && mv "${WORKDIR}"/${MY_CA}/* 3rdparty/catch
	cmake_src_prepare
}

src_configure() {
	# X independent options
	local mycmakeargs=(
		-DwxUSE_GUI=$(usex X)
		-DwxUSE_ZLIB=sys
		-DwxUSE_EXPAT=sys
		-DwxUSE_THREADS=$(usex threads)
		-DwxUSE_LIBSDL=$(usex sdl)
		-DwxUSE_REGEX=$(usex pcre sys no)
		-DwxUSE_LIBLZMA=$(usex lzma)
		-DwxUSE_WEBREQUEST_CURL=$(usex curl)
		-DwxBUILD_DEBUG_LEVEL=$(usex debug 2 1)
	)

	# wxGTK options
	#   --enable-graphics_ctx - needed for webkit, editra
	#   --without-gnomevfs - bug #203389
	use X && mycmakeargs+=(
		-DwxBUILD_TOOLKIT=gtk4
		-DwxUSE_GRAPHICS_CONTEXT=yes
		-DwxUSE_GTKPRINT=sys
		-DwxUSE_LIBPNG=sys
		-DwxUSE_LIBJPEG=sys
		-DwxUSE_LIBGNOMEVFS=no
		-DwxUSE_MEDIACTRL=$(usex gstreamer)
		-DwxUSE_WEBVIEW=$(multilib_native_usex webkit)
		-DwxUSE_LIBNOTIFY=$(usex libnotify)
		-DwxUSE_OPENGL=$(usex opengl)
		-DwxUSE_LIBTIFF=$(usex tiff sys no)
		-DwxUSE_SECRETSTORE=$(usex gnome-keyring)
		-DwxUSE_SPELLCHECK=$(usex spell)
		-DwxUSE_NANOSVG=$(usex svg sys no)
		-DwxUSE_GLCANVAS_EGL=$(usex egl)
		-DwxUSE_LIBMSPACK=$(usex chm)
		-DwxUSE_DETECT_SM=yes
	)

	multilib_is_native_abi && use test && mycmakeargs+=(
		-DwxBUILD_TESTS=$(usex X ALL CONSOLE_ONLY)
	)

	cmake_src_configure
}

src_test() {
	local -x LD_LIBRARY_PATH="${BUILD_DIR}/lib:${BUILD_DIR}/tests"
	cd tests
	./test --reporter compact || die "non-GUI tests failed"
	use X && virtx ./test_gui --reporter compact || die "GUI tests failed"
}

src_install() {
	cmake_src_install
	# Unversioned links
	rm -f "${ED}"/usr/bin/wx{-config,rc}
}

pkg_postinst() {
	has_version -b app-eselect/eselect-wxwidgets \
		&& eselect wxwidgets update
}

pkg_postrm() {
	has_version -b app-eselect/eselect-wxwidgets \
		&& eselect wxwidgets update
}
