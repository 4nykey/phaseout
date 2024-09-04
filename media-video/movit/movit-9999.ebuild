# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.sesse.net/${PN}"
else
	MY_PV="7af0417"
	MY_GT="gtest-1.14.0"
	if [[ -n ${PV%%*_p*} ]]; then
		MY_PV="${PV}"
		SRC_URI="
			https://movit.sesse.net/${P}.tar.gz
		"
	else
		SRC_URI="
			https://git.sesse.net/?p=${PN};a=snapshot;h=${MY_PV};sf=tgz
			-> ${P}.tar.gz
		"
	fi
	SRC_URI+="
		https://github.com/google/googletest/archive/refs/tags/v${MY_GT##*-}.tar.gz
		-> ${MY_GT}.tar.gz
	"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV}"
	RESTRICT="primaryuri"
fi
SRC_URI+="
	demo? (
		https://home.samfundet.no/~sesse/blg_wheels_woman_1.jpg
	)
"
inherit autotools

DESCRIPTION="High-performance, high-quality video filters for the GPU"
HOMEPAGE="https://movit.sesse.net/"
IUSE="demo"

LICENSE="GPL-2+"
SLOT="0"

# no sane way to use OpenGL from within tests?
RESTRICT+=" test"

RDEPEND="
	media-libs/mesa[X(+)]
	>=dev-cpp/eigen-3.2.0:3
	media-libs/libepoxy[X]
	>=sci-libs/fftw-3:=
	demo? (
		media-libs/libsdl2[haptic]
		media-libs/sdl2-image
		media-libs/libpng
	)
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}"/${PN}-1.6.3-gcc12.patch
)

src_prepare() {
	default
	local _t="${WORKDIR}/googletest-${MY_GT##*-}/googletest"
	sed -e "/GTEST_DIR ?= /s:= .*:= ${_t}:" -i Makefile.in
	eautoreconf
	if use demo; then
		local _j=blg_wheels_woman_1.jpg
		cp "${DISTDIR}"/${_j} .
		sed \
			-e "s:\"${_j}\":\"${EPREFIX}/usr/share/movit/${_j}\":" \
			-i demo.cpp
	fi
}

src_install() {
	default
	if use demo; then
		newbin .libs/demo ${PN}-demo
		insinto /usr/share/${PN}
		doins blg_wheels_woman_1.jpg
	fi
	find "${ED}" -name '*.la' -delete
}
