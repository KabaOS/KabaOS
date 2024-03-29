clear
rm -f /home/Kaba/.profile

export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11

export http_proxy=http://127.0.0.1:4444

startx /usr/bin/gnome-session --disable-acceleration-check &>/dev/null
