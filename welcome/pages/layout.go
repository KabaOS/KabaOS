package pages

import (
	"os"
	"strings"

	"github.com/arthurmelton/KabaOS/welcome/window"
	"github.com/diamondburned/gotk4/pkg/gio/v2"
	"github.com/diamondburned/gotk4/pkg/glib/v2"
	"github.com/diamondburned/gotk4/pkg/gtk/v4"
)

type layout struct {
	code string
	name string
}

type variant struct {
	code   string
	layout string
	name   string
}

var dat, _ = os.ReadFile("/usr/share/X11/xkb/rules/base.lst") // should never fail if we are running on KabaOS
var layouts = getLayouts(string(dat))
var variants = getVariants(string(dat))

var selected = struct {
	a uint
	b uint
}{
	getId("us"),
	0,
}

func Layout(w *window.Welcome, increase bool) {
	screen := gtk.NewBox(gtk.OrientationVertical, 0)

	layoutListSize := uint(0)
	layoutList := gtk.NewStringList([]string{})

	layout := gtk.NewDropDown(&layoutList.ListModel, nil)

	language := gtk.NewDropDownFromStrings(getNames())
	language.Connect("notify::selected", func() {
		variantNames := getVariantNames(layouts[language.Selected()].code)
		layoutList.Splice(0, layoutListSize, variantNames)
		layoutListSize = uint(len(variantNames))
		selected.a = language.Selected()
		layout.SetSelected(0)
	})

	layout.Connect("notify::selected", func() {
		updateLayout(getLayoutString(layouts[language.Selected()].code, getVariantNames(layouts[language.Selected()].code)[layout.Selected()]))
		selected.b = layout.Selected()
	})

	tmpb := selected.b
	language.SetSelected(selected.a)
	layout.SetSelected(tmpb)

	screen.Append(language)
	screen.Append(layout)

	w.Window.SetTitle("Select a keyboard layout")
	w.Window.SetChild(screen)
}

func getLayouts(base string) []layout {
	inside, returns := false, []layout{}
	for _, line := range strings.Split(base, "\n") {
		if line == "" {
			inside = false
		}

		if inside {
			feilds := strings.Fields(line)

			returns = append(returns, layout{
				code: feilds[0],
				name: strings.Join(feilds[1:], " "),
			})
		}

		if line == "! layout" {
			inside = true
		}
	}
	return returns
}

func getVariants(base string) []variant {
	inside, returns := false, []variant{}
	for _, line := range strings.Split(base, "\n") {
		if line == "" {
			inside = false
		}

		if inside {
			feilds := strings.Fields(line)

			returns = append(returns, variant{
				code:   feilds[0],
				layout: feilds[1][:len(feilds[1])-1],
				name:   strings.Join(feilds[2:], " "),
			})
		}

		if line == "! variant" {
			inside = true
		}
	}
	return returns
}

func getId(code string) uint {
	for i := range layouts {
		if layouts[i].code == code {
			return uint(i)
		}
	}
	return 0
}

func getNames() []string {
	result := []string{}
	for i := range layouts {
		result = append(result, layouts[i].name)
	}
	return result
}

func getLayoutCode(search string) string {
	for i := range layouts {
		if layouts[i].name == search {
			return layouts[i].code
		}
	}
	return "" // should never happen
}

func getVariantNames(code string) []string {
	result := []string{"Default"}
	for i := range variants {
		if variants[i].layout == code {
			result = append(result, variants[i].name)
		}
	}
	return result
}

func getLayoutString(layout string, variant string) string {
	for i := range variants {
		if variants[i].name == variant {
			return layout + "+" + variants[i].code
		}
	}
	return layout
}

func updateLayout(name string) {
	g := gio.NewSettings("org.gnome.desktop.input-sources")
	g.SetValue("sources", glib.NewVariantArray(glib.NewVariantType("(ss)"), []*glib.Variant{glib.NewVariantTuple([]*glib.Variant{glib.NewVariantString("xkb"), glib.NewVariantString(name)})}))
}
