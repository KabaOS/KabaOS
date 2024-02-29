package pages

import (
	"github.com/arthurmelton/KabaOS/welcome/window"
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

func Welcome(w *window.Welcome, increase bool) {
	b := gtk.NewBox(gtk.OrientationVertical, 0)
	b.Append(gtk.NewLabel("(Logo)"))
	b.Append(gtk.NewLabel("Thank you for using KabaOS!"))

	w.Window.SetTitle("Welcome")

	w.Window.SetChild(b)
}
