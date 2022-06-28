# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

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
IUSE="+X chm curl debug egl gstreamer libnotify lzma opengl pch pcre sdl svg threads test tiff webkit"
REQUIRED_USE="
	egl? ( opengl )
"

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
	pcre? ( dev-libs/libpcre2[pcre16,pcre32] )
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
PATCHES=(
	"${FILESDIR}"/96cb1b5.patch
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
		$(use_enable pch)
		$(use_enable threads)
		$(use_with sdl)
		$(use_with pcre regex sys)
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
			$(use_enable svg)
			$(multilib_native_use_enable webkit webview)
			$(use_with libnotify)
			$(use_with opengl)
			$(use_enable egl glcanvasegl)
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
