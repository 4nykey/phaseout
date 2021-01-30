# Copyright 1999-2021 Gentoo Authors
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
SLOT="0/2.0"
IUSE="cpu_flags_x86_sse2 doc opengl python static-libs test"
REQUIRED_USE="
	doc? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
"
RESTRICT+=" test"

RDEPEND="
	opengl? (
		media-libs/lcms:2
		media-libs/openimageio:=
		media-libs/glew:=
		media-libs/freeglut
		virtual/opengl
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			>=dev-python/pybind11-2.6.1[${PYTHON_MULTI_USEDEP}]
		')
	)
	dev-libs/expat
	dev-cpp/yaml-cpp
	media-libs/ilmbase
	dev-cpp/pystring
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

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	sed -e '/DESTINATION lib/s:\<lib\>:${CMAKE_INSTALL_LIBDIR}:' \
		-i src/OpenColorIO/CMakeLists.txt \
		src/libutils/o{iio,glapp}helpers/CMakeLists.txt
	sed -e '/-Werror/d' -i share/cmake/utils/CompilerFlags.cmake
	cmake_src_prepare
}

src_configure() {
	# Missing features:
	# - Truelight and Nuke are not in portage for now, so their support are disabled
	# - Java bindings was not tested, so disabled
	# Notes:
	# - OpenImageIO is required for building ociodisplay and ocioconvert (USE opengl)
	# - OpenGL, GLUT and GLEW is required for building ociodisplay (USE opengl)
	local mycmakeargs=(
		-DCMAKE_CONFIGURATION_TYPES=Gentoo
		-DOCIO_BUILD_NUKE=OFF
		-DOCIO_BUILD_SHARED=ON
		-DOCIO_BUILD_STATIC=$(usex static-libs)
		-DOCIO_BUILD_DOCS=$(usex doc)
		-DOCIO_BUILD_APPS=$(usex opengl)
		-DOCIO_USE_SSE=$(usex cpu_flags_x86_sse2)
		-DOCIO_BUILD_TESTS=$(usex test)
		-DOCIO_BUILD_GPU_TESTS=$(usex test)
		-DOCIO_BUILD_PYTHON=$(usex python)
	)
	use python && mycmakeargs+=(
		-DPython_EXECUTABLE=${PYTHON}
	)
	cmake_src_configure
}
