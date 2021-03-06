# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs
MY_GC="gmic-community-e6976b2"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="626699d"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_OFX='openfx-108880d'
	SRC_URI="
		mirror://githubcl/NatronGitHub/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-} -> ${MY_OFX}.tar.gz
		mirror://githubcl/dtschump/${MY_GC%-*}/tar.gz/${MY_GC##*-} -> ${MY_GC}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="OpenFX wrapper for the G'MIC framework"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="|| ( CeCILL-C CeCILL-2 )"
SLOT="0"
IUSE="openmp"

RDEPEND="
	>=media-gfx/gmic-2.8.4:=[cgmic(-),curl,fftw,openmp?]
"
DEPEND="${RDEPEND}"

src_unpack() {
	if [[ -z ${PV%%*9999} ]]; then
		git-r3_src_unpack
		EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_GC}" \
		EGIT_REPO_URI="https://github.com/dtschump/${MY_GC%-*}.git" \
			git-r3_src_unpack
	else
		default
	fi
}

src_prepare() {
	default
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/openfx
	fi
	mv "${WORKDIR}"/${MY_GC}/libcgmic/gmic_stdlib_gmic.h "${S}"/
	sed \
		-e 's:gmic\.cpp gmic_libc\.cpp::' \
		-i GMIC_OFX/Makefile
	echo 'LINKFLAGS += -lcgmic' >> GMIC_OFX/Makefile
	sed \
		-e "s:PLUGINPATH=\"/:PLUGINPATH=\"${ED}/:" \
		-e 's,^install:,&\n\tmkdir -p "$(PLUGINPATH)",' \
		-i openfx/Examples/Makefile.master
}

src_compile() {
	local myemakeargs=(
		-C GMIC_OFX
		CXX=$(tc-getCXX)
		CXXFLAGS_ADD="${CXXFLAGS}"
		LDFLAGS_ADD="${LDFLAGS}"
		OPENMP=$(usex openmp 1 '')
		V=1
	)
	emake "${myemakeargs[@]}"
}
