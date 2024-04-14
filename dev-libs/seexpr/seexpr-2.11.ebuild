# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
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
inherit cmake

DESCRIPTION="An embeddable expression evaluation engine"
HOMEPAGE="https://www.disneyanimation.com/technology/seexpr.html"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="apidocs"

RDEPEND="
	${PYTHON_DEPS}
"
DEPEND="
	${RDEPEND}
	apidocs? ( app-text/doxygen )
	app-alternatives/lex
	app-alternatives/yacc
"

src_prepare() {
	cmake_src_prepare
	sed \
		-e '/ADD_SUBDIRECTORY (src\/\(demos\|SeExprEditor\))/d' \
		-i CMakeLists.txt
	sed -e "s:\(share/doc/\)SeExpr:\1${PF}/html:" -i src/doc/CMakeLists.txt
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=$(usex !apidocs)
	)
	cmake_src_configure
}
