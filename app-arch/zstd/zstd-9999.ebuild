# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake-multilib toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/facebook/${PN}.git"
else
	MY_PV="8e43f53"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/facebook/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi
CMAKE_USE_DIR="${S}/build/cmake"

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

src_configure() {
	local mycmakeargs=(
		-DZSTD_BUILD_CONTRIB=$(multilib_native_usex contrib)
		-DZSTD_BUILD_STATIC=$(usex static-libs)
		-DZSTD_PROGRAMS_LINK_SHARED=$(usex !static-libs)
		-DZSTD_LZMA_SUPPORT=$(usex lzma)
		-DZSTD_LZ4_SUPPORT=$(multilib_native_usex lz4)
		-DZSTD_MULTITHREAD_SUPPORT=$(usex threads)
		-DZSTD_ZLIB_SUPPORT=$(usex zlib)
	)
	cmake-multilib_src_configure
}
