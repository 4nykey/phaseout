# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

if [[ -z ${PV%%*9999} ]]; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	inherit git-r3
	REQUIRED_USE="!doc"
else
	MY_PV="${PN^}-${PV/_rc/-RC}"
	SRC_URI="
		doc? (
		https://github.com/${PN}/${PN}/releases/download/${PN^}-${MY_PV#*-}/${PN}-manual-${MY_PV#*-}.zip
		)
	"
	[[ -z ${PV%%*_p*} ]] && MY_PV="84d5e63"
	SRC_URI+="
		mirror://githubcl/${PN}/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi
MY_TP="ThreadPool-9a42ec1"
SRC_URI+="
	curl? (
		mirror://githubcl/progschj/${MY_TP%-*}/tar.gz/${MY_TP##*-} -> ${MY_TP}.tar.gz
	)
"
inherit cmake flag-o-matic xdg

DESCRIPTION="Free crossplatform audio editor"
HOMEPAGE="https://web.audacityteam.org/"

LICENSE="GPL-2"
SLOT="0"
IUSE="
alsa curl doc ffmpeg +flac id3tag jack +ladspa +lv2 mad
nls ogg oss portmidi +portmixer portsmf sbsms +soundtouch twolame vamp +vorbis
+vst
"
RESTRICT="test primaryuri"

RDEPEND="
	media-libs/portaudio[alsa?]
	portmidi? ( media-libs/portmidi )
"
RDEPEND="
	dev-libs/expat
	media-libs/libsndfile
	media-libs/libsoundtouch
	media-libs/soxr
	>=media-sound/lame-3.100-r3
	x11-libs/wxGTK:3.1=[X]
	alsa? ( media-libs/alsa-lib )
	curl? ( net-misc/curl )
	ffmpeg? ( media-video/ffmpeg:= )
	flac? ( media-libs/flac[cxx] )
	id3tag? ( media-libs/libid3tag )
	jack? ( virtual/jack )
	lv2? (
		dev-libs/serd
		dev-libs/sord
		media-libs/lilv
		media-libs/lv2
		media-libs/sratom
		media-libs/suil
	)
	mad? ( >=media-libs/libmad-0.15.1b )
	ogg? ( media-libs/libogg )
	sbsms? ( >=media-libs/libsbsms-2.2 )
	soundtouch? ( >=media-libs/libsoundtouch-1.7.1 )
	twolame? ( media-sound/twolame )
	vamp? ( media-libs/vamp-plugin-sdk )
	vorbis? ( media-libs/libvorbis )
"
DEPEND="${RDEPEND}"
BDEPEND="
	doc? ( app-arch/unzip )
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"

PATCHES=(
	"${FILESDIR}"/cmake.diff
)

src_prepare() {
	use portmidi || sed \
		-e '/MIDI_OUT/d' -i src/Experimental.cmake
	cmake_src_prepare
	use curl || return
	mv "${WORKDIR}"/${MY_TP} "${S}"/libraries/lib-network-manager/${MY_TP%-*}
}

src_configure() {
	local _w="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.1"
	# * always use system libraries if possible
	# * options listed in the order that cmake-gui lists them
	local mycmakeargs=(
		-DCMAKE_SKIP_BUILD_RPATH=yes
		-DwxWidgets_CONFIG_EXECUTABLE="${_w}"
		-Daudacity_lib_preference=system
		-Daudacity_obey_system_dependencies=yes
		-Daudacity_use_ffmpeg=$(usex ffmpeg linked off)
		-Daudacity_use_flac=$(usex flac system off)
		-Daudacity_use_libid3tag=$(usex id3tag system off)
		-Daudacity_use_ladspa=$(usex ladspa)
		-Daudacity_use_lv2=$(usex lv2 system off)
		-Daudacity_use_libmad=$(usex mad system off)
		-Daudacity_use_midi=$(usex portmidi local off)
		-Daudacity_has_networking=$(usex curl)
		-Daudacity_has_updates_check=no
		-Daudacity_use_ogg=$(usex ogg system off)
		-Daudacity_use_pa_alsa=$(usex alsa)
		-Daudacity_use_pa_jack=$(usex jack linked off)
		-Daudacity_use_pa_oss=$(usex oss)
		-Daudacity_use_portaudio=local
		-Daudacity_use_portmixer=$(usex portmixer local off)
		-Daudacity_use_portsmf=$(usex portsmf local off)
		-Daudacity_use_sbsms=$(usex sbsms system off)
		-Daudacity_use_twolame=$(usex twolame system off)
		-Daudacity_use_vamp=$(usex vamp system off)
		-Daudacity_use_vorbis=$(usex vorbis system off)
		-Daudacity_use_vst=$(usex vst)
		-DDISABLE_DYNAMIC_LOADING_FFMPEG=yes
		-DDISABLE_DYNAMIC_LOADING_LAME=yes
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	# Remove bad doc install
	rm -r "${ED}"/usr/share/doc || die

	if use doc ; then
		docinto html
		dodoc -r "${WORKDIR}"/help/manual/.
		dosym ../../doc/${PF}/html /usr/share/${PN}/help/manual
	fi
}
