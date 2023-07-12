# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..11} )
# locale/LINGUAS
PLOCALES="
af ar be bg bn bs ca ca_ES@valencia co cs cy da de el es eu eu_ES fa fi fr ga
gl he hi hr hu hy id it ja ka km ko lt mk mr my nb nl oc pl pt_BR pt_PT ro ru
sk sl sr_RS sr_RS@latin sv ta tg tr uk vi zh_CN zh_TW
"
if [[ -z ${PV%%*9999} ]]; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	inherit git-r3
	REQUIRED_USE="!doc"
else
	MY_PV="$(ver_rs 3-4 '-')"
	MY_PV="${MY_PV/-rc-/-RC}"
	MY_PV="${PN^}-${MY_PV%_*}"
	[[ -z ${PV%%*_p*} ]] && MY_PV="84d5e63"
	SRC_URI="
		mirror://githubcl/${PN}/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	case ${PV} in
		*_alpha*|*_beta*|*_pre*)
			REQUIRED_USE="!doc" ;;
		*)
			SRC_URI+=" doc? (
			https://github.com/${PN}/${PN}/releases/download/${MY_PV}/${PN}-manual-${MY_PV#*-}.tar.gz
			)" ;;
	esac
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi
MY_TP="ThreadPool-9a42ec1"
SRC_URI+="
	curl? (
		mirror://githubcl/progschj/${MY_TP%-*}/tar.gz/${MY_TP##*-} -> ${MY_TP}.tar.gz
	)
"
inherit plocale python-any-r1 cmake flag-o-matic xdg

DESCRIPTION="Free crossplatform audio editor"
HOMEPAGE="https://web.audacityteam.org/"

LICENSE="GPL-3"
SLOT="0"
IUSE="
alsa curl doc ffmpeg +flac id3tag jack +ladspa +lv2 mp3
nls ogg oss pch +portmixer sbsms +soundtouch twolame vamp +vorbis
vst wavpack
"
RESTRICT="test primaryuri"

DEPEND="
	media-libs/portaudio[alsa?]
	media-libs/portmidi
	media-libs/portsmf:=
	dev-libs/expat
	media-libs/libsndfile
	media-libs/libsoundtouch
	media-libs/soxr
	>=media-sound/lame-3.100-r3
	x11-libs/wxGTK:3.2=[X,regex(+)]
	dev-db/sqlite:3
	alsa? ( media-libs/alsa-lib )
	curl? (
		net-misc/curl
		dev-libs/rapidjson
	)
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
	mp3? ( media-sound/mpg123 )
	ogg? ( media-libs/libogg )
	sbsms? ( media-libs/libsbsms:= )
	soundtouch? ( >=media-libs/libsoundtouch-1.7.1 )
	twolame? ( media-sound/twolame )
	vamp? ( media-libs/vamp-plugin-sdk )
	vorbis? ( media-libs/libvorbis )
	vst? (
		media-libs/vst3sdk
		x11-libs/libX11
	)
	wavpack? ( media-sound/wavpack )
"
RDEPEND="
	${DEPEND}
	ffmpeg? ( media-video/ffmpeg:= )
"
BDEPEND="
	doc? ( app-arch/unzip )
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
"

PATCHES=(
	"${FILESDIR}"/vst3.diff
)

src_prepare() {
	sed -e 's:\<ccache\>:no_&:' -i CMakeLists.txt

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

	cmake_src_prepare

	use curl || return
	mv "${WORKDIR}"/${MY_TP} "${S}"/libraries/lib-network-manager/${MY_TP%-*}
	sed -e '/audacity_find_package(ThreadPool/d' \
		-i cmake-proxies/cmake-modules/DependenciesList.cmake
	sed -e '/threadpool::threadpool/d' -i libraries/lib-network-manager/CMakeLists.txt
}

src_configure() {
	local _w="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.2"
	local _r=2
	case ${PV} in
		*_beta*) _r=1 ;;
		*_p*|9999*) _r=0 ;;
	esac
	# * always use system libraries if possible
	# * options listed in the order that cmake-gui lists them
	local mycmakeargs=(
		-DAUDACITY_BUILD_LEVEL=${_r}
		-DCMAKE_SKIP_BUILD_RPATH=yes
		-DwxWidgets_CONFIG_EXECUTABLE="${_w}"
		-Daudacity_conan_enabled=off
		-Daudacity_lib_preference=system
		-Daudacity_obey_system_dependencies=yes
		-Daudacity_use_ffmpeg=$(usex ffmpeg loaded off)
		-Daudacity_use_libflac=$(usex flac system off)
		-Daudacity_use_libid3tag=$(usex id3tag system off)
		-Daudacity_use_ladspa=$(usex ladspa)
		-Daudacity_use_lv2=$(usex lv2 system off)
		-Daudacity_use_libmpg123=$(usex mp3 system off)
		-Daudacity_use_midi=system
		-Daudacity_has_networking=$(usex curl)
		-Daudacity_has_updates_check=no
		-Daudacity_use_libogg=$(usex ogg system off)
		-Daudacity_use_portaudio=system
		-Daudacity_use_portmixer=$(usex portmixer system off)
		-Daudacity_use_portsmf=system
		-Daudacity_use_sbsms=$(usex sbsms system off)
		-Daudacity_use_twolame=$(usex twolame system off)
		-Daudacity_use_vamp=$(usex vamp system off)
		-Daudacity_use_libvorbis=$(usex vorbis system off)
		-Daudacity_use_wavpack=$(usex wavpack system off)
		-Daudacity_has_vst3=$(usex vst)
		-DDISABLE_DYNAMIC_LOADING_LAME=yes
		-Duse_pch=$(usex pch)
	)
	[[ -n ${PV%%*9999} ]] && mycmakeargs+=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Git=yes
	)
	has_version '~sys-devel/gettext-0.22' && mycmakeargs+=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Gettext=yes
	)
	cmake_src_configure
}

src_compile() {
	LD_LIBRARY_PATH="${BUILD_DIR}/Gentoo/$(get_libdir)/${PN}" \
	cmake_src_compile
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
