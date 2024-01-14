# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NatronGitHub/${PN}.git"
else
	MY_PV="f63c273"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Natron-${PV}"
	MY_P="${PN}-${MY_PV}"
	MY_OFX='openfx-a5d9ca8'
	MY_SUP='openfx-supportext-533db0b'
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
	KEYWORDS="~amd64"
	S="${WORKDIR}/${MY_P}"
	PATCHES=( "${FILESDIR}"/gladegl.diff )
fi

DESCRIPTION="A set of Readers/Writers plugins written using the OpenFX standard"
HOMEPAGE="https://github.com/NatronGitHub/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE="+color-management ffmpeg openexr +openimageio png seexpr"

RDEPEND="
	color-management? ( <media-libs/opencolorio-2.3:= )
	openexr? ( media-libs/openexr:= )
	openimageio? ( media-libs/openimageio:=[raw] )
	ffmpeg? ( media-video/ffmpeg:= )
	png? ( media-libs/libpng:= )
	seexpr? ( dev-libs/seexpr:0 )
	media-libs/glu
"
DEPEND="${RDEPEND}"
PATCHES+=(
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
		$(cmake_use_find_package color-management OpenColorIO)
		$(cmake_use_find_package openexr OpenEXR)
		$(cmake_use_find_package ffmpeg FFmpeg)
		$(cmake_use_find_package openimageio OpenImageIO)
		$(cmake_use_find_package png PNG)
		$(cmake_use_find_package seexpr SeExpr2)
	)
	cmake_src_configure
}
