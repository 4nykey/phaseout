# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://codeberg.org/tenacityteam/${PN}.git"
else
	MY_PV="3df1882"
	[[ -n ${PV%%*_p*} ]] && MY_PV="${PV}"
	SRC_URI="
		https://codeberg.org/tenacityteam/${PN}/archive/${MY_PV}.tar.gz
		-> ${P}-codeberg.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}"
fi

DESCRIPTION="The MAD id3tag library, Tenacity fork"
HOMEPAGE="https://codeberg.org/tenacityteam/${PN}"

LICENSE="GPL-2"
SLOT="0/${PV%_*}"
IUSE="static-libs"

RDEPEND="sys-libs/zlib[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"
