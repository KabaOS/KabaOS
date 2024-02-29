package pages

import (
	"github.com/arthurmelton/KabaOS/welcome/window"
	"github.com/diamondburned/gotk4/pkg/gio/v2"
	"github.com/diamondburned/gotk4/pkg/glib/v2"
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

func Layout(w *window.Welcome, increase bool) {
	b := gtk.NewBox(gtk.OrientationVertical, 0)
	b.Append(gtk.NewLabel("(Logo)"))
	b.Append(gtk.NewLabel("Thank you for using KabaOS!"))

	g := gio.NewSettings("org.gnome.desktop.input-sources")
	g.SetValue("sources", glib.NewVariantArray(glib.NewVariantType("(ss)"), []*glib.Variant{glib.NewVariantTuple([]*glib.Variant{glib.NewVariantString("xkb"), glib.NewVariantString("us+dvorak")})}))

	w.Window.SetTitle("Select a keyboard layout")

	w.Window.SetChild(b)
}
