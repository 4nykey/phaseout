# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 )
_PYTHON_ALLOW_PY27=1

inherit cmake-utils multilib python-r1 virtualx

MY_P="PySide-${PV}"
DESCRIPTION="Python bindings for the Qt framework"
HOMEPAGE="http://wiki.qt.io/PySide"
SRC_URI="http://download.qt-project.org/official_releases/${PN}/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="X declarative help multimedia opengl script scripttools sql svg test webkit xmlpatterns"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	declarative? ( X )
	help? ( X )
	multimedia? ( X )
	opengl? ( X )
	scripttools? ( X script )
	sql? ( X )
	svg? ( X )
	test? ( X )
	webkit? ( X )
"

# Minimal supported version of Qt.
QT_PV="4.8.5:4"

RDEPEND="
	${PYTHON_DEPS}
	>=dev-python/shiboken-${PV}:${SLOT}[${PYTHON_USEDEP}]
	>=dev-qt/qtcore-${QT_PV}[ssl]
	X? (
		>=dev-qt/qtgui-${QT_PV}[accessibility]
		>=dev-qt/qttest-${QT_PV}
	)
	declarative? ( >=dev-qt/qtdeclarative-${QT_PV} )
	help? ( >=dev-qt/qthelp-${QT_PV} )
	multimedia? ( >=dev-qt/qtmultimedia-${QT_PV} )
	opengl? ( >=dev-qt/qtopengl-${QT_PV} )
	script? ( >=dev-qt/qtscript-${QT_PV} )
	sql? ( >=dev-qt/qtsql-${QT_PV} )
	svg? ( >=dev-qt/qtsvg-${QT_PV}[accessibility] )
	webkit? ( >=dev-qt/qtwebkit-${QT_PV} )
	xmlpatterns? ( >=dev-qt/qtxmlpatterns-${QT_PV} )
"
DEPEND="${RDEPEND}
	>=dev-qt/qtgui-${QT_PV}
"
S="${WORKDIR}/${MY_P}/sources/${PN}"

src_prepare() {
	# Fix generated pkgconfig file to require the shiboken
	# library suffixed with the correct python version.
	sed -i -e '/^Requires:/ s:\<shiboken\>:&@SHIBOKEN_PYTHON_SUFFIX@:' \
		libpyside/pyside.pc.in || die

	if use prefix; then
		cp "${FILESDIR}"/rpath.cmake . || die
		sed -i -e '1iinclude(rpath.cmake)' CMakeLists.txt || die
	fi

	eapply "${FILESDIR}/qgtkstyle-${PV}.patch" # bug 530764

	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTS="$(usex test)"
		-DDISABLE_QtGui="$(usex !X)"
		-DDISABLE_QtTest="$(usex !X)"
		-DDISABLE_QtDeclarative="$(usex !declarative)"
		-DDISABLE_QtHelp="$(usex !help)"
		-DDISABLE_QtMultimedia="$(usex !multimedia)"
		-DDISABLE_QtOpenGL="$(usex !opengl)"
		-DDISABLE_QtScript="$(usex !script)"
		-DDISABLE_QtScriptTools="$(usex !scripttools)"
		-DDISABLE_QtSql="$(usex !sql)"
		-DDISABLE_QtSvg="$(usex !svg)"
		-DDISABLE_QtWebKit="$(usex !webkit)"
		-DDISABLE_QtXmlPatterns="$(usex !xmlpatterns)"
	)

	configuration() {
		local mycmakeargs=(
			-DPYTHON_SUFFIX="-${EPYTHON}"
			"${mycmakeargs[@]}"
		)
		cmake-utils_src_configure
	}
	python_foreach_impl configuration
}

src_compile() {
	python_foreach_impl cmake-utils_src_compile
}

src_test() {
	local PYTHONDONTWRITEBYTECODE
	export PYTHONDONTWRITEBYTECODE

	python_foreach_impl virtx cmake-utils_src_test
}

src_install() {
	installation() {
		cmake-utils_src_install
		mv "${ED}"/usr/$(get_libdir)/pkgconfig/${PN}{,-${EPYTHON}}.pc || die
		python_optimize
	}
	python_foreach_impl installation
}
