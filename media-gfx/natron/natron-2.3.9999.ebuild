# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )
_PYTHON_ALLOW_PY27=1
MY_PN="${PN^}"
MY_OC="OpenColorIO-Configs-557b981"
inherit flag-o-matic qmake-qt4 python-single-r1 toolchain-funcs xdg
if [[ -z ${PV%%*9999} ]]; then
	EGIT_REPO_URI="https://github.com/NatronGitHub/${MY_PN}.git"
	EGIT_BRANCH="RB-${PV%.*}"
	inherit git-r3
else
	MY_PV="e496f33"
	if [[ -n ${PV%%*_p*} ]]; then
		inherit eapi7-ver
		MY_PV="v$(ver_rs 3 '-')"
	fi
	MY_OFX='openfx-8326878'
	MY_SEQ='SequenceParsing-2016fb2'
	MY_TIN='tinydir-3aae922'
	MY_MCK='google-mock-17945db'
	MY_TST='google-test-50d6fc3'
	SRC_URI="
		mirror://githubcl/NatronGitHub/${MY_PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OC%-*}/tar.gz/${MY_OC##*-}
		-> ${MY_OC}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_OFX%-*}/tar.gz/${MY_OFX##*-}
		-> ${MY_OFX}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_SEQ%-*}/tar.gz/${MY_SEQ##*-}
		-> ${MY_SEQ}.tar.gz
		mirror://githubcl/NatronGitHub/${MY_TIN%-*}/tar.gz/${MY_TIN##*-}
		-> ${MY_TIN}.tar.gz
		test? (
			mirror://githubcl/NatronGitHub/${MY_MCK%-*}/tar.gz/${MY_MCK##*-}
			-> ${MY_MCK}.tar.gz
			mirror://githubcl/NatronGitHub/${MY_TST%-*}/tar.gz/${MY_TST##*-}
			-> ${MY_TST}.tar.gz
		)
	"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV#v}"
fi
RESTRICT="primaryuri"

DESCRIPTION="Open-source video compositing software"
HOMEPAGE="http://natrongithub.github.io"

LICENSE="GPL-2+ doc? ( CC-BY-SA-4.0 )"
SLOT="0"
IUSE="c++11 debug doc gmic openmp pch test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	dev-libs/boost:=
	media-libs/fontconfig
	dev-libs/expat
	x11-libs/cairo
	$(python_gen_cond_dep '
		dev-python/pyside:0[X,opengl,${PYTHON_MULTI_USEDEP}]
		dev-python/shiboken:0[${PYTHON_MULTI_USEDEP}]
	')
"
DEPEND="
	${RDEPEND}
	doc? ( dev-python/sphinx )
"
RDEPEND="
	${RDEPEND}
	media-plugins/openfx-io
	media-plugins/openfx-misc
	media-plugins/openfx-arena
	gmic? ( media-plugins/openfx-gmic )
"

pkg_pretend() {
	use openmp && tc-check-openmp
}

src_unpack() {
	if [[ -z ${PV%%*9999} ]]; then
		git-r3_src_unpack
		EGIT_BRANCH= \
		EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_OC}" \
		EGIT_REPO_URI="https://github.com/NatronGitHub/${MY_OC%-*}.git" \
			git-r3_src_unpack
	else
		default
	fi
}

src_prepare() {
	use pch && append-flags -Winvalid-pch

	default

	if [[ -n ${PV%%*9999} ]]; then
		mv "${WORKDIR}"/${MY_OFX}/* "${S}"/libs/OpenFX
		mv "${WORKDIR}"/${MY_SEQ}/* "${S}"/libs/SequenceParsing
		mv "${WORKDIR}"/${MY_TIN}/* "${S}"/libs/SequenceParsing/tinydir
		if use test; then
			mv "${WORKDIR}"/${MY_MCK}/* "${S}"/Tests/${MY_MCK%-*}
			mv "${WORKDIR}"/${MY_TST}/* "${S}"/Tests/${MY_TST%-*}
		fi
	fi
	mv "${WORKDIR}"/${MY_OC} "${S}"/OpenColorIO-Configs

	sed \
		-e "s:@PKGCONFIG@:$(tc-getPKG_CONFIG):" \
		"${FILESDIR}"/config.pri > "${S}"/config.pri

	sed \
		-e '/X11.*fonts/d' \
		-e '/-Wl,-rpath/d' \
		-e "/\//s:\<lib\>:$(get_libdir):" \
		-e "s:\([^-]\)pkg-config:\1$(tc-getPKG_CONFIG):" \
		-e 's:LIBS +=.*libcairo\.a:PKGCONFIG += cairo:' \
		-i global.pri
}

src_configure() {
	local qmakeargs=(
		PREFIX=/usr
		BUILD_USER_NAME=Gentoo
		CONFIG+=custombuild
		CONFIG$(usex c++11 + -)=c++11
		CONFIG$(usex openmp + -)=openmp
		CONFIG$(usex pch - +)=nopch
		CONFIG$(usex debug - +)=noassertions
		CONFIG$(usex test - +)=notests
	)
	eqmake4 -r "${qmakeargs[@]}"
}

src_compile() {
	default
	use doc && \
		sphinx-build -b html Documentation/source html
}

src_install() {
	local DOCS=(
		{BUGS,CHANGELOG,CONTRIBUTING,README}.md CONTRIBUTORS.txt
		$(usex doc html '')
	)
	emake INSTALL_ROOT="${ED}" install
	einstalldocs
}

src_test() {
	cd "${S}"/Tests
	./Tests || die
}
