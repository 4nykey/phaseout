# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake
MY_GC="gmic-community-e6976b2"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="626699d"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_OFX='openfx-e405e09'
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
PATCHES=( "${FILESDIR}"/cmake.diff )

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
	sed -e '/PROPERTIES INSTALL_RPATH/d' -i CMakeLists.txt
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/openfx
	fi
	mv "${WORKDIR}"/${MY_GC}/libcgmic/gmic_stdlib_gmic.h "${S}"/
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/OFX/Plugins"
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=yes
	)
	cmake_src_configure
}
