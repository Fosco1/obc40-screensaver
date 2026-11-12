#!/bin/sh
# obc40-screensaver installer: installs the screensaver for the current user (no root needed).
#
#   sh install.sh                  install, start it at every XFCE login and start it now
#   sh install.sh --dim N          backlight at N% while the screensaver is shown (default 5, 0 = unchanged)
#   sh install.sh --no-autostart   install only, nothing starts at login
#   sh install.sh --uninstall      stop it and remove it
#   sh install.sh --system         as root: the power key no longer shuts the board down, and the
#                                  video group may change the backlight (add --uninstall to undo)
#
# Files: ~/.local/bin/obc-screensaver, ~/.config/autostart/obc-screensaver.desktop
# With --system: /etc/elogind/logind.conf.d/90-obc40-powerkey.conf, /etc/udev/rules.d/91-obc40-backlight.rules
set -e
SRC=$(cd "$(dirname "$0")" && pwd)
BIN="$HOME/.local/bin"
AUTOSTART_FILE="$HOME/.config/autostart/obc-screensaver.desktop"
AUTOSTART=1
UNINSTALL=0
SYSTEM=0
ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-autostart) AUTOSTART=0 ;;
    --uninstall) UNINSTALL=1 ;;
    --system) SYSTEM=1 ;;
    --dim) shift; case "$1" in ''|*[!0-9]*) echo "--dim needs a number (0-100)" >&2; exit 1 ;; esac
           ARGS=" --dim $1" ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

# --- system part (root): elogind ignores the power key, backlight writable by the video group
if [ "$SYSTEM" = 1 ]; then
  [ "$(id -u)" = 0 ] || { echo "--system must be run as root" >&2; exit 1; }
  LOGIND_CONF=/etc/elogind/logind.conf.d/90-obc40-powerkey.conf
  UDEV_RULE=/etc/udev/rules.d/91-obc40-backlight.rules
  BL=/sys/class/backlight/backlight/brightness
  if [ "$UNINSTALL" = 1 ]; then
    rm -f "$LOGIND_CONF" "$UDEV_RULE"
    pkill -HUP -x elogind 2>/dev/null || true
    echo "System files removed: the power key shuts the board down again (elogind default)."
    echo "The backlight permissions go back to root only at the next boot."
    exit 0
  fi
  mkdir -p "${LOGIND_CONF%/*}" "${UDEV_RULE%/*}"
  sed 's/\r$//' "$SRC/system/90-obc40-powerkey.conf" > "$LOGIND_CONF"
  sed 's/\r$//' "$SRC/system/91-obc40-backlight.rules" > "$UDEV_RULE"
  chmod 644 "$LOGIND_CONF" "$UDEV_RULE"
  # elogind rereads its configuration on SIGHUP: no restart, the sessions are left alone
  if pkill -HUP -x elogind 2>/dev/null; then
    echo "elogind: the power key no longer shuts the board down"
  else
    echo "elogind is not running: the power key setting applies from its next start"
  fi
  # apply the udev rule now too, without a reboot
  if [ -e "$BL" ]; then
    chgrp video "$BL" && chmod g+w "$BL" && echo "backlight: writable by the video group"
  fi
  echo "Add the desktop user to the video and input groups if needed (addgroup <user> video), then run"
  echo "sh install.sh as that user, inside the XFCE session."
  exit 0
fi

stop_running() {
  pkill -f "python3 $BIN/obc-screensaver" 2>/dev/null || true
}

if [ "$UNINSTALL" = 1 ]; then
  stop_running
  rm -f "$BIN/obc-screensaver" "$AUTOSTART_FILE"
  echo "obc40-screensaver removed (the XFCE power button setting was left as it is)"
  exit 0
fi

# --- requirements
python3 -c 'import cairo, gi; gi.require_version("Gtk", "3.0"); gi.require_foreign("cairo"); from gi.repository import Gtk' 2>/dev/null || {
  echo "Missing Python GTK3/cairo. Install them as root and run again:  apk add py3-gobject3 py3-cairo gtk+3.0" >&2; exit 1; }
KEY=""
for d in /sys/class/input/event*; do
  [ "$(cat "$d/device/name" 2>/dev/null)" = "30370000.snvs:snvs-powerkey" ] && KEY=/dev/input/${d##*/}
done
if [ -z "$KEY" ]; then
  echo "warning: power key device (snvs-powerkey) not found: is this an OBC40?" >&2
elif [ ! -r "$KEY" ]; then
  echo "warning: $KEY is not readable by $(id -un). Add the user to the input group as root" >&2
  echo "         (addgroup $(id -un) input), then log out and in again." >&2
fi
if [ -e /sys/class/backlight/backlight/brightness ] && [ ! -w /sys/class/backlight/backlight/brightness ]; then
  echo "note: the backlight is not writable by $(id -un), so the screen will not be dimmed. Run once as root: sh install.sh --system"
fi

# --- files
mkdir -p "$BIN"
sed 's/\r$//' "$SRC/obc-screensaver" > "$BIN/obc-screensaver.new"
chmod 755 "$BIN/obc-screensaver.new"
mv "$BIN/obc-screensaver.new" "$BIN/obc-screensaver"
if [ "$AUTOSTART" = 1 ]; then
  mkdir -p "${AUTOSTART_FILE%/*}"
  sed -e 's/\r$//' -e "s#@BIN@#$BIN#" -e "s#@ARGS@#$ARGS#" "$SRC/obc-screensaver.desktop" > "$AUTOSTART_FILE"
else
  rm -f "$AUTOSTART_FILE"
fi

# --- power button: no action in XFCE, so a press does not shut the board down.
# This alone is not enough: elogind can still act on the key, see --system.
if command -v xfconf-query >/dev/null 2>&1 &&
   xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/power-button-action -n -t uint -s 0 2>/dev/null; then
  echo "XFCE power button action set to: do nothing"
else
  echo "warning: could not set the XFCE power button action. Run this from a terminal inside the XFCE session," >&2
  echo "         or set it by hand: Settings > Power Manager > General > When power button is pressed: Do nothing" >&2
fi
if [ ! -e /etc/elogind/logind.conf.d/90-obc40-powerkey.conf ] && [ -d /etc/elogind ]; then
  echo "warning: elogind may still shut the board down when the power key is pressed." >&2
  echo "         Run once as root:  sh install.sh --system" >&2
fi

echo "obc40-screensaver $(cat "$SRC/VERSION" 2>/dev/null) installed in $BIN/obc-screensaver"

# --- start it now (only inside a graphical session)
if [ -n "$DISPLAY" ] && [ "$AUTOSTART" = 1 ]; then
  stop_running
  # shellcheck disable=SC2086
  setsid "$BIN/obc-screensaver"$ARGS >/dev/null 2>&1 < /dev/null &
  echo "Started: press the power key on the back to show it, press it again or touch the screen to hide it."
else
  echo "It will start at the next XFCE login. Try it now with: $BIN/obc-screensaver --demo"
fi
