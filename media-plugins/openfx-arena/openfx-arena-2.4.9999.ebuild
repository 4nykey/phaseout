# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="e9ab79a"
	if [[ -n ${PV%%*_p*} ]]; then
		MY_PV="Natron-${PV}"
		MY_OIO="${MY_PV}"
	else
		MY_OIO="3b80afe"
	fi
	MY_OFX='openfx-f46d822'
	MY_SUP='openfx-supportext-76f9748'
	MY_SEQ='SequenceParsing-103c528'
	MY_TIN='tinydir-64fb1d4'
	MY_PNG='lodepng-8c6a9e3'
	SRC_URI="
		mirror://githubcl/NatronGitHub/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-} -> ${MY_OFX}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SUP%-*}/tar.gz/${MY_SUP##*-} -> ${MY_SUP}.tar.gz
		mirror://githubcl/NatronGitHub/openfx-io/tar.gz/${MY_OIO} -> openfx-io-${MY_OIO}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SEQ%-*}/tar.gz/${MY_SEQ##*-} -> ${MY_SEQ}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_TIN%-*}/tar.gz/${MY_TIN##*-} -> ${MY_TIN}.tar.gz
		mirror://githubcl/lvandeve/${MY_PNG%-*}/tar.gz/${MY_PNG##*-} -> ${MY_PNG}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="Extra OpenFX plugins for Natron"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE="sox"

RDEPEND="
	media-gfx/imagemagick:=
	dev-libs/librevenge
	media-libs/libcdr
	media-libs/lcms
	media-libs/fontconfig
	dev-libs/libxml2
	dev-libs/libzip
	gnome-base/librsvg
	x11-libs/pango
	>=app-text/poppler-0.83:=
	virtual/opencl
	<media-libs/opencolorio-2:=
	sox? ( media-sound/sox )
"
DEPEND="${RDEPEND}"
PATCHES=(
	"${FILESDIR}"/cmake.diff
)

src_unpack() {
	if [[ -z ${PV%%*9999} ]]; then
		git-r3_src_unpack
		EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_PNG}" \
		EGIT_REPO_URI="https://github.com/lvandeve/lodepng.git" \
			git-r3_src_unpack
	else
		default
	fi
}

src_prepare() {
	sed -e '/PROPERTIES INSTALL_RPATH/d' -i CMakeLists.txt
	cmake_src_prepare
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/OpenFX
		mv "${WORKDIR}"/${MY_SUP}/* "${S}"/SupportExt
		mv "${WORKDIR}"/openfx-io-${MY_OIO}/* "${S}"/OpenFX-IO
		mv "${WORKDIR}"/${MY_SEQ}/* "${S}"/OpenFX-IO/IOSupport/SequenceParsing
		mv "${WORKDIR}"/${MY_TIN}/* "${S}"/OpenFX-IO/IOSupport/SequenceParsing/tinydir
		mv "${WORKDIR}"/${MY_PNG}/* "${S}"/lodepng
	fi
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/OFX/Plugins"
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=yes
	)
	cmake_src_configure
}
