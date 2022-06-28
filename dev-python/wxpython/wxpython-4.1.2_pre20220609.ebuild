# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..10} )
PYTHON_REQ_USE="threads(+)"
VIRTUALX_REQUIRED="test"
DISTUTILS_IN_SOURCE_BUILD=1

MY_PN="wxPython"
if [[ -n ${PV%%*_p*} ]]; then
	MY_P="${MY_PN}-${PV}"
	SRC_URI="mirror://pypi/${P:0:1}/${MY_PN}/${MY_P}.tar.gz"
else
	MY_PV="$(ver_cut 1-3)a1.dev5434+7d45ee6a"
	MY_P="${MY_PN}-${MY_PV}"
	SRC_URI="
		https://wxpython.org/Phoenix/snapshot-builds/${MY_P}.tar.gz
		apidocs? (
			https://wxpython.org/Phoenix/snapshot-builds/${MY_PN}-docs-${MY_PV}.tar.gz
		)
	"
fi
S="${WORKDIR}/${MY_P}"
inherit distutils-r1 eutils virtualx

DESCRIPTION="A blending of the wxWindows C++ class library with Python"
HOMEPAGE="https://www.wxpython.org"

LICENSE="wxWinLL-3.1 LGPL-2"
SLOT="4.0"
KEYWORDS="~amd64 ~x86"
IUSE="apidocs debug examples libnotify opengl test"

RDEPEND="
	~x11-libs/wxGTK-3.1.7:3.1=[gstreamer,webkit,libnotify=,opengl?,tiff,X]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	app-doc/doxygen
	>=dev-python/sip-6.6:5[${PYTHON_USEDEP}]
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
	"${FILESDIR}"/cflags.diff
	# sip-6.6
	"${FILESDIR}"/90171ba.patch
)
EPYTEST_DESELECT=(
	unittests/test_asserts.py::asserts_Tests::test_asserts2
	unittests/test_asserts.py::asserts_Tests::test_asserts3
	unittests/test_display.py::display_Tests::test_display
	unittests/test_frame.py::frame_Tests::test_frameRestore
	unittests/test_gbsizer.py::gbsizer_Tests::test_gbsizer_sizer2
	unittests/test_lib_agw_ultimatelistctrl.py::lib_agw_ultimatelistctrl_Tests::test_lib_agw_ultimatelistctrlCtorIcon
	unittests/test_lib_calendar.py::lib_calendar_Tests
	unittests/test_lib_busy.py::lib_busy_Tests
	unittests/test_lib_buttons.py::lib_buttons_Tests
	unittests/test_lib_pubsub_provider.py::lib_pubsub_Except::test1
	unittests/test_lib_pubsub_topicmgr.py::lib_pubsub_TopicMgr2_GetOrCreate_DefnProv::test20_UseProvider
	unittests/test_sound.py::sound_Tests
	unittests/test_utils.py::utils_Tests::test_utilsSomeOtherStuff
	unittests/test_windowid.py::IdManagerTest::test_newIdRef03
)
distutils_enable_tests pytest

pkg_setup() {
	WAF_BINARY="${S%/*}/${WAF_BINARY}/waf"
	use apidocs && HTML_DOCS=( ../${MY_PN}-docs-${MY_PV}/docs/html/. )
	use examples && DOCS+=( demo samples )
	python_setup
}

python_prepare_all() {
	sed -e '/attrdict/d' -i buildtools/config.py

	distutils-r1_python_prepare_all
}

python_compile() {
	local -x DOXYGEN="/usr/bin/doxygen" \
		WX_CONFIG="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.1"
	local _args=(
		--python="${PYTHON}"
		--$(usex debug debug release)
		--gtk3
		--use_syswx
		--no_magic
		--jobs=$(makeopts_jobs)
		--verbose
	)
	${PYTHON} ./build.py dox etg sip --nodoc || die
	CC="$(tc-getCC) ${CFLAGS}" \
	CXX="$(tc-getCXX) ${CXXFLAGS}" \
		${PYTHON} ./build.py build_py "${_args[@]}" || die
}

python_test() {
	virtx epytest unittests
}

python_install() {
	distutils-r1_python_install --skip-build
}

python_install_all() {
	distutils-r1_python_install_all
	use examples && docompress -x /usr/share/doc/${PF}/{demo,samples}
}
