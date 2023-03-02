# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/mltframework/${PN}.git"
else
	MY_PV="20db1b6"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	MY_GLA="glaxnimate-e9f08e3"
	SRC_URI="
		mirror://githubcl/mltframework/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		glaxnimate? (
			https://gitlab.com/mattbas/${MY_GLA%-*}/-/archive/${MY_GLA##**-}/${MY_GLA}.tar.bz2
		)
	"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

LUA_COMPAT=( lua5-{1..4} luajit )
PYTHON_COMPAT=( python3_{9..11} )
inherit python-single-r1 cmake

DESCRIPTION="Open source multimedia framework for television broadcasting"
HOMEPAGE="https://www.mltframework.org/"

LICENSE="GPL-3"
SLOT="0/7"
IUSE="debug ffmpeg frei0r gtk jack libsamplerate opencv opengl python qt5 rtaudio rubberband sdl test vdpau vidstab xine xml"
IUSE+=" doc glaxnimate sdl1 sox qt6"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"
REQUIRED_USE+="
	test? ( qt5 )
	glaxnimate? ( qt5 )
"

# Needs unpackaged 'kwalify'
RESTRICT="test"
RESTRICT+=" primaryuri"

# rtaudio will use OSS on non linux OSes
# Qt already needs FFTW/PLUS so let's just always have it on to ensure
# MLT is useful: bug #603168.
DEPEND="
	>=media-libs/libebur128-1.2.2:=
	sci-libs/fftw:3.0=
	ffmpeg? ( media-video/ffmpeg:0=[vdpau?,-flite] )
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
	opencv? ( >=media-libs/opencv-4.5.1:=[contrib] )
	opengl? (
		media-libs/libglvnd
		media-video/movit
	)
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
	qt6? (
		dev-qt/qtsvg:6
		dev-qt/qt5compat:6
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
#	java? ( >=virtual/jre-1.8:* )
#	perl? ( dev-lang/perl )
#	php? ( dev-lang/php )
#	ruby? ( ${RUBY_DEPS} )
#	tcl? ( dev-lang/tcl:0= )
RDEPEND="${DEPEND}"
BDEPEND="
	virtual/pkgconfig
	python? ( >=dev-lang/swig-2.0 )
"

DOCS=( AUTHORS NEWS README.md )

PATCHES=(
	"${FILESDIR}"/${PN}-6.10.0-swig-underlinking.patch
	"${FILESDIR}"/${PN}-6.22.1-no_lua_bdepend.patch
	"${FILESDIR}"/${PN}-7.0.1-cmake-symlink.patch
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	[[ -n ${PV%%*9999} ]] && mv \
		"${WORKDIR}"/${MY_GLA}/* src/modules/glaxnimate/glaxnimate/

	# Respect CFLAGS LDFLAGS when building shared libraries. Bug #308873
	if use python; then
		sed -i "/mlt.so/s/ -lmlt++ /& ${CFLAGS} ${LDFLAGS} /" src/swig/python/build || die
		python_fix_shebang src/swig/python
	fi

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_SKIP_BUILD_RPATH=yes
		-DGPL=yes
		-DGPL3=yes
		-DBUILD_TESTING=$(usex test)
		-DMOD_KDENLIVE=ON
		-DMOD_SDL1=$(usex sdl1)
		-DMOD_SDL2=$(usex sdl)
		-DMOD_AVFORMAT=$(usex ffmpeg)
		-DMOD_PLUS=yes
		-DMOD_FREI0R=$(usex frei0r)
		-DMOD_GDK=$(usex gtk)
		-DMOD_JACKRACK=$(usex jack)
		-DMOD_GLAXNIMATE=$(usex glaxnimate)
		-DMOD_RESAMPLE=$(usex libsamplerate)
		-DMOD_OPENCV=$(usex opencv)
		-DMOD_MOVIT=$(usex opengl)
		-DMOD_QT=$(usex qt5)
		-DMOD_QT6=$(usex qt6)
		-DMOD_RTAUDIO=$(usex rtaudio)
		-DMOD_RUBBERBAND=$(usex rubberband)
		-DMOD_VIDSTAB=$(usex vidstab)
		-DMOD_XINE=$(usex xine)
		-DMOD_XML=$(usex xml)
		-DMOD_SOX=$(usex sox)
	)

	# TODO: rework upstream CMake to allow controlling MMX/SSE/SSE2
	# TODO: add swig language bindings?
	# see also https://www.mltframework.org/twiki/bin/view/MLT/ExtremeMakeover

	if use python; then
		mycmakeargs+=(
			-DSWIG_PYTHON=yes
			-DPython3_EXECUTABLE="${EPREFIX}/usr/bin/${EPYTHON}"
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	insinto /usr/share/${PN}
	doins -r demo

	#
	# Install SWIG bindings
	#

	docinto swig

	if use python; then
		dodoc "${S}"/src/swig/python/play.py
		python_optimize
	fi
}
