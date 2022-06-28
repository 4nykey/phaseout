# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg cmake
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
	>=media-libs/mlt-7.8:=[ffmpeg,frei0r,jack?,qt5,sdl,xml]
	sci-libs/fftw:=
	dev-qt/qtquickcontrols2:5
	dev-qt/qtdeclarative:5[widgets]
	dev-qt/qtwebsockets:5
	dev-qt/qtopengl:5
	dev-qt/qtsql:5
	dev-qt/qtmultimedia:5
"
RDEPEND="
	${DEPEND}
	dev-qt/qtgraphicaleffects:5
	dev-qt/qtquickcontrols:5
"
BDEPEND="
	virtual/pkgconfig
"

src_prepare() {
	cmake_src_prepare
	sed -e '/INSTALL(TARGETS/s:\<lib\>:${CMAKE_INSTALL_LIBDIR}:' \
		-i CuteLogger/CMakeLists.txt
}
