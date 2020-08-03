# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit cmake flag-o-matic python-single-r1
MY_PN="OpenColorIO"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/AcademySoftwareFoundation/${MY_PN}.git"
else
	MY_PV="ebdec41"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/AcademySoftwareFoundation/${MY_PN}/tar.gz/${MY_PV}
		-> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV#v}"
fi

DESCRIPTION="A color management framework for visual effects and animation"
HOMEPAGE="https://opencolorio.org/"

LICENSE="BSD"
SLOT="0"
IUSE="cpu_flags_x86_sse2 doc opengl python static-libs test"
REQUIRED_USE="
	doc? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
"
RESTRICT+=" test"

RDEPEND="
	opengl? (
		media-libs/lcms:2
		media-libs/openimageio
		media-libs/glew:=
		media-libs/freeglut
		virtual/opengl
	)
	python? ( ${PYTHON_DEPS} )
	>=dev-cpp/yaml-cpp-0.5
	dev-libs/tinyxml
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	doc? (
		$(python_gen_cond_dep '
			dev-python/sphinx[${PYTHON_MULTI_USEDEP}]
		')
		dev-texlive/texlive-latex
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-1.1.0-use-GNUInstallDirs-and-fix-cmake-install-location.patch"
	"${FILESDIR}/${PN}-1.1.0-remove-building-of-bundled-programs.patch"
	"${FILESDIR}/${PN}-1.1.0-yaml-cpp-0.6.patch"
	"${FILESDIR}/${PN}-1.1.0-remove-Werror.patch"
	"${FILESDIR}"/${PN}-1.1.1-docs.diff
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	sed -e '/-Werror/d' -i src/core/CMakeLists.txt
	cmake_src_prepare

	use python || return
	python_fix_shebang .
	local _s=$(python_get_sitedir)
	sed \
		-e "/set(PYTHON_VARIANT_PATH/ s:\".*\":\"${_s#*/usr/}\":" \
		-i share/cmake/OCIOMacros.cmake
}

src_configure() {
	# Missing features:
	# - Truelight and Nuke are not in portage for now, so their support are disabled
	# - Java bindings was not tested, so disabled
	# Notes:
	# - OpenImageIO is required for building ociodisplay and ocioconvert (USE opengl)
	# - OpenGL, GLUT and GLEW is required for building ociodisplay (USE opengl)
	local mycmakeargs=(
		-DOCIO_BUILD_JNIGLUE=OFF
		-DOCIO_BUILD_NUKE=OFF
		-DOCIO_BUILD_SHARED=ON
		-DOCIO_BUILD_STATIC=$(usex static-libs)
		-DOCIO_STATIC_JNIGLUE=OFF
		-DOCIO_BUILD_TRUELIGHT=OFF
		-DUSE_EXTERNAL_LCMS=ON
		-DUSE_EXTERNAL_TINYXML=ON
		-DUSE_EXTERNAL_YAML=ON
		-DOCIO_BUILD_DOCS=$(usex doc)
		-DOCIO_BUILD_APPS=$(usex opengl)
		-DOCIO_BUILD_PYGLUE=$(usex python)
		-DOCIO_USE_SSE=$(usex cpu_flags_x86_sse2)
		-DOCIO_BUILD_TESTS=$(usex test)
	)
	cmake_src_configure
}