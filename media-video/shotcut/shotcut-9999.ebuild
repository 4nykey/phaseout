# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit qmake-utils xdg
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/mltframework/${PN}.git"
else
	MY_PV="96a492f"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/mltframework/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	KEYWORDS="~amd64 ~x86"
	RESTRICT="primaryuri"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="A free, open source, cross-platform video editor"
HOMEPAGE="https://www.shotcut.org"

LICENSE="GPL-3+"
SLOT="0"
IUSE="jack"

BDEPEND="
	dev-qt/linguist-tools:5
"
DEPEND="
	>=media-libs/mlt-6.18.0[ffmpeg,frei0r,jack?,qt5,sdl,xml]
	dev-qt/qtdeclarative:5[widgets]
	dev-qt/qtmultimedia:5
	dev-qt/qtopengl:5
	dev-qt/qtsql:5
	dev-qt/qtwebsockets:5
	dev-qt/qtquickcontrols2:5
"
RDEPEND="
	${DEPEND}
	dev-qt/qtgraphicaleffects:5
	dev-qt/qtquickcontrols:5
"
DEPEND+="
	dev-qt/qtconcurrent:5
	dev-qt/qtx11extras:5
"

src_prepare() {
	default

	sed -i -e '/QT.*private/d' \
		src/src.pro || die
}

src_configure() {
	local myqmakeargs=(
		PREFIX="${EPREFIX}/usr"
		CONFIG+=warn_off
		SHOTCUT_VERSION="${PV}"
	)
	eqmake5 "${myqmakeargs[@]}"
}

src_install() {
	emake INSTALL_ROOT="${D}" install
	einstalldocs
}
