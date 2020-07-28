# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )
inherit cmake python-single-r1
MY_PN="oiio"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/OpenImageIO/${MY_PN}.git"
else
	MY_PV="3caf2e5"
	[[ -n ${PV%%*_p*} ]] && MY_PV="Release-${PV}"
	MY_OI="oiio-images-51ae42d"
	# src/cmake/externalpackages.cmake
	MY_RM="robin-map-0.6.2"
	SRC_URI="
		mirror://githubcl/OpenImageIO/${MY_PN}/tar.gz/${MY_PV}
		-> ${P}.tar.gz
		mirror://githubcl/Tessil/${MY_RM%-*}/tar.gz/v${MY_RM##*-}
		-> ${MY_RM}.tar.gz
		test? (
			mirror://githubcl/OpenImageIO/${MY_OI%-*}/tar.gz/${MY_OI##*-}
			-> ${MY_OI}.tar.gz
		)
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV}"
fi

DESCRIPTION="A library for reading and writing images"
HOMEPAGE="https://openimageio.org"

LICENSE="BSD"
SLOT="0/$(ver_cut 1-2)"

CPU_FEATURES=( sse2 sse3 ssse3 sse4_1 sse4_2 avx avx2 avx512f f16c aes )

IUSE="
color-management dicom doc ffmpeg field3d gif heif jpeg2k libressl opencv
opengl openvdb pdf ptex python qt5 raw test +truetype +tools webp
${CPU_FEATURES[@]/#/cpu_flags_x86_}
"
REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
	test? ( tools )
	doc? ( tools )
	pdf? ( doc )
"
RESTRICT+=" test"

BDEPEND="
	tools? (
		app-text/txt2man
	)
	doc? (
		pdf? ( dev-python/breathe )
		dev-python/sphinx_rtd_theme
		app-doc/doxygen
	)
"
DEPEND="
	>=dev-libs/boost-1.62:=
	dev-libs/pugixml:=
	>=media-libs/ilmbase-2.2.0-r1:=
	media-libs/libpng:0=
	webp? ( >=media-libs/libwebp-0.2.1:= )
	>=media-libs/openexr-2.2.0-r2:=
	media-libs/tiff:0=
	sys-libs/zlib:=
	virtual/jpeg:0
	color-management? ( media-libs/opencolorio:= )
	dicom? ( sci-libs/dcmtk )
	ffmpeg? ( media-video/ffmpeg:= )
	field3d? ( media-libs/Field3D:= )
	gif? ( media-libs/giflib:0= )
	jpeg2k? ( >=media-libs/openjpeg-1.5:0= )
	opencv? ( media-libs/opencv:= )
	opengl? (
		media-libs/glew:=
		virtual/glu
		virtual/opengl
	)
	ptex? ( media-libs/ptex:= )
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-libs/boost:=[python,${PYTHON_MULTI_USEDEP}]
			dev-python/numpy[${PYTHON_MULTI_USEDEP}]
			dev-python/pybind11[${PYTHON_MULTI_USEDEP}]
		')
	)
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtwidgets:5
		opengl? ( dev-qt/qtopengl:5 )
	)
	raw? ( media-libs/libraw:= )
	truetype? ( media-libs/freetype:2= )
	heif? ( media-libs/libheif:= )
	openvdb? ( >=media-gfx/openvdb-5 )
	dev-libs/libfmt:=
"
RDEPEND="
	${DEPEND}
	media-fonts/droid
"
DOCS=( {CHANGES,CREDITS,README}.md )
PATCHES=(
	"${FILESDIR}"/oiio-plugindir.diff
	"${FILESDIR}"/oiio-docs.diff
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	cmake_src_prepare
	mkdir -p ext
	mv "${WORKDIR}/${MY_RM}" ext/${MY_RM%-*}
	use test && mv "${WORKDIR}/${MY_OI}" "${WORKDIR}/${MY_OI%-*}"
}

src_configure() {
	# Build with SIMD support
	local cpufeature mysimd=()
	for cpufeature in "${CPU_FEATURES[@]}"; do
		use "${cpufeature/#/cpu_flags_x86_}" && mysimd+=("${cpufeature//_/.}")
	done

	# If no CPU SIMDs were used, completely disable them
	[[ -z ${mysimd} ]] && mysimd=("0")

	local mycmakeargs=(
		-DVERBOSE=ON
		-DOIIO_BUILD_TOOLS=$(usex tools)
		-DOIIO_BUILD_TESTS=$(usex test)
		-DBUILD_DOCS=$(usex tools)
		-DINSTALL_DOCS=OFF
		-DINSTALL_FONTS=OFF
		-DEMBEDPLUGINS=OFF
		-DPLUGIN_SEARCH_PATH="${EROOT}/usr/lib/${PN}"
		-DSTOP_ON_WARNING=OFF
		-DUSE_PYTHON=$(usex python)
		-DUSE_SIMD=$(local IFS=','; echo "${mysimd[*]}")
		# src/cmake/externalpackages.cmake
		-DBUILD_MISSING_DEPS=OFF
		-DUSE_JPEGTurbo=ON
		-DUSE_EXTERNAL_PUGIXML=ON
		-DUSE_Freetype=$(usex truetype)
		-DUSE_OpenColorIO=$(usex color-management)
		-DUSE_OpenCV=$(usex opencv)
		-DUSE_DCMTK=$(usex dicom)
		-DUSE_FFMPEG=$(usex ffmpeg)
		-DUSE_HDF5=$(usex field3d)
		-DUSE_Field3D=$(usex field3d)
		-DUSE_GIF=$(usex gif)
		-DUSE_Libheif=$(usex heif)
		-DUSE_LibRaw=$(usex raw)
		-DUSE_OpenJpeg=$(usex jpeg2k)
		-DUSE_TBB=$(usex openvdb)
		-DUSE_OpenVDB=$(usex openvdb)
		-DUSE_PTex=$(usex ptex)
		-DUSE_Webp=$(usex webp)
		-DUSE_Nuke=OFF # Missing in Gentoo
		-DUSE_R3DSDK=OFF # Missing in Gentoo
		-DUSE_OPENGL=$(usex opengl)
		-DUSE_QT=$(usex qt5)
		-DUSE_Qt5=$(usex qt5)
		-DUSE_EMBEDDED_LIBSQUISH=ON # Missing in Gentoo
	)
	use python && mycmakeargs+=(
		-DPYTHON_VERSION=${EPYTHON#python}
		-DPYTHON_SITE_DIR=$(python_get_sitedir)
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	use doc || return
	mkdir build
	emake -C src/doc BUILDDIR="${BUILD_DIR}" \
		sphinx $(usex pdf sphinxpdf '')
}

src_install() {
	cmake_src_install
	use tools && doman "${BUILD_DIR}"/src/doc/*.1
	use doc || return
	use pdf && dodoc build/latex/${PN}.pdf
	docinto html
	dodoc -r build/sphinx/.
}
