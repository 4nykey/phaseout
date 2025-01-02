# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# locale/LINGUAS
PLOCALES="
af ar be bg bn bs ca ca_ES@valencia co cs cy da de el es eu_ES fa fi fr ga gl
he hi hr hu hy id it ja ka km ko lt mk mr my nb nl oc pl pt_BR pt_PT ro ru sk
sl sr_RS sr_RS@latin sv ta tg tr uk vi zh_CN zh_TW
"
if [[ -z ${PV%%*9999} ]]; then
	EGIT_REPO_URI="https://codeberg.org/tenacityteam/${PN}.git"
	EGIT_SUBMODULES=( lib-src/libnyquist )
	inherit git-r3
else
	MY_PV="685e7c7"
	MY_NY="libnyquist-d4fe08b"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		https://codeberg.org/tenacityteam/${PN}/archive/${MY_PV}.tar.gz
		-> ${P}.tar.gz
		https://codeberg.org/tenacityteam/${MY_NY%-*}/archive/${MY_NY##*-}.tar.gz
		-> ${MY_NY}.tar.gz
	"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}"
fi
inherit plocale cmake flag-o-matic xdg

DESCRIPTION="An easy-to-use multi-track audio editor and recorder"
HOMEPAGE="https://tenacityaudio.org"

LICENSE="GPL-2 CC-BY-3.0"
SLOT="0"
IUSE="
ffmpeg flac id3tag ladspa lv2 mad nls ogg portmidi sbsms soundtouch twolame
vamp vorbis vst
"
RESTRICT="test primaryuri"

RDEPEND="
	>=x11-libs/wxGTK-3.2:=[X]
	dev-libs/expat
	media-sound/lame
	media-libs/libsndfile
	media-libs/soxr
	dev-db/sqlite:3
	media-libs/portaudio
	portmidi? (
		media-libs/portmidi
		media-libs/portsmf:=
	)
	id3tag? ( media-libs/libid3tag:= )
	mad? ( media-libs/libmad:= )
	twolame? ( media-sound/twolame )
	ogg? ( media-libs/libogg )
	vorbis? ( media-libs/libvorbis )
	flac? ( media-libs/flac[cxx] )
	sbsms? ( media-libs/libsbsms:= )
	soundtouch? ( media-libs/libsoundtouch:= )
	ffmpeg? ( media-video/ffmpeg:= )
	vamp? ( media-libs/vamp-plugin-sdk )
	lv2? (
		dev-libs/serd
		dev-libs/sord
		media-libs/lilv
		media-libs/lv2
		media-libs/sratom
		media-libs/suil
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"

PATCHES=(
	"${FILESDIR}"/cmake.diff
)

src_prepare() {
	has_version media-sound/audacity && sed \
		-e '/x-audacity-project\.xpm/d' -i images/CMakeLists.txt

	rm_locale() {
		sed -e "/${1}/d" -i locale/LINGUAS
	}
	if use nls; then
		plocale_for_each_disabled_locale rm_locale
	else
		sed -e '/add_subdirectory( "locale" )/d' -i CMakeLists.txt || die
		sed \
			-e '/add_dependencies( \${TARGET} locale )/d' \
			-i src/CMakeLists.txt || die
	fi

	[[ -d ../libnyquist ]] && mv ../libnyquist/* lib-src/libnyquist
	cmake_src_prepare
	mkdir -p "${BUILD_DIR}"/src/private
}

src_configure() {
	local _w="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.2"
	local mycmakeargs=(
		-DwxWidgets_CONFIG_EXECUTABLE="${_w}"
		-DCCACHE=no
		-DSCCACHE=no
		-DMIDI=$(usex portmidi system off)
		-DID3TAG=$(usex id3tag system off)
		-DMP3_DECODING=$(usex mad system off)
		-DMP2=$(usex twolame system off)
		-DOGG=$(usex ogg system off)
		-DVORBIS=$(usex vorbis system off)
		-DFLAC=$(usex flac system off)
		-DSBSMS=$(usex sbsms system off)
		-DSOUNDTOUCH=$(usex soundtouch system off)
		-DFFMPEG=$(usex ffmpeg system off)
		-DVAMP=$(usex vamp system off)
		-DLV2=$(usex lv2 system off)
		-DLADSPA=$(usex ladspa)
		-DVST2=$(usex vst)
	)
	if [[ -n ${PV%%*9999} ]]; then
		mycmakeargs+=(
			-DCMAKE_DISABLE_FIND_PACKAGE_Git=yes
			-DGIT_DESCRIBE="${MY_PV}"
		)
		touch src/RevisionIdent.h
	fi
	cmake_src_configure
}
