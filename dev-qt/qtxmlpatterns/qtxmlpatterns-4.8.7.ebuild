# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit qt4-build-multilib

DESCRIPTION="The XmlPatterns module for the Qt toolkit"

if [[ ${QT4_BUILD_TYPE} == release ]]; then
	KEYWORDS="~amd64 ~x86"
fi

IUSE=""

DEPEND="
	~dev-qt/qtcore-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
"
RDEPEND="${DEPEND}"

QT4_TARGET_DIRECTORIES="
	src/xmlpatterns
	tools/xmlpatterns
	tools/xmlpatternsvalidator"

QCONFIG_ADD="xmlpatterns"
QCONFIG_DEFINE="QT_XMLPATTERNS"
PATCHES=( "${FILESDIR}"/qt-everywhere-opensource-src-4.8.7-gcc6.patch )

multilib_src_configure() {
	local myconf=(
		-xmlpatterns
	)
	qt4_multilib_src_configure
}
