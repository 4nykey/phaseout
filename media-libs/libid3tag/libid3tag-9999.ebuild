# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake multilib-minimal
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/audacity/${PN}.git"
else
	MY_PV="9252f26"
	[[ -n ${PV%%*_p*} ]] && MY_PV="${PV}"
	SRC_URI="
		mirror://githubcl/audacity/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="The MAD id3tag library"
HOMEPAGE="http://www.underbit.com/products/mad/"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug static-libs"

RDEPEND="sys-libs/zlib[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	>=dev-util/gperf-3.1"

PATCHES=(
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-64bit-long.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-a_capella.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-compat.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-file-write.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-fix_overflow.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-tag.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-unknown-encoding.patch
	"${FILESDIR}"/0.15.1b/${PN}-0.15.1b-utf16.patch
	"${FILESDIR}"/cmake.diff
)

multilib_src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED=$(usex !static-libs)
	)
	cmake_src_configure
}

multilib_src_compile() {
	cmake_src_compile
}

multilib_src_install() {
	cmake_src_install

	sed \
		-e "s/%VERSION%/${PV}/g" \
		-e "s:^prefix=:&${EPREFIX}:" \
		-e "/libdir=/s:\<lib\>:$(get_libdir):" \
		"${FILESDIR}"/id3tag.pc > id3tag.pc
	insinto /usr/$(get_libdir)/pkgconfig
	doins id3tag.pc
}
