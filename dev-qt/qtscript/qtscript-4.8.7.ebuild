# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit qt4-build-multilib

DESCRIPTION="The QtScript module for the Qt toolkit"

if [[ ${QT4_BUILD_TYPE} == release ]]; then
	KEYWORDS="~amd64 ~x86"
fi

IUSE="+jit"

DEPEND="
	~dev-qt/qtcore-${PV}[aqua=,debug=,${MULTILIB_USEDEP}]
"
RDEPEND="${DEPEND}"

QT4_TARGET_DIRECTORIES="src/script"

QCONFIG_ADD="script"
QCONFIG_DEFINE="QT_SCRIPT"

PATCHES=( "${FILESDIR}/4.8.7-javascriptcore.patch" )

multilib_src_configure() {
	local myconf=(
		$(qt_use jit javascript-jit)
		-no-xkb -no-fontconfig -no-xrender -no-xrandr -no-xfixes -no-xcursor -no-xinerama
		-no-xshape -no-sm -no-opengl -no-nas-sound -no-dbus -no-cups -no-nis -no-gif
		-no-libpng -no-libmng -no-libjpeg -no-openssl -system-zlib -no-webkit -no-phonon
		-no-qt3support -no-xmlpatterns -no-freetype -no-libtiff
		-no-accessibility -no-fontconfig -no-glib -no-opengl -no-svg
		-no-gtkstyle
	)
	qt4_multilib_src_configure
}
