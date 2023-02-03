# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/inikep/${PN}.git"
else
	MY_PV="af8518c"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/inikep/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="An efficient compressor with very fast decompression"
HOMEPAGE="https://github.com/inikep/${PN}"

LICENSE="BSD-2 GPL-2"
SLOT="0"
IUSE="static-libs"

RDEPEND=""
DEPEND="${RDEPEND}"

src_prepare() {
	sed -e '/PREFIX/s:/local::' -i {.,lib,programs}/Makefile
	sed -e "/LIBDIR/s:/\<lib\>:/$(get_libdir):" -i lib/Makefile
	default
	MAKEOPTS+="
		BUILD_STATIC=$(usex static-libs)
	"
}

src_compile() {
	tc-env_build emake all
}
