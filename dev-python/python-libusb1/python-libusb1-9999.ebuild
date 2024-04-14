# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
inherit distutils-r1
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/vpelletier/${PN}.git"
else
	MY_PV="${PV}"
	[[ -z ${PV%%*_p*} ]] && MY_PV="3d49a5a"
	SRC_URI="
		mirror://githubcl/vpelletier/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
fi

DESCRIPTION="Python ctype-based wrapper around libusb1"
HOMEPAGE="https://github.com/vpelletier/${PN}"

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE=""

RDEPEND="
	virtual/libusb:1
"
DEPEND="
	${RDEPEND}
"
