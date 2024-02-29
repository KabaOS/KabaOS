package pages

import (
	"github.com/arthurmelton/KabaOS/welcome/window"
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

func Finish(w *window.Welcome, increase bool) {
	b := gtk.NewBox(gtk.OrientationVertical, 0)
	b.Append(gtk.NewLabel("Thank you for useing Kaba!"))

	w.Window.SetTitle("Thank You")

	w.Window.SetChild(b)
}
