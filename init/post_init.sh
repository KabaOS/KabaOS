clear
rm -f /home/Kaba/.profile

export XDG_CURRENT_DESKTOP=GNOME
export ALL_PROXY=socks5://127.0.0.1:4447
export all_proxy=socks5://127.0.0.1:4447

startx /usr/bin/gnome-shell --x11 &>/dev/null
