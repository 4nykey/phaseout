# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

RESTRICT="!test? ( test )"
inherit cmake multibuild flag-o-matic
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/nih-at/${PN}.git"
else
	MY_PV="26ba552"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/nih-at/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT+=" primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="Library for manipulating zip archives"
HOMEPAGE="https://libzip.org"

LICENSE="BSD"
SLOT="0/5"
IUSE="bzip2 gnutls lzma mbedtls ssl static-libs test tools zstd"
REQUIRED_USE="test? ( tools )"

DEPEND="
	sys-libs/zlib
	bzip2? ( app-arch/bzip2:= )
	lzma? ( app-arch/xz-utils )
	ssl? (
		gnutls? (
			dev-libs/nettle:0=
			>=net-libs/gnutls-3.6.5:=
		)
		!gnutls? (
			mbedtls? ( net-libs/mbedtls:= )
			!mbedtls? ( dev-libs/openssl:0= )
		)
	)
	zstd? ( app-arch/zstd )
"
RDEPEND="${DEPEND}"
PATCHES=( "${FILESDIR}"/zstd.diff )

pkg_setup() {
	# Upstream doesn't support building dynamic & static
	# simultaneously: https://github.com/nih-at/libzip/issues/76
	MULTIBUILD_VARIANTS=( shared $(usev static-libs) )
}

src_configure() {
	append-lfs-flags
	myconfigure() {
		local mycmakeargs=(
			-DBUILD_EXAMPLES=OFF # nothing is installed
			-DENABLE_COMMONCRYPTO=OFF # not in tree
			-DENABLE_BZIP2=$(usex bzip2)
			-DENABLE_LZMA=$(usex lzma)
			-DENABLE_ZSTD=$(usex zstd)
		)
		if [[ ${MULTIBUILD_VARIANT} = static-libs ]]; then
			mycmakeargs+=(
				-DBUILD_DOC=OFF
				-DBUILD_EXAMPLES=OFF
				-DBUILD_SHARED_LIBS=OFF
				-DBUILD_TOOLS=OFF
			)
		else
			mycmakeargs+=(
				-DBUILD_DOC=ON
				-DBUILD_REGRESS=$(usex test)
				-DBUILD_TOOLS=$(usex tools)
			)
		fi

		if use ssl; then
			if use gnutls; then
				mycmakeargs+=(
					-DENABLE_GNUTLS=$(usex gnutls)
					-DENABLE_MBEDTLS=OFF
					-DENABLE_OPENSSL=OFF
				)
			elif use mbedtls; then
				mycmakeargs+=(
					-DENABLE_GNUTLS=OFF
					-DENABLE_MBEDTLS=$(usex mbedtls)
					-DENABLE_OPENSSL=OFF
				)
			else
				mycmakeargs+=(
					-DENABLE_GNUTLS=OFF
					-DENABLE_MBEDTLS=OFF
					-DENABLE_OPENSSL=ON
				)
			fi
		else
			mycmakeargs+=(
				-DENABLE_GNUTLS=OFF
				-DENABLE_MBEDTLS=OFF
				-DENABLE_OPENSSL=OFF
			)
		fi
		cmake_src_configure
	}

	multibuild_foreach_variant myconfigure
}

src_compile() {
	multibuild_foreach_variant cmake_src_compile
}

src_test() {
	run_tests() {
		[[ ${MULTIBUILD_VARIANT} = shared ]] && cmake_src_test
	}

	multibuild_foreach_variant run_tests
}

src_install() {
	multibuild_foreach_variant cmake_src_install
}
