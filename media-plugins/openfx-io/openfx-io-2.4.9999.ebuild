# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="3b80afe"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_P="${PN}-${MY_PV}"
	MY_OFX='openfx-108880d'
	MY_SUP='openfx-supportext-bde8d6a'
	MY_SEQ='SequenceParsing-ab247c2'
	MY_TIN='tinydir-3aae922'
	SRC_URI="
		mirror://githubcl/NatronGitHub/${PN}/tar.gz/${MY_PV} -> ${MY_P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-} -> ${MY_OFX}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SUP%-*}/tar.gz/${MY_SUP##*-} -> ${MY_SUP}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SEQ%-*}/tar.gz/${MY_SEQ##*-} -> ${MY_SEQ}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_TIN%-*}/tar.gz/${MY_TIN##*-} -> ${MY_TIN}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

DESCRIPTION="A set of Readers/Writers plugins written using the OpenFX standard"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="
	media-libs/openexr:=
	media-libs/openimageio:=[color-management(+),ffmpeg,opengl,raw]
	<media-libs/opencolorio-2:=
	dev-libs/seexpr:0
"
DEPEND="${RDEPEND}"
PATCHES=( "${FILESDIR}"/openexr3.diff )

src_prepare() {
	default
	sed \
		-e '/OIIO_CXXFLAGS =/ s:=.*:=`pkg-config --cflags OpenImageIO libraw`:' \
		-e '/OIIO_LINKFLAGS =/ s:=.*:=`pkg-config --libs OpenImageIO`:' \
		-e "s:\<pkg-config\>:$(tc-getPKG_CONFIG):g" \
		-e 's:\<IlmBase\>::' \
		-i Makefile.master
	has_version media-libs/openexr:3 && sed \
		-e 's:\<OpenEXR\>:&-3:g' -i Makefile.master
	sed -e 's:LINKFLAGS += .*:& -ldl:' -i IO/Makefile
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/openfx
		mv "${WORKDIR}"/${MY_SUP}/* "${S}"/SupportExt
		mv "${WORKDIR}"/${MY_SEQ}/* "${S}"/IOSupport/SequenceParsing
		mv "${WORKDIR}"/${MY_TIN}/* "${S}"/IOSupport/SequenceParsing/tinydir
	fi
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
