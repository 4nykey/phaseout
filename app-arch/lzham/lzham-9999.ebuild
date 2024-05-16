# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN}_codec"
inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/richgel999/${MY_PN}.git"
else
	MY_PV="d379b1f"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v$(ver_rs 1-2 '_')_stable1"
	SRC_URI="
		mirror://githubcl/richgel999/${MY_PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${MY_PN}-${MY_PV#v}"
fi

DESCRIPTION="Lossless Data Compression Codec"
HOMEPAGE="https://github.com/richgel999/lzham_codec"

LICENSE="public-domain"
SLOT="0"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}"
PATCHES=( "${FILESDIR}"/build.diff )
