# Copyright 1999-2018 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{5,6,7} )
SLOT="2"

inherit cmake-utils llvm python-r1

if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://code.qt.io/pyside/pyside-setup.git"
	EGIT_BRANCH="5.11"
	EGIT_SUBMODULES=()
	KEYWORDS=""
	S=${WORKDIR}/${P}/sources/${PN}${SLOT}
	# Minimum version of Qt required.
	QT_PV="${EGIT_BRANCH}:5"
else
	MY_P="pyside-setup-everywhere-src-${PV}"
	SRC_URI="
		http://download.qt.io/official_releases/QtForPython/pyside2/PySide2-${PV}-src/${MY_P}.tar.xz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S=${WORKDIR}/${MY_P}/sources/${PN}${SLOT}
	QT_PV="${PV%.*}:5"
fi

DESCRIPTION="Tool for creating Python bindings for C++ libraries"
HOMEPAGE="https://wiki.qt.io/PySide2"

# The "sources/shiboken2/libshiboken" directory is triple-licensed under the GPL
# v2, v3+, and LGPL v3. All remaining files are licensed under the GPL v3 with
# version 1.0 of a Qt-specific exception enabling shiboken2 output to be
# arbitrarily relicensed. (TODO)
LICENSE="|| ( GPL-2 GPL-3+ LGPL-3 ) GPL-3"
IUSE="numpy test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	${PYTHON_DEPS}
	dev-libs/libxml2
	dev-libs/libxslt
	>=dev-qt/qtcore-${QT_PV}
	>=dev-qt/qtxml-${QT_PV}
	>=dev-qt/qtxmlpatterns-${QT_PV}
	>=sys-devel/clang-3.9.1:=
	numpy? ( dev-python/numpy[${PYTHON_USEDEP}] )
"
RDEPEND="${DEPEND}"

DOCS=( AUTHORS )

# Ensure the path returned by get_llvm_prefix() contains clang as well.
llvm_check_deps() {
	has_version "sys-devel/clang:${LLVM_SLOT}"
}

src_prepare() {
	#FIXME: File an upstream issue requesting a sane way to disable NumPy support.
	if ! use numpy; then
		sed -i -e '/get_numpy_location()/d' libshiboken/CMakeLists.txt || die
	fi

	cmake-utils_src_prepare
}

src_configure() {
	configuration() {
		local mycmakeargs=(
			-DBUILD_TESTS=$(usex test)
			-DPYTHON_EXECUTABLE="${PYTHON}"
			-DPYTHON_SITE_PACKAGES="$(python_get_sitedir)"
		)
		use prefix && mycmakeargs+=(
			-DCMAKE_SKIP_BUILD_RPATH=FALSE
			-DCMAKE_BUILD_WITH_INSTALL_RPATH=FALSE
			-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE
		)
		# CMakeLists.txt expects LLVM_INSTALL_DIR as an environment variable.
		LLVM_INSTALL_DIR="$(get_llvm_prefix)" cmake-utils_src_configure
	}
	python_foreach_impl configuration
}

src_compile() {
	python_foreach_impl cmake-utils_src_compile
}

src_test() {
	python_foreach_impl cmake-utils_src_test
}

src_install() {
	installation() {
		cmake-utils_src_install
		mv "${ED}"usr/$(get_libdir)/pkgconfig/${PN}2{,-${EPYTHON}}.pc || die
	}
	python_foreach_impl installation
}
