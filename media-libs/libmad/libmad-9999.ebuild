# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake multilib-minimal
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/audacity/${PN}.git"
else
	MY_PV="0ff5fa8"
	[[ -n ${PV%%*_p*} ]] && MY_PV="${PV}"
	SRC_URI="
		mirror://githubcl/audacity/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="\"M\"peg \"A\"udio \"D\"ecoder library"
HOMEPAGE="http://mad.sourceforge.net"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug static-libs"

DEPEND=""
RDEPEND=""

DOCS=( CHANGES CREDITS README TODO VERSION )

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/mad.h
)

PATCHES=(
	"${FILESDIR}"/${PN}-0.15.1b-CVE-2017-8372_CVE-2017-8373_CVE-2017-8374.patch
	"${FILESDIR}"/cmake.diff
	"${FILESDIR}"/stdlib.diff
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
		"${FILESDIR}"/mad.pc > mad.pc
	insinto /usr/$(get_libdir)/pkgconfig
	doins mad.pc
}
