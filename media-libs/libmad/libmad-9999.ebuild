# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://codeberg.org/tenacityteam/${PN}.git"
else
	MY_PV="6abb0bc"
	[[ -n ${PV%%*_p*} ]] && MY_PV="${PV}"
	SRC_URI="
		https://codeberg.org/tenacityteam/${PN}/archive/${MY_PV}.tar.gz
		-> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}"
fi

DESCRIPTION="\"M\"peg \"A\"udio \"D\"ecoder library"
HOMEPAGE="https://codeberg.org/tenacityteam/${PN}"

LICENSE="GPL-2"
SLOT="0/${PV%_*}"
IUSE="static-libs"

DEPEND=""
RDEPEND=""
MULTILIB_WRAPPED_HEADERS=(
	/usr/include/mad.h
)

multilib_src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=$(usex !static-libs)
	)
	cmake_src_configure
}
