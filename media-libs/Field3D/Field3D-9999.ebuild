# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/imageworks/${PN}.git"
else
	MY_PV="0cf75ad"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/imageworks/${PN}/tar.gz/${MY_PV}
		-> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="A library for storing voxel data"
HOMEPAGE="https://opensource.imageworks.com/field3d.html"

LICENSE="BSD"
SLOT="0"
IUSE="mpi"

RDEPEND="
	>=dev-libs/boost-1.62:=
	media-libs/openexr:=
	sci-libs/hdf5:=
	mpi? ( virtual/mpi )
"
DEPEND="
	${RDEPEND}
"

src_prepare() {
	grep -rl '#include <OpenEXR' | xargs \
		sed -e '/#include </ s:OpenEXR/::' -i
	has_version '>=media-libs/openexr-3' && \
		eapply "${FILESDIR}"/openexr3.diff
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DINSTALL_DOCS=OFF # Docs are not finished yet.
		-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON
		$(cmake_use_find_package mpi MPI)
		-DIlmbase_Base_Dir=/usr
	)
	cmake_src_configure
}
