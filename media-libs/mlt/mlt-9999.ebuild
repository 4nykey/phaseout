# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
RESTRICT="test"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/mltframework/${PN}.git"
else
	MY_PV="817e4d8"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/mltframework/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	KEYWORDS="~amd64 ~x86"
	RESTRICT+=" primaryuri"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

LUA_COMPAT=( lua5-{1..4} luajit )
PYTHON_COMPAT=( python3_{7..9} )
inherit lua python-single-r1 cmake toolchain-funcs

DESCRIPTION="Open source multimedia framework for television broadcasting"
HOMEPAGE="https://www.mltframework.org/"

LICENSE="GPL-3"
SLOT="7"
IUSE="cpu_flags_x86_mmx cpu_flags_x86_sse cpu_flags_x86_sse2 debug
ffmpeg fftw frei0r gtk jack kernel_linux libsamplerate lua opencv opengl python
qt5 rtaudio rubberband sdl vdpau vidstab xine xml"
IUSE+=" doc sdl1 sox test"
# java perl php tcl

REQUIRED_USE="lua? ( ${LUA_REQUIRED_USE} )
	python? ( ${PYTHON_REQUIRED_USE} )"
REQUIRED_USE+="
	test? ( qt5 )
"

SWIG_DEPEND=">=dev-lang/swig-2.0"
#	java? ( ${SWIG_DEPEND} >=virtual/jdk-1.5 )
#	perl? ( ${SWIG_DEPEND} )
#	php? ( ${SWIG_DEPEND} )
#	tcl? ( ${SWIG_DEPEND} )
#	ruby? ( ${SWIG_DEPEND} )
BDEPEND="
	virtual/pkgconfig
	lua? ( ${SWIG_DEPEND} virtual/pkgconfig )
	python? ( ${SWIG_DEPEND} )
"
#rtaudio will use OSS on non linux OSes
DEPEND="
	>=media-libs/libebur128-1.2.2:=
	ffmpeg? ( media-video/ffmpeg:0=[vdpau?,-flite] )
	fftw? ( sci-libs/fftw:3.0= )
	frei0r? ( media-plugins/frei0r-plugins )
	gtk? (
		media-libs/libexif
		x11-libs/pango
	)
	jack? (
		>=dev-libs/libxml2-2.5
		media-libs/ladspa-sdk
		virtual/jack
	)
	libsamplerate? ( >=media-libs/libsamplerate-0.1.2 )
	lua? ( ${LUA_DEPS} )
	opencv? ( >=media-libs/opencv-3.2.0:= )
	opengl? ( media-video/movit )
	python? ( ${PYTHON_DEPS} )
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtsvg:5
		dev-qt/qtwidgets:5
		dev-qt/qtxml:5
		media-libs/libexif
		x11-libs/libX11
	)
	rtaudio? (
		>=media-libs/rtaudio-4.1.2
		kernel_linux? ( media-libs/alsa-lib )
	)
	rubberband? ( media-libs/rubberband )
	sdl? (
		media-libs/libsdl2[X,opengl,video]
		media-libs/sdl2-image
	)
	vidstab? ( media-libs/vidstab )
	xine? ( >=media-libs/xine-lib-1.1.2_pre20060328-r7 )
	xml? ( >=dev-libs/libxml2-2.5 )
	sdl1? (
		media-libs/libsdl[X,opengl=,video]
		media-libs/sdl-image
	)
	sox? ( media-sound/sox )
"
#	java? ( >=virtual/jre-1.5 )
#	perl? ( dev-lang/perl )
#	php? ( dev-lang/php )
#	ruby? ( ${RUBY_DEPS} )
#	tcl? ( dev-lang/tcl:0= )
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}"/${PN}-6.10.0-swig-underlinking.patch
	"${FILESDIR}"/${PN}-6.22.1-no_lua_bdepend.patch
	"${FILESDIR}"/mlt7-no_symlinks.diff
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	cmake_src_prepare

	# respect CFLAGS LDFLAGS when building shared libraries. Bug #308873
	for x in python lua; do
		sed -i "/mlt.so/s/ -lmlt++ /& ${CFLAGS} ${LDFLAGS} /" src/swig/$x/build || die
	done

	use python && python_fix_shebang src/swig/python
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_SKIP_BUILD_RPATH=yes
		-DGPL=yes
		-DGPL3=yes
		-DBUILD_TESTING=$(usex test)
		-DBUILD_DOCS=$(usex doc)
		-DMOD_AVFORMAT=$(usex ffmpeg)
		-DMOD_FREI0R=$(usex frei0r)
		-DMOD_GDK=$(usex gtk)
		-DMOD_JACKRACK=$(usex jack)
		-DMOD_KDENLIVE=yes
		-DMOD_OPENCV=$(usex opencv)
		-DMOD_MOVIT=$(usex opengl)
		-DMOD_PLUS=$(usex fftw)
		-DMOD_QT=$(usex qt5)
		-DMOD_RESAMPLE=$(usex libsamplerate)
		-DMOD_RTAUDIO=$(usex rtaudio)
		-DMOD_RUBBERBAND=$(usex rubberband)
		-DMOD_SDL1=$(usex sdl1)
		-DMOD_SDL2=$(usex sdl)
		-DMOD_SOX=$(usex sox)
		-DMOD_VIDSTAB=$(usex vidstab)
		-DMOD_XINE=$(usex xine)
		-DMOD_XML=$(usex xml)

		-DSWIG_PYTHON=$(usex python)
		-DSWIG_LUA=$(usex lua)
	)
	use python && mycmakeargs+=(
		-DPython3_EXECUTABLE="${PYTHON}"
	)
	cmake_src_configure

	# TODO: add swig language bindings
	# see also https://www.mltframework.org/twiki/bin/view/MLT/ExtremeMakeover
}

src_compile() {
	cmake_src_compile

	if use lua; then
		local _b="${BUILD_DIR}"
		BUILD_DIR="${S}"
		# Only copy sources now to avoid unnecessary rebuilds
		lua_copy_sources

		lua_compile() {
			pushd "${BUILD_DIR}"/src/swig/lua > /dev/null || die

			sed -i -e "s| mlt_wrap.cxx| $(lua_get_CFLAGS) mlt_wrap.cxx|" build || die
			./build

			popd > /dev/null || die
		}
		lua_foreach_impl lua_compile
		BUILD_DIR="${_b}"
	fi
}

src_install() {
	cmake_src_install

	insinto /usr/share/mlt-7
	doins -r demo

	#
	# Install SWIG bindings
	#

	docinto swig

	if use python; then
		dodoc src/swig/python/play.py
		python_optimize
	fi

	if use lua; then
		BUILD_DIR="${S}"
		lua_install() {
			pushd "${BUILD_DIR}"/src/swig/lua > /dev/null || die

			exeinto "$(lua_get_cmod_dir)"
			newexe mlt.so mlt7.so

			popd > /dev/null || die
		}
		lua_foreach_impl lua_install

		dodoc "${S}"/src/swig/lua/play.lua
	fi
	# not done: java perl php ruby tcl
}
