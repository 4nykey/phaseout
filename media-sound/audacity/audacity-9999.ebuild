# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
if [[ -z ${PV%%*9999} ]]; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	inherit git-r3
else
	if [[ -n ${PV%%*_p*} ]]; then
		MY_P="${PN}-minsrc-${PV}"
		SRC_URI="
		https://github.com/${PN}/${PN}/releases/download/${PN^}-${PV}/${MY_P}.tar.xz
		"
	else
		MY_P="${PN}-ff5003a"
		SRC_URI="
			mirror://githubcl/${PN}/${PN}/tar.gz/${MY_P#*-} -> ${P}.tar.gz
		"
	fi
	SRC_URI+="
		doc? (
		https://github.com/${PN}/${PN}/releases/download/${PN^}-${PV%_p*}/${PN}-manual-${PV%_p*}.zip
		)
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi
inherit cmake flag-o-matic xdg

DESCRIPTION="Free crossplatform audio editor"
HOMEPAGE="https://web.audacityteam.org/"

LICENSE="GPL-2"
SLOT="0"
IUSE="
alsa cpu_flags_x86_sse doc ffmpeg +flac id3tag jack +ladspa +lame +lv2 mad midi
nls ogg oss portmidi +portmixer portsmf sbsms +soundtouch twolame vamp +vorbis
+vst
"

RESTRICT="test"
RESTRICT+=" primaryuri"

RDEPEND="dev-libs/expat
	media-libs/libsndfile
	media-libs/libsoundtouch
	media-libs/portaudio[alsa?]
	media-libs/soxr
	>=media-sound/lame-3.100-r3
	x11-libs/wxGTK:3.1=[X]
	alsa? ( media-libs/alsa-lib )
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
	portmidi? ( media-libs/portmidi )
	sbsms? ( >=media-libs/libsbsms-2.2 )
	soundtouch? ( >=media-libs/libsoundtouch-1.7.1 )
	twolame? ( media-sound/twolame )
	vamp? ( media-libs/vamp-plugin-sdk )
	vorbis? ( media-libs/libvorbis )
"
DEPEND="${RDEPEND}"
BDEPEND="app-arch/unzip
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"

PATCHES=(
	"${FILESDIR}"/wx.diff
	"${FILESDIR}"/NoteTrackShifter.diff
	"${FILESDIR}"/pa_jack.diff
)

src_prepare() {
	sed -e '/CMAKE_[A-Z_]\+_RPATH/d' -i CMakeLists.txt
	sed -e '/DESTINATION/s:appdata:metainfo:' -i help/CMakeLists.txt
	cmake_src_prepare
}

src_configure() {
	local -x WX_CONFIG="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.1"
	# * always use system libraries if possible
	# * options listed in the order that cmake-gui lists them
	local mycmakeargs=(
		-Daudacity_lib_preference=system
		-Daudacity_use_expat=system
		-Daudacity_use_ffmpeg=$(usex ffmpeg linked off)
		-Daudacity_use_flac=$(usex flac system off)
		-Daudacity_use_id3tag=$(usex id3tag system off)
		-Daudacity_use_ladspa=$(usex ladspa)
		-Daudacity_use_lame=system
		-Daudacity_use_lv2=$(usex lv2 system off)
		-Daudacity_use_mad=$(usex mad system off)
		-Daudacity_use_midi=$(usex portmidi system off)
		-Daudacity_use_ogg=$(usex ogg system off)
		-Daudacity_use_pa_alsa=$(usex alsa)
		-Daudacity_use_pa_jack=$(usex jack linked off)
		-Daudacity_use_pa_oss=$(usex oss)
		-Daudacity_use_portmixer=$(usex portmixer local off)
		-Daudacity_use_portsmf=$(usex portsmf system off)
		-Daudacity_use_sbsms=$(usex sbsms system off)
		-Daudacity_use_sndfile=system
		-Daudacity_use_soundtouch=system
		-Daudacity_use_soxr=system
		-Daudacity_use_twolame=$(usex twolame system off)
		-Daudacity_use_vamp=$(usex vamp system off)
		-Daudacity_use_vorbis=$(usex vorbis system off)
		-Daudacity_use_vst=$(usex vst)
		-Daudacity_use_wxwidgets=system
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
