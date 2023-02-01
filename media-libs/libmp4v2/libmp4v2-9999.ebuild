# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN=mp4v2
inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/enzo1982/${MY_PN}.git"
else
	MY_PV="f4af85b"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/enzo1982/${MY_PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV#v}"
fi

DESCRIPTION="A library to create, modify and read MP4 files"
HOMEPAGE="https://mp4v2.org"

LICENSE="MPL-1.1"
SLOT="0"
IUSE="static utils"

BDEPEND="
	utils? ( sys-apps/help2man )
"

PATCHES=(
	"${FILESDIR}"/${PN}-2.0.0-unsigned-int-cast.patch
)

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED=$(usex !static)
		-DBUILD_UTILS=$(usex utils)
	)
	cmake_src_configure
}
