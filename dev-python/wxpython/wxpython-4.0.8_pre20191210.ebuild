# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )
PYTHON_REQ_USE="threads(+)"
VIRTUALX_REQUIRED="test"
DISTUTILS_IN_SOURCE_BUILD=0

MY_PN="wxPython"
MY_PV="95c3c7d"
[[ -n ${PV%%*_p*} ]] && MY_PV="wxPython-${PV}"
# wxGTK version and corresponding ext/wxwidgets submodule commit or tag
WXV=( 3.0.5.1 v3.0.5.1 )
# build.py: 'wafCurrentVersion'
WAF_BINARY="waf-2.0.8"
inherit distutils-r1 eutils wxwidgets vcs-snapshot virtualx

DESCRIPTION="A blending of the wxWindows C++ class library with Python"
HOMEPAGE="https://wiki.wxpython.org/ProjectPhoenix"
SRC_URI="
	mirror://githubcl/wxWidgets/Phoenix/tar.gz/${MY_PV}
	-> ${P}.tar.gz
	mirror://githubcl/wxWidgets/wxWidgets/tar.gz/${WXV[1]}
	-> wxGTK-${WXV}.tar.gz
	https://waf.io/${WAF_BINARY}.tar.bz2
"
RESTRICT="primaryuri"

LICENSE="wxWinLL-3.1 LGPL-2"
SLOT="4.0"
KEYWORDS="~amd64 ~x86"
IUSE="apidocs examples gtk3 libnotify opengl test"

RDEPEND="
	dev-lang/python-exec:2[${PYTHON_USEDEP}]
	gtk3? (
		>=x11-libs/wxGTK-${WXV}:3.0-gtk3[gstreamer,webkit,libnotify=,opengl?,tiff,X]
	)
	!gtk3? (
		>=x11-libs/wxGTK-${WXV}:3.0[gstreamer,libnotify=,opengl?,tiff,X]
	)
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	>=dev-python/sip-4.19.16[${PYTHON_USEDEP}]
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
	docs/{classic_vs_phoenix,MigrationGuide}.rst
)
PATCHES=(
	"${FILESDIR}"/fix-ftbfs-sip-4.19.23.patch
	"${FILESDIR}"/sphinx3.diff
)

pkg_setup() {
	WX_GTK_VER="3.0$(usex gtk3 '-gtk3' '')"
	WAF_BINARY="${WORKDIR}/${WAF_BINARY}/waf"
	use apidocs && HTML_DOCS=( docs/html/. )
	use examples && DOCS+=( demo samples )
	python_setup
	setup-wxwidgets
}

python_prepare_all() {
	default
	rm -rf ext/wxWidgets sip/siplib
	ln -s "${WORKDIR}"/wxGTK-${WXV} ext/wxWidgets
	sed -e "/revhash  = /s:=.*:= '${MY_PV}':" -i sphinxtools/postprocess.py

	# unbundle sip
	rm -f wx/include/wxPython/sip.h
	grep -rl wx\.siplib | xargs sed -e 's:wx\.siplib:sip:g' -i
	sed \
		-e '/SIP_MODULE_BASENAME/s:siplib:sip:' \
		-e '/copy_file(.*sip\.h/,/makeExtCopyRule(.*siplib/d' \
		-e '/updateLicenseFiles(cfg)/d' \
		-i wscript

	SIP=/usr/bin/sip DOXYGEN=/usr/bin/doxygen \
		${EPYTHON} ./build.py dox etg sip \
		$(usex apidocs 'sphinx' '--nodoc') || die

	unset PATCHES
	distutils-r1_python_prepare_all
}

mywaf() {
	local _cmd="${@}"
	local wafargs=(
		--verbose
		--jobs=$(makeopts_jobs)
		--prefix="${EPREFIX}/usr"
		--libdir="${EPREFIX}/usr/$(get_libdir)"
		--out="${BUILD_DIR}"
		--python="${PYTHON}"
		--wx_config="${WX_CONFIG}"
		--no_magic
		--gtk$(usex gtk3 3 2)
	)
	set -- ${PYTHON} "${WAF_BINARY}" "${wafargs[@]}" "${_cmd}"
	einfo "${@}"
	"${@}" || die "${_cmd} failed"
}

python_configure() {
	mywaf configure
}

python_compile() {
	mywaf build
}

python_test() {
	virtx ${EPYTHON} ./build.py \
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
