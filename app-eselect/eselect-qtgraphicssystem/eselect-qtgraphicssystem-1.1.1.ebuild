# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="Utility to change the active Qt Graphics System"
HOMEPAGE="https://github.com/gentoo/eselect-qtgraphicssystem"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND=">=app-admin/eselect-1.2.4"
S="${WORKDIR}"

src_install() {
	insinto /usr/share/eselect/modules
	doins "${FILESDIR}"/qtgraphicssystem.eselect
}
