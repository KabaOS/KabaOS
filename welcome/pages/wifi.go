package pages

import (
	"github.com/arthurmelton/KabaOS/welcome/window"
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
	"net"
)

func Wifi(w *window.Welcome, increase bool) {
	connected := true
	var ief *net.Interface
	var err error

	if ief, err = net.InterfaceByName("eth0"); err != nil {
		connected = false
	} else if _, err = ief.Addrs(); err != nil {
		connected = false
	}

	if connected {
		w.Update(increase)
		return
	}

	w.Window.SetTitle("Select Wifi")

	b := gtk.NewBox(gtk.OrientationVertical, 0)
	b.Append(gtk.NewLabel("(wifi selector)"))

	w.Window.SetChild(b)
}
