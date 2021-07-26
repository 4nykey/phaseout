# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_USE_DIR="${S}/build/cmake"
inherit flag-o-matic cmake multilib-minimal toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/facebook/${PN}.git"
else
	MY_PV="a488ba1"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/facebook/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="zstd fast compression library"
HOMEPAGE="https://facebook.github.io/zstd/"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0/1"
IUSE="contrib lzma lz4 static-libs +threads zlib"

RDEPEND="
	lzma? ( app-arch/xz-utils )
	lz4? ( app-arch/lz4 )
	zlib? ( sys-libs/zlib )
"
DEPEND="${RDEPEND}"

multilib_src_configure() {
	local mycmakeargs=(
		-DZSTD_BUILD_CONTRIB=$(usex contrib)
		-DZSTD_BUILD_STATIC=$(usex static-libs)
		-DZSTD_PROGRAMS_LINK_SHARED=$(usex !static-libs)
		-DZSTD_LZMA_SUPPORT=$(usex lzma)
		-DZSTD_LZ4_SUPPORT=$(usex lz4)
		-DZSTD_MULTITHREAD_SUPPORT=$(usex threads)
		-DZSTD_ZLIB_SUPPORT=$(usex zlib)
	)
	cmake_src_configure
}

multilib_src_compile() {
	cmake_src_compile
}

multilib_src_install() {
	cmake_src_install
}
