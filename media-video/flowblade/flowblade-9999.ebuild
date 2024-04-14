# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
PYTHON_REQ_USE="xml(+)"
DISTUTILS_SINGLE_IMPL=1
PLOCALES="cs de es fi fr it"
inherit plocale distutils-r1 xdg
if [[ -z ${PV%%*9999} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/jliljebl/${PN}.git"
	SRC_URI=
	MY_PV="${PV}"
else
	MY_PV="d3caf21"
	[[ -n ${PV%%*_p*} ]] && MY_PV="v${PV}"
	SRC_URI="
		mirror://githubcl/jliljebl/${PN}/tar.gz/${MY_PV} -> ${P}.tar.gz
	"
	RESTRICT="primaryuri"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="A non-linear PyGTK/MLT video editor"
HOMEPAGE="https://jliljebl.github.io/flowblade"

LICENSE="GPL-3"
SLOT="0"
IUSE="frei0r gmic ladspa"
S="${WORKDIR}/${PN}-${MY_PV#v}/${PN}-trunk"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pygobject:3[cairo,${PYTHON_USEDEP}]
		dev-python/dbus-python[${PYTHON_USEDEP}]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/python-libusb1[${PYTHON_USEDEP}]
		media-libs/mlt:0[python,sdl1(-),${PYTHON_SINGLE_USEDEP}]
	')
	gnome-base/librsvg:2[introspection]
	x11-libs/gtk+:3[introspection]
	frei0r? ( media-plugins/frei0r-plugins )
	ladspa? ( media-plugins/swh-plugins )
	gmic? ( media-gfx/gmic )
"
DEPEND="
	${RDEPEND}
"
DOCS=( AUTHORS README docs/{FAQ,KNOWN_ISSUES,RELEASE_NOTES,ROADMAP}.md )

python_prepare_all() {
	distutils-r1_python_prepare_all
	sed -e 's:share/appdata:share/metainfo:' -i setup.py
	sed -e "s:/usr/share/flowblade/:$(python_get_sitedir)/:" -i flowblade
}

src_compile() {
	rmloc() { rm -rf "${S}"/Flowblade/locale/${1}; }
	plocale_for_each_disabled_locale rmloc
	distutils-r1_src_compile
}
