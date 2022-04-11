# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..10} )
PYTHON_REQ_USE="threads(+)"
VIRTUALX_REQUIRED="test"
DISTUTILS_IN_SOURCE_BUILD=1

MY_PN="wxPython"
MY_PV="af8cca5"
[[ -n ${PV%%*_p*} ]] && MY_PV="wxPython-${PV}"
# wxGTK version and corresponding ext/wxwidgets submodule commit or tag
WXV=( 3.1.5_p20211026 204db7e )
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
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	app-doc/doxygen
	<dev-python/sip-6:5[${PYTHON_USEDEP}]
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
	"${FILESDIR}"/cflags.diff
)
EPYTEST_DESELECT=(
	unittests/test_asserts.py::asserts_Tests::test_asserts2
	unittests/test_asserts.py::asserts_Tests::test_asserts3
	unittests/test_display.py::display_Tests::test_display
	unittests/test_frame.py::frame_Tests::test_frameRestore
	unittests/test_gbsizer.py::gbsizer_Tests::test_gbsizer_sizer2
	unittests/test_intl.py::intl_Tests::test_intlGetString
	unittests/test_lib_agw_zoombar.py::lib_agw_zoombar_Tests::test_lib_agw_zoombarCtor
	unittests/test_lib_pubsub_provider.py::lib_pubsub_Except::test1
	unittests/test_lib_pubsub_topicmgr.py::lib_pubsub_TopicMgr2_GetOrCreate_DefnProv::test20_UseProvider
	unittests/test_sound.py::sound_Tests::test_sound2
	unittests/test_sound.py::sound_Tests::test_sound3
	unittests/test_sound.py::sound_Tests::test_sound4
	unittests/test_utils.py::utils_Tests::test_utilsSomeOtherStuff
	unittests/test_windowid.py::IdManagerTest::test_newIdRef03
	wx/py/tests/test_introspect.py::GetAttributeNamesTestCase::test_getAttributeNames
)
distutils_enable_tests pytest

pkg_setup() {
	WAF_BINARY="${S%/*}/${WAF_BINARY}/waf"
	use apidocs && HTML_DOCS=( docs/html/. )
	use examples && DOCS+=( demo samples )
	python_setup
}

python_prepare_all() {
	rm -rf ext/wxWidgets ext/nanosvg
	ln -s "${WORKDIR}"/wxGTK-${WXV} ext/wxWidgets
	ln -s "${WORKDIR}"/${MY_NS} ext/nanosvg
	sed -e "/revhash  = /s:=.*:= '${MY_PV}':" -i sphinxtools/postprocess.py

	distutils-r1_python_prepare_all
}

python_configure() {
	DOXYGEN="/usr/bin/doxygen" \
		${PYTHON} ./build.py dox etg $(usex apidocs '' '--nodoc') sip || die
}

python_compile_all() {
	use apidocs || return
	DOXYGEN="/usr/bin/doxygen" \
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
	CC="$(tc-getCC) ${CFLAGS}" \
	CXX="$(tc-getCXX) ${CXXFLAGS}" \
	DOXYGEN="/usr/bin/doxygen" \
	WAF="${WAF_BINARY}" \
	WX_CONFIG="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.1" \
		${PYTHON} ./build.py "${_args[@]}" build_py || die
}

python_test() {
	virtx epytest
}

python_install() {
	distutils-r1_python_install --skip-build
}

python_install_all() {
	distutils-r1_python_install_all
	use examples && docompress -x /usr/share/doc/${PF}/{demo,samples}
}
