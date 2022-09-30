# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PLOCALES="be de es he ro ru uk"
inherit plocale gnome2 cmake
MY_PN="xneur-devel"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/AndrewCrewKuznetsov/${MY_PN}.git"
	SRC_URI=""
	S="${WORKDIR}/${P}/${PN}"
else
	MY_PV="ae52f05"
	SRC_URI="
		mirror://githubcl/AndrewCrewKuznetsov/${MY_PN}/tar.gz/${MY_PV}
		-> ${MY_PN}-${MY_PV}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV}/${PN}"
fi

DESCRIPTION="GTK+ based GUI for xneur"
HOMEPAGE="https://www.xneur.ru"

LICENSE="GPL-2"
SLOT="0"
IUSE="nls"

DEPEND="
	gnome-base/libglade:2.0
	>=sys-devel/gettext-0.16.1
	>=x11-libs/gtk+-2.20:2
	~x11-misc/xneur-${PV}:${SLOT}[nls=]
	gnome-base/gconf
"
RDEPEND="
	${DEPEND}
	nls? ( virtual/libintl )
"
BDEPEND="
	virtual/pkgconfig
	dev-util/intltool
	nls? ( sys-devel/gettext )
"
PATCHES=( "${FILESDIR}"/gxneur.diff )

src_configure() {
	local mycmakeargs=(
		-DAPPINDICATOR=no
	)
	cmake_src_configure
}
