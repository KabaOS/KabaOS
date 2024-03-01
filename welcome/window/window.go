package window

import (
	_ "embed"
	"os"

	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

type Welcome struct {
	*gtk.Application
	Window *gtk.Dialog
	Header *gtk.HeaderBar

	Page  int
	Pages []func(w *Welcome, increase bool)

	Back   *gtk.Button
	Next   *gtk.Button
	Finish *gtk.Button
}

func (w *Welcome) Update(increase bool) {
	if increase {
		w.Page++
	} else {
		w.Page--
	}

	if w.Page == len(w.Pages) {
		os.Exit(0)
	}

	if w.Page > 0 {
		w.Back.Show()
	} else {
		w.Back.Hide()
	}

	if w.Page < len(w.Pages)-1 {
		w.Next.Show()
		w.Finish.Hide()
	} else {
		w.Next.Hide()
		w.Finish.Show()
	}

	w.Pages[w.Page](w, increase)
}
