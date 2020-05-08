# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit qmake-utils
MY_PS="ps3muxer-f435b1a"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/clark15b/${PN}"
else
	inherit vcs-snapshot
	MY_PV="764962e"
	SRC_URI="
		mirror://githubcl/clark15b/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/clark15b/${MY_PS%-*}/tar.gz/${MY_PS##*-} -> ${MY_PS}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="AVCHD/Blu-Ray HDMV Transport Stream demultiplexer"
HOMEPAGE="https://github.com/clark15b/${PN}"

LICENSE="MIT"
SLOT="0"
IUSE="qt5"

DEPEND="
	qt5? ( dev-qt/qtgui:5 )
"
RDEPEND="
	${DEPEND}
"
PATCHES=( "${FILESDIR}"/${PN}_qt5.diff )

src_unpack() {
	if [[ -z ${PV%%*9999} ]]; then
		git-r3_src_unpack
		EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_PS}" \
		EGIT_REPO_URI="https://github.com/clark15b/${MY_PS%-*}" \
			git-r3_src_unpack
	else
		vcs-snapshot_src_unpack
	fi
}

src_prepare() {
	mv "${WORKDIR}"/${MY_PS} "${S}"/${MY_PS%-*}
	default
	tc-export CXX
	sed \
		-e "s:g++:${CXX} ${CXXFLAGS} ${LDFLAGS}:" \
		-i Makefile
	rm -f "${S}"/getopt.h
}

src_configure() {
	use qt5 || return
	cd tsDemuxGUI && eqmake5 tsDemuxGUI.pro
}

src_compile() {
	default
	use qt5 && emake -C tsDemuxGUI
}

src_install() {
	dobin tsdemux
	dodoc README
	use qt5 && dobin tsDemuxGUI/tsDemuxGUI
}
