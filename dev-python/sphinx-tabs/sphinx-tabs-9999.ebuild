# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )

inherit distutils-r1
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/executablebooks/${PN}.git"
else
	MY_PV="05ddd2c"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/executablebooks/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}-${MY_PV#v}"
fi

DESCRIPTION="Tabbed views for Sphinx"
HOMEPAGE="https://sphinx-tabs.readthedocs.io"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

PDEPEND="
	dev-python/sphinx[${PYTHON_USEDEP}]
"
BDEPEND="
	test? ( dev-python/pytest-regressions[${PYTHON_USEDEP}] )
"
distutils_enable_tests pytest
