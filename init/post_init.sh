clear
rm -f /home/Cloak/.profile

export XDG_CURRENT_DESKTOP=GNOME

startx /usr/bin/gnome-shell --x11 &>/dev/null
