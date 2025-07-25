# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="https://wxwidgets.org/"
VIRTUALX_REQUIRED="X"
inherit cmake-multilib virtualx

MY_PN="wxWidgets"
MY_PV="204db7e"
[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
MY_CA="Catch-5f5e4ce"
SRC_URI="
	mirror://githubcl/${MY_PN}/${MY_PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	test? (
		mirror://githubcl/${MY_PN}/${MY_CA%-*}/tar.gz/${MY_CA##*-}
		-> ${MY_CA}.tar.gz
	)
"
S="${WORKDIR}/${MY_PN}-${MY_PV#v}"

LICENSE="wxWinLL-3 GPL-2"
SLOT="$(ver_cut 1-2)/$(ver_cut 3)"
KEYWORDS="~amd64 ~x86"
IUSE="+X curl doc debug keyring gstreamer libnotify +lzma opengl pch sdl +spell test tiff wayland webkit"
IUSE+=" chm egl pcre svg threads"
REQUIRED_USE="
	egl? ( opengl )
	test? ( tiff )
	tiff? ( X )
	spell? ( X )
	keyring? ( X )
"
RESTRICT="!test? ( test )"

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
		keyring? ( app-crypt/libsecret )
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
		webkit? ( net-libs/webkit-gtk:4.1= )
	)
	chm? ( dev-libs/libmspack )
	svg? ( media-libs/nanosvg )
"
DEPEND="
	${RDEPEND}
	opengl? ( virtual/glu[${MULTILIB_USEDEP}] )
	X? ( x11-base/xorg-proto )
"
BDEPEND="
	test? ( dev-util/cppunit )
	app-eselect/eselect-wxwidgets
	virtual/pkgconfig
"
DOCS=(
	docs/{changes,readme}.txt
	docs/{base,gtk}
)
PATCHES=(
	"${FILESDIR}"/libdir.diff
)

src_prepare() {
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
		-DwxBUILD_TOOLKIT=gtk3
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
		-DwxUSE_SECRETSTORE=$(usex keyring)
		-DwxUSE_SPELLCHECK=$(usex spell)
		-DwxUSE_NANOSVG=$(usex svg sys no)
		-DwxUSE_GLCANVAS_EGL=$(usex egl)
		-DwxUSE_LIBMSPACK=$(usex chm)
		-DwxUSE_DETECT_SM=yes
	)

	multilib_is_native_abi && use test && mycmakeargs+=(
		-DwxBUILD_TESTS=$(usex X ALL CONSOLE_ONLY)
	)

	cmake-multilib_src_configure
}

src_test() {
	if use X; then
		virtx cmake-multilib_src_test
	else
		cmake-multilib_src_test
	fi
}

src_install() {
	cmake-multilib_src_install
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
