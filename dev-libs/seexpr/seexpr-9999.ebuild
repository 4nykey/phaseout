# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{10..12} )
MY_PN="SeExpr"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/wdas/${MY_PN}.git"
else
	MY_PV="a5f02bb"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/wdas/${MY_PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV#v}"
fi
inherit llvm python-single-r1 cmake

DESCRIPTION="An embeddable expression evaluation engine"
HOMEPAGE="https://www.disneyanimation.com/technology/seexpr.html"

LICENSE="Apache-2.0"
SLOT="2"
IUSE="apidocs -llvm qt5 -python test utils demos cpu_flags_x86_sse4_1"
REQUIRED_USE="python? ( qt5 )"

DEPEND="
	llvm? ( sys-devel/llvm:= )
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-libs/boost:=[python,${PYTHON_USEDEP}]
			dev-python/PyQt5[opengl,${PYTHON_USEDEP}]
		')
	)
	qt5? ( dev-qt/qtopengl:5 )
"
RDEPEND="
	${DEPEND}
"
BDEPEND="
	apidocs? ( app-text/doxygen )
	python? (
		$(python_gen_cond_dep '
			dev-python/sip[${PYTHON_USEDEP}]
		')
	)
	app-alternatives/lex
	app-alternatives/yacc
"

pkg_setup() {
	use llvm && llvm_pkg_setup
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	cmake_src_prepare
	sed \
		-e '/set(CMAKE_CXX_FLAGS.*-std=c++11/d' \
		-i {src/SeExpr2/UI/,}CMakeLists.txt
	sed \
		-e 's:includedir=\${prefix}/include:&/SeExpr2:' \
		-e 's,Cflags: .*,& -I@LLVM_INCLUDE_DIR@,' \
		-i src/build/seexpr2.pc.in
}

src_configure() {
	local mycmakeargs=(
		-DENABLE_LLVM_BACKEND=$(usex llvm)
		-DENABLE_QT5=$(usex qt5)
		-DENABLE_SSE4=$(usex cpu_flags_x86_sse4_1)
		-DUSE_PYTHON=$(usex python)
		-DBUILD_UTILS=$(usex utils)
		-DBUILD_DEMOS=$(usex demos)
		-DBUILD_DOC=$(usex apidocs)
		-DBUILD_TESTS=$(usex test)
	)
	use python && mycmakeargs+=(
		-DPYQT_SIP_DIR="${EPREFIX}/usr/share/sip/PyQt5"
	)
	cmake_src_configure
}
