clear
rm -f /home/Kaba/.profile

export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11

startx /usr/bin/gnome-session &>/dev/null
