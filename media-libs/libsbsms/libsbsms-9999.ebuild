# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/claytonotey/${PN}.git"
else
	MY_PV="165e537"
	[[ -n ${PV%%*_p*} ]] && MY_PV="${PV}"
	SRC_URI="
		mirror://githubcl/claytonotey/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="A library for high quality time and pitch scale modification"
HOMEPAGE="https://github.com/claytonotey/${PN}"

LICENSE="GPL-2"
SLOT="0"
IUSE="cpu_flags_x86_sse static-libs threads"

PATCHES=( "${FILESDIR}/${PN}-2.0.2-cflags.patch" )

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--enable-shared
		$(use_enable static-libs static)
		$(use_enable cpu_flags_x86_sse sse)
		$(use_enable threads multithreaded)
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete
}
