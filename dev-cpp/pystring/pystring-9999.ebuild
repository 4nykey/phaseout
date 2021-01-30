# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit toolchain-funcs
if [[ "${PV}" == "9999" ]];  then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/imageworks/${PN}.git"
else
	MY_PV="281419d"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/imageworks/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="C++ functions matching the interface and behavior of python string methods"
HOMEPAGE="https://github.com/imageworks/pystring"

LICENSE="BSD"
SLOT="0"
BDEPEND="
	sys-devel/libtool
"

src_compile() {
	local emake_args=(
		CXX="$(tc-getCXX)"
		CXXFLAGS="${CXXFLAGS}"
	)
	emake "${emake_args[@]}"
}

src_install() {
	dolib.so .libs/libpystring.so*
	mkdir -p ${PN}
	cp -a ${PN}.h ${PN}
	doheader -r ${PN}
	einstalldocs
}
