# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..13} )
DISTUTILS_USE_PEP517=setuptools
DISTUTILS_EXT=1
PYPI_PN="wxPython"
PYPI_NO_NORMALIZE=1
VIRTUALX_REQUIRED="test"

inherit toolchain-funcs pypi distutils-r1 multiprocessing virtualx
if [[ -n ${PV%%*_p*} ]]; then
	MY_P="${PYPI_PN}-${PV}"
	SRC_URI="
		https://github.com/wxWidgets/Phoenix/releases/download/${MY_P}/${MY_P}.tar.gz
		apidocs? (
			https://extras.wxpython.org/${PYPI_PN}4/extras/${PV}/${PYPI_PN}-docs-${PV}.tar.gz
			https://wxpython.org/Phoenix/snapshot-builds/${PYPI_PN}-docs-${PV}.tar.gz
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

DESCRIPTION="A blending of the wxWindows C++ class library with Python"
HOMEPAGE="https://www.wxpython.org"
S="${WORKDIR}/${MY_P}"

LICENSE="wxWinLL-3.1 LGPL-2"
SLOT="4.0"
KEYWORDS="~amd64"
IUSE="apidocs debug examples libnotify opengl test webkit"

RDEPEND="
	x11-libs/wxGTK:3.2=[gstreamer,webkit?,libnotify=,opengl?,tiff,X]
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	app-text/doxygen
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
	"${FILESDIR}/${PN}-4.2.1-x86-time.patch"
	"${FILESDIR}/${PN}-4.2.2-setuppy.patch"
)
EPYTEST_DESELECT=(
	unittests/test_windowid.py::IdManagerTest::test_newIdRef03
	unittests/test_frame.py::frame_Tests::test_frameRestore
	unittests/test_lib_pubsub_provider.py::lib_pubsub_Except::test1
)
distutils_enable_tests pytest

pkg_setup() {
	use apidocs && HTML_DOCS=( ../${MY_P/-/-docs-}/docs/html/. )
	use examples && DOCS+=( demo samples )
	python_setup
}

python_prepare_all() {
	if use !webkit; then
		rm -f unittests/test_webview.py
		eapply "${FILESDIR}"/${PN}-4.2.0-no-webkit.patch
	fi
	cp "${FILESDIR}"/runtests.sh .

	# sip assumes unconditional C99 support since 6.8.4
	# which breaks when trying to use "sip/siplib/bool.cpp"
	# https://github.com/Python-SIP/sip/commit/29fb3df49ff37df7aab9d5666fd72de95ac9e7f8
	if has_version ">=dev-python/sip-6.8.4"; then
		sed -i '\|sip/siplib/bool\.cpp|d' wscript || die
	fi
	doxygen -u ext/wxWidgets/docs/doxygen/Doxyfile || die

	distutils-r1_python_prepare_all

	# sigh
	sed -i -e '/from buildtools/i\
sys.path.insert(0, ".")' setup.py || die

	# sigh, used only when fetching things implicitly which we definitely
	# don't want; https://bugs.gentoo.org/955593
	sed -i -e '/requests/d' build.py || die
}

python_compile() {
	local -x DOXYGEN="$(type -P doxygen)" \
		WX_CONFIG="${EPREFIX}/usr/$(get_libdir)/wx/config/gtk3-unicode-3.2"
	local _args=(
		--python=${PYTHON}
		--$(usex debug debug release)
		--gtk3
		--use_syswx
		--no_magic
		--jobs=$(makeopts_jobs)
		--verbose
	)
	DISTUTILS_ARGS=(
		--verbose
		build
		--buildpy-options="build_py ${_args[*]}"
	)
	# Patch will fail if copy of refreshed sip file is not restored
	# if using multiple Python implementations
	${PYTHON} ./build.py dox etg sip --nodoc || die
	cp "${S}/sip/cpp/sip_corewxAppTraits.cpp" "${S}" || die

	eapply "${FILESDIR}/${PN}-4.2.2-no-stacktrace.patch" || die

	CC="$(tc-getCC) ${CFLAGS}" \
	CXX="$(tc-getCXX) ${CXXFLAGS}" \
	distutils-r1_python_compile

	# This package's built system relies on copying extensions back
	# to source directory for setuptools to pick them up.  This is
	# hopeless.
	find -name "*$(get_modname)" -delete || die

	cp "${S}/sip_corewxAppTraits.cpp" "${S}/sip/cpp/" || die
}

python_test() {
	rm -rf wx
	virtx source ./runtests.sh
}

python_install_all() {
	distutils-r1_python_install_all
	use examples && docompress -x /usr/share/doc/${PF}/{demo,samples}
}
