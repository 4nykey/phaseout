# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/conor42/${PN}.git"
else
	MY_PV="ded964d"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/conor42/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="Fast LZMA2 Library"
HOMEPAGE="https://github.com/conor42/${PN}"

LICENSE="BSD GPL-2"
SLOT="0"
IUSE="test"

RDEPEND=""
DEPEND="${RDEPEND}"

src_prepare() {
	sed -e 's,CFLAGS:=,CFLAGS+=,' \
		-e '/\$(MAKE)/d' \
		-e 's,test:libfast-lzma2,test:,' \
		-i Makefile
	default
}

src_compile() {
	tc-env_build emake CC=$(tc-getCC)
	use test && emake -C test CC=$(tc-getCC)
}

src_install() {
	local _l="libfast-lzma2.so.1.0" _d="/usr/$(get_libdir)"
	dolib.so ${_l}
	dosym ${_l} ${_d}/${_l%.*}
	dosym ${_l} ${_d}/${_l%%.*}.so
	doheader fast-lzma2.h fl2_errors.h
	einstalldocs
}
