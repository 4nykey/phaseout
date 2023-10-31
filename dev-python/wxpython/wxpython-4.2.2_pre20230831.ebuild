# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_IN_SOURCE_BUILD="1"
PYTHON_COMPAT=( python3_{10..11} )
DISTUTILS_EXT=1
PYPI_PN="wxPython"
VIRTUALX_REQUIRED="test"

inherit pypi distutils-r1 multiprocessing virtualx
if [[ -n ${PV%%*_p*} ]]; then
	MY_P="${PYPI_PN}-${PV}"
	SRC_URI="
		$(pypi_sdist_url --no-normalize)
		https://github.com/wxWidgets/Phoenix/releases/download/${MY_P}/${MY_P}.tar.gz
		apidocs? (
			https://extras.wxpython.org/${PYPI_PN}4/extras/${PV}/${PYPI_PN}-docs-${PV}.tar.gz
		)
	"
else
	MY_PV="$(ver_cut 1-3)a1.dev5626+a1184286"
	MY_P="${PYPI_PN}-${MY_PV}"
	SRC_URI="
		https://wxpython.org/Phoenix/snapshot-builds/${MY_P}.tar.gz
		apidocs? (
			https://wxpython.org/Phoenix/snapshot-builds/${PYPI_PN}-docs-${MY_PV}.tar.gz
		)
	"
	RESTRICT="primaryuri"
fi
S="${WORKDIR}/${MY_P}"

DESCRIPTION="A blending of the wxWindows C++ class library with Python"
HOMEPAGE="https://www.wxpython.org"

LICENSE="wxWinLL-3.1 LGPL-2"
SLOT="4.0"
KEYWORDS="~amd64 ~x86"
IUSE="apidocs debug examples libnotify opengl test webkit"

RDEPEND="
	x11-libs/wxGTK:3.2=[gstreamer,webkit?,libnotify=,opengl?,tiff,X]
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	app-doc/doxygen
	>=dev-python/sip-6.6.2:5[${PYTHON_USEDEP}]
	dev-python/cython[${PYTHON_USEDEP}]
	test? (
		${VIRTUALX_DEPEND}
		dev-python/appdirs[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
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
)
EPYTEST_DESELECT=(
	unittests/test_asserts.py::asserts_Tests::test_asserts2
	unittests/test_asserts.py::asserts_Tests::test_asserts3
	unittests/test_gbsizer.py::gbsizer_Tests::test_gbsizer_sizer2
	unittests/test_windowid.py::IdManagerTest::test_newIdRef03
	unittests/test_frame.py::frame_Tests::test_frameRestore
	unittests/test_lib_pubsub_provider.py::lib_pubsub_Except::test1
)
distutils_enable_tests pytest

pkg_setup() {
	use apidocs && HTML_DOCS=( ../${MY_P/-/-docs-}/docs/html/. )
	use examples && DOCS+=( demo samples )
	python_setup
	use webkit || PATCHES+=(
		"${FILESDIR}"/${PN}-4.2.0-no-webkit.patch
	)
}

python_prepare_all() {
	sed -e '/attrdict/d' -i buildtools/config.py
	rm -f unittests/test_display.py
	use webkit || rm -f unittests/test_webview.py
	cp "${FILESDIR}"/runtests.sh .
	distutils-r1_python_prepare_all
}

python_compile() {
	local -x DOXYGEN="/usr/bin/doxygen" \
		WX_CONFIG="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.2"
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
	virtx source ./runtests.sh
}

python_install() {
	distutils-r1_python_install --skip-build
}

python_install_all() {
	distutils-r1_python_install_all
	use examples && docompress -x /usr/share/doc/${PF}/{demo,samples}
}
