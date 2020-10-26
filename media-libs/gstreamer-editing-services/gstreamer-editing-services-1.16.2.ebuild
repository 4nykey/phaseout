# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{6,7,8} )

inherit bash-completion-r1 gnome.org gnome2-utils python-r1 meson

DESCRIPTION="SDK for making video editors and more"
HOMEPAGE="http://wiki.pitivi.org/wiki/GES"
SRC_URI="https://gstreamer.freedesktop.org/src/${PN}/${P}.tar.xz"

LICENSE="LGPL-2+"
SLOT="1.0"
KEYWORDS="~amd64 ~x86"

IUSE="gtk-doc +introspection test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	>=dev-libs/glib-2.40.0:2
	dev-libs/libxml2:2
	dev-python/pygobject:3[${PYTHON_USEDEP}]
	>=media-libs/gstreamer-${PV}:1.0[introspection?]
	>=media-libs/gst-plugins-base-${PV}:1.0[introspection?]
	introspection? ( >=dev-libs/gobject-introspection-0.9.6:= )
"
DEPEND="
	${RDEPEND}
"
BDEPEND="
	virtual/pkgconfig
	gtk-doc? ( dev-util/gtk-doc )
"
# XXX: tests do pass but need g-e-s to be installed due to missing
# AM_TEST_ENVIRONMENT setup.
RESTRICT="test"

src_configure() {
	local emesonargs=(
		-Dpygi-overrides-dir=''
		$(meson_feature gtk-doc gtk_doc)
		$(meson_feature introspection)
		$(meson_feature test tests)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	pygi_install() {
		insinto $(python_get_sitedir)/gi/overrides
		doins bindings/python/gi/overrides/GES.py
		python_optimize
	}
	python_foreach_impl pygi_install
}
