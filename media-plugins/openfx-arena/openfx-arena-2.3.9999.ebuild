# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	inherit vcs-snapshot
	MY_PV="3ffa0a3"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_OFX='openfx-cc363a7'
	MY_SUP='openfx-supportext-6f7cdfe'
	MY_OIO='openfx-io-60096b7'
	MY_SEQ='SequenceParsing-977e36f'
	MY_TIN='tinydir-3aae922'
	# PNGVERSION in Extra/Makefile
	MY_PNG="lodepng-a70c086"
	SRC_URI="
		mirror://githubcl/NatronGitHub/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-} -> ${MY_OFX}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SUP%-*}/tar.gz/${MY_SUP##*-} -> ${MY_SUP}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OIO%-*}/tar.gz/${MY_OIO##*-} -> ${MY_OIO}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SEQ%-*}/tar.gz/${MY_SEQ##*-} -> ${MY_SEQ}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_TIN%-*}/tar.gz/${MY_TIN##*-} -> ${MY_TIN}.tar.gz
		mirror://githubcl/lvandeve/${MY_PNG%-*}/tar.gz/${MY_PNG##*-} -> ${MY_PNG}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Extra OpenFX plugins for Natron"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="
	media-gfx/imagemagick
	dev-libs/librevenge
	media-libs/libcdr
	media-libs/lcms
	media-libs/fontconfig
	dev-libs/libxml2
	dev-libs/libzip
	gnome-base/librsvg
	x11-libs/pango
	app-text/poppler
	virtual/opencl
"
DEPEND="${RDEPEND}"

src_unpack() {
	if [[ -z ${PV%%*9999} ]]; then
		git-r3_src_unpack
		EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_PNG}" \
		EGIT_REPO_URI="https://github.com/lvandeve/lodepng.git" \
			git-r3_src_unpack
	else
		vcs-snapshot_src_unpack
	fi
}

src_prepare() {
	default
	sed \
		-e "s:\<pkg-config\>:$(tc-getPKG_CONFIG):" \
		-e 's:--static::' \
		-i Makefile.master
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/OpenFX
		mv "${WORKDIR}"/${MY_SUP}/* "${S}"/SupportExt
		mv "${WORKDIR}"/${MY_OIO}/* "${S}"/OpenFX-IO
		mv "${WORKDIR}"/${MY_SEQ}/* "${S}"/OpenFX-IO/IOSupport/SequenceParsing
		mv "${WORKDIR}"/${MY_TIN}/* "${S}"/OpenFX-IO/IOSupport/SequenceParsing/tinydir
	fi
	mv "${WORKDIR}"/${MY_PNG}/lodepng.{h,cpp} "${S}"/Extra
}

src_compile() {
	local myemakeargs=(
		CXX=$(tc-getCXX)
		CXXFLAGS_ADD="${CXXFLAGS}"
		LDFLAGS_ADD="${LDFLAGS}"
		V=1
	)
	emake "${myemakeargs[@]}"
}
