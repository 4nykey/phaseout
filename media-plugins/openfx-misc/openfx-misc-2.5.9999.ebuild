# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="9c26c5f"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_OFX='openfx-f167682'
	MY_SUP='openfx-supportext-79d8c22'
	SRC_URI="
		mirror://githubcl/NatronGitHub/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-} -> ${MY_OFX}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SUP%-*}/tar.gz/${MY_SUP##*-} -> ${MY_SUP}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi
# CImg/Makefile: CIMGVERSION
MY_CIM='CImg-89b9d06'
SRC_URI+="
	mirror://githubcl/dtschump/${MY_CIM%-*}/tar.gz/${MY_CIM##*-} -> ${MY_CIM}.tar.gz
"

DESCRIPTION="Miscellaneous OpenFX plugins for Natron"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="
	virtual/opengl
"
DEPEND="${RDEPEND}"
PATCHES=( "${FILESDIR}"/cmake.diff )

src_prepare() {
	sed -e '/PROPERTIES INSTALL_RPATH/d' -i CMakeLists.txt
	cmake_src_prepare
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* openfx
		mv "${WORKDIR}"/${MY_SUP}/* SupportExt
	fi
	mv "${WORKDIR}"/${MY_CIM}/CImg.h CImg
	mv "${WORKDIR}"/${MY_CIM}/plugins/inpaint.h CImg/Inpaint
	cd CImg/Inpaint
	eapply inpaint.h.patch
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/OFX/Plugins"
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=yes
	)
	cmake_src_configure
}
