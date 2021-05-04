# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="f4c99c3"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_OFX='openfx-108880d'
	MY_SUP='openfx-supportext-bde8d6a'
	SRC_URI="
		mirror://githubcl/NatronGitHub/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-} -> ${MY_OFX}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SUP%-*}/tar.gz/${MY_SUP##*-} -> ${MY_SUP}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="Miscellaneous OpenFX plugins for Natron"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="
	virtual/opengl
"
DEPEND="${RDEPEND}"

src_prepare() {
	default
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/openfx
		mv "${WORKDIR}"/${MY_SUP}/* "${S}"/SupportExt
	fi
}

src_compile() {
	local myemakeargs=(
		CXX=$(tc-getCXX)
		CXXFLAGS_ADD="${CXXFLAGS}"
		LDFLAGS_ADD="${LDFLAGS} -lpthread"
		V=1
	)
	emake "${myemakeargs[@]}"
}
