# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/${PN}-project/${PN}.git"
else
	MY_PV="36f6b74"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v$(ver_rs 2 '-v' 5 '-R')"
	SRC_URI="
		mirror://githubcl/${PN}-project/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="Port of 7-Zip archiver for Unix"
HOMEPAGE="https://p7zip.sourceforge.net/"

LICENSE="LGPL-2.1 rar? ( unRAR )"
SLOT="0"
IUSE="asm rar"

RDEPEND="
	app-arch/brotli
	app-arch/fast-lzma2
	app-arch/lizard
	app-arch/lz4
	app-arch/lz5
	app-arch/lzham
	app-arch/zstd
"
DEPEND="${RDEPEND}"
BDEPEND="
	asm? ( dev-lang/jwasm )
"
PATCHES=( "${FILESDIR}"/system-libs.diff )

DOCS=(
	DOC/7zC.txt
	DOC/7zFormat.txt
	DOC/lzma.txt
	DOC/Methods.txt
	DOC/readme.txt
	DOC/src-history.txt
)

src_prepare() {
	default
	sed -e 's: -\(O2\|\<s\>\)::' -i CPP/7zip/7zip_gcc.mak
}

src_compile() {
	local myemakeargs=(
		7z_LIB=$(get_libdir)
		7z_ADDON_LIB_FLAG=
		CFLAGS_BASE2="${CFLAGS}"
		CXXFLAGS_BASE2="${CXXFLAGS}"
		IS_X64=1
		USE_ASM=$(usex asm 1 '')
		USE_JWASM=$(usex asm 1 '')
		O="${S}"
		DISABLE_RAR=$(usex rar '' 1)
	)
	tc-env_build emake \
		-C CPP/7zip/Bundles/Alone2 \
		-f makefile.gcc \
		"${myemakeargs[@]}"
}

src_install() {
	newbin bin/7zz 7z
	einstalldocs
}
