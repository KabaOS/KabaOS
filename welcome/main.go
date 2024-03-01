package main

import (
	_ "embed"
	"os"

	"github.com/arthurmelton/KabaOS/welcome/pages"
	"github.com/arthurmelton/KabaOS/welcome/window"

	"github.com/diamondburned/gotk4/pkg/gio/v2"
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

func main() {
	app := gtk.NewApplication("com.github.arthurmelton.kabaos.Welcome", gio.ApplicationFlagsNone)
	app.ConnectActivate(func() {
		w := newWelcome(app)
		w.Window.Show()
	})

	if code := app.Run(os.Args); code > 0 {
		os.Exit(code)
	}
}

func newWelcome(app *gtk.Application) *window.Welcome {
	w := window.Welcome{Application: app, Page: 0}

	w.Back = gtk.NewButtonFromIconName("go-previous")
	w.Back.Hide()
	w.Back.SetTooltipText("Back")
	w.Back.ConnectClicked(func() { w.Update(false) })

	w.Next = gtk.NewButtonFromIconName("go-next")
	w.Next.SetTooltipText("Next")
	w.Next.ConnectClicked(func() { w.Update(true) })

	w.Finish = gtk.NewButtonWithLabel("Finish")
	w.Finish.AddCSSClass("suggested-action")
	w.Finish.Hide()
	w.Finish.ConnectClicked(func() { w.Update(true) })

	w.Header = gtk.NewHeaderBar()
	w.Header.PackStart(w.Back)
	w.Header.PackEnd(w.Next)
	w.Header.PackEnd(w.Finish)

	w.Pages = []func(w *window.Welcome, increase bool){pages.Welcome, pages.Layout, pages.Wifi, pages.Finish}

	_ = gtk.NewApplicationWindow(app)

	w.Window = gtk.NewDialogWithFlags("", app.ActiveWindow(), gtk.DialogModal)
	w.Window.SetDeletable(false)
	w.Window.SetResizable(false)
	w.Window.SetDefaultSize(400, 650)
	w.Window.SetTitlebar(w.Header)

	w.Pages[w.Page](&w, true)

	return &w
}
