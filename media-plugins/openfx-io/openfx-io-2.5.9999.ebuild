# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="9fb5ee9"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_P="${PN}-${MY_PV}"
	MY_OFX='openfx-a5d9ca8'
	MY_SUP='openfx-supportext-8aff0b0'
	MY_SEQ='SequenceParsing-3c93fcc'
	MY_TIN='tinydir-64fb1d4'
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
	media-libs/openimageio:=[ffmpeg,opengl,-openvdb,raw]
	media-libs/opencolorio:=
	media-libs/glu
	dev-libs/seexpr:0
"
DEPEND="${RDEPEND}"
PATCHES=(
	"${FILESDIR}"/cmake.diff
)

src_prepare() {
	sed \
		-e '/PROPERTIES INSTALL_RPATH/d' \
		-e '/set(CMAKE_CXX_STANDARD/d' \
		-i CMakeLists.txt
	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/openfx
		mv "${WORKDIR}"/${MY_SUP}/* "${S}"/SupportExt
		mv "${WORKDIR}"/${MY_SEQ}/* "${S}"/IOSupport/SequenceParsing
		mv "${WORKDIR}"/${MY_TIN}/* "${S}"/IOSupport/SequenceParsing/tinydir
	fi
	sed -s 's:#include <dlfcn.h>:&\n#include <cstddef>:' \
		-i SupportExt/glad/gladegl.cpp
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/lib/OFX/Plugins"
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=yes
	)
	cmake_src_configure
}
