# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )
PYTHON_REQ_USE="threads(+)"
VIRTUALX_REQUIRED="test"
DISTUTILS_IN_SOURCE_BUILD=0

MY_PN="wxPython"
MY_PV="bfb3356"
[[ -n ${PV%%*_p*} ]] && MY_PV="wxPython-${PV}"
# wxGTK version and corresponding ext/wxwidgets submodule commit or tag
WXV=( 3.1.5_pre20201120 493cc35 )
MY_NS="nanosvg-9dd92bb"
# build.py: 'wafCurrentVersion'
WAF_BINARY="waf-2.0.19"
inherit distutils-r1 eutils vcs-snapshot virtualx

DESCRIPTION="A blending of the wxWindows C++ class library with Python"
HOMEPAGE="https://wiki.wxpython.org/ProjectPhoenix"
SRC_URI="
	mirror://githubcl/wxWidgets/Phoenix/tar.gz/${MY_PV}
	-> ${P}.tar.gz
	mirror://githubcl/wxWidgets/wxWidgets/tar.gz/${WXV[1]}
	-> wxGTK-${WXV}.tar.gz
	mirror://githubcl/wxWidgets/${MY_NS%-*}/tar.gz/${MY_NS##*-}
	-> ${MY_NS}.tar.gz
	https://waf.io/${WAF_BINARY}.tar.bz2
"
RESTRICT="primaryuri"

LICENSE="wxWinLL-3.1 LGPL-2"
SLOT="4.0"
KEYWORDS="~amd64 ~x86"
IUSE="apidocs debug examples libnotify opengl test"

RDEPEND="
	>=x11-libs/wxGTK-${WXV}:3.1=[gstreamer,webkit,libnotify=,opengl?,tiff,X]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	>=dev-python/sip-4.19.22[${PYTHON_USEDEP}]
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	app-doc/doxygen
	apidocs? ( dev-python/sphinx[${PYTHON_USEDEP}] )
	test? (
		dev-python/pytest-xdist[${PYTHON_USEDEP}]
		dev-python/pytest-timeout[${PYTHON_USEDEP}]
	)
"
DOCS=(
	{CHANGES,README,TODO}.rst
	docs/MigrationGuide.rst
)
PATCHES=(
	"${FILESDIR}"/sphinx3.diff
)

pkg_setup() {
	WAF_BINARY="${WORKDIR}/${WAF_BINARY}/waf"
	use apidocs && HTML_DOCS=( docs/html/. )
	use examples && DOCS+=( demo samples )
	python_setup
}

python_prepare_all() {
	rm -rf ext/wxWidgets ext/nanosvg sip/siplib
	ln -s "${WORKDIR}"/wxGTK-${WXV} ext/wxWidgets
	ln -s "${WORKDIR}"/${MY_NS} ext/nanosvg
	sed -e "/revhash  = /s:=.*:= '${MY_PV}':" -i sphinxtools/postprocess.py
	sed -e 's:class="\([^"]\+\)":class='\1':' -i ext/wxWidgets/docs/doxygen/Doxyfile

	# unbundle sip
	rm -f wx/include/wxPython/sip.h
	grep -rl wx\.siplib | xargs sed -e 's:wx\.siplib:sip:g' -i
	sed \
		-e '/SIP_MODULE_BASENAME/s:siplib:sip:' \
		-e '/copy_file(.*sip\.h/,/makeExtCopyRule(.*siplib/d' \
		-e '/updateLicenseFiles(cfg)/d' \
		-i wscript

	SIP="${EROOT}/usr/bin/sip" DOXYGEN="/usr/bin/doxygen" \
		${PYTHON} ./build.py dox etg $(usex apidocs '' '--nodoc') sip || die

	distutils-r1_python_prepare_all
}

python_compile_all() {
	use apidocs || return
	SIP="${EROOT}/usr/bin/sip" DOXYGEN="/usr/bin/doxygen" \
		${PYTHON} ./build.py sphinx || die
}

python_compile() {
	local _args=(
		--python="${PYTHON}"
		--$(usex debug debug release)
		--gtk3
		--use_syswx
		--no_magic
		--jobs=$(makeopts_jobs)
		--verbose
	)
	SIP="${EROOT}/usr/bin/sip" \
	DOXYGEN="/usr/bin/doxygen" \
	WAF="${WAF_BINARY}" \
	WX_CONFIG="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.1" \
		${PYTHON} ./build.py "${_args[@]}" build_py || die
}

python_test() {
	virtx ${PYTHON} ./build.py \
		--verbose --pytest_jobs=$(makeopts_jobs) test || \
		die "Tests failed with ${EPYTHON}"
}

python_install() {
	distutils-r1_python_install --skip-build
}

python_install_all() {
	distutils-r1_python_install_all
	use examples && docompress -x /usr/share/doc/${PF}/{demo,samples}
}
