package pages

import (
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

func NewBoxWith(orientation gtk.Orientation, spacing int, items []gtk.Widgetter) *gtk.Box {
    returns := gtk.NewBox(orientation, spacing)
    for i := range items {
        returns.Append(items[i])
    }
    return returns
}
