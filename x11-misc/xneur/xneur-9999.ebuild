# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PLOCALES="be de ro ru uk"
MY_PN="xneur-devel"
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/AndrewCrewKuznetsov/${MY_PN}.git"
	S="${WORKDIR}/${P}/${PN}"
else
	MY_PV="ae52f05"
	SRC_URI="
		mirror://githubcl/AndrewCrewKuznetsov/${MY_PN}/tar.gz/${MY_PV}
		-> ${MY_PN}-${MY_PV}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_PN}-${MY_PV}/${PN}"
fi
inherit plocale cmake

DESCRIPTION="An utility for keyboard layout switching"
HOMEPAGE="https://xneur.ru"

LICENSE="GPL-2"
SLOT="0"
IUSE="alsa aspell debug enchant gstreamer keylogger libnotify nls openal xosd"

DEPEND="
	sys-libs/zlib
	x11-libs/libXi
	gstreamer? ( media-libs/gstreamer:1.0 )
	openal? ( media-libs/freealut )
	>=dev-libs/libpcre-5.0
	enchant? ( app-text/enchant:0 )
	aspell? ( app-text/aspell )
	xosd? ( x11-libs/xosd )
	libnotify? (
		>=x11-libs/libnotify-0.4.0
		x11-libs/gtk+:2
	)
"
RDEPEND="
	${DEPEND}
	alsa? ( media-sound/alsa-utils )
	gstreamer? (
		media-libs/gst-plugins-good:1.0
	)
	nls? ( virtual/libintl )
"
BDEPEND="
	virtual/pkgconfig
	dev-util/intltool
	nls? ( sys-devel/gettext )
"

REQUIRED_USE="
	?? ( gstreamer openal alsa )
	?? ( aspell enchant )
"

src_prepare() {
	sed \
		-e '/\(libdir\|DESTINATION\)/ s:\<lib\>:${CMAKE_INSTALL_LIBDIR}:' \
		-i lib/{,lib/,config/}CMakeLists.txt
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DSOUNDS=$(usex alsa aplay $(usex gstreamer gstreamer $(usex openal openal)))
		-DKEYLOGGER=$(usex keylogger)
		-DSPELL=$(usex enchant enchant $(usex aspell aspell))
		-DNOTIFICATIONS=$(usex libnotify)
		-DLOCALE_INSTALL_DIR="share/locale"
		-DMAN_INSTALL_DIR="share/man"
	)
	cmake_src_configure
}
