# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake qmake-utils
KEYWORDS="~amd64"
MY_PV="3.5.3.0"
SRC_URI="
	https://files.kde.org/krita/build/dependencies/gmic-${MY_PV}.tar.gz
"
S="${WORKDIR}/gmic-v${MY_PV}/gmic-qt"

DESCRIPTION="GMIC plugin for krita"
HOMEPAGE="https://krita.org https://gmic.eu"

LICENSE="GPL-3 || ( CeCILL-C CeCILL-2 )"
SLOT="5"

RDEPEND="
	~media-gfx/krita-${PV}:${SLOT}
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	dev-qt/linguist-tools:5
"

src_configure() {
	local mycmakeargs=(
		-DGMIC_QT_HOST=krita-plugin
		-DENABLE_SYSTEM_GMIC=OFF
	)
	cmake_src_configure
}

src_compile() {
	export PATH="$(qt5_get_bindir):${PATH}"
	emake -C translations
	emake -C translations/filters
	cmake_src_compile
}
