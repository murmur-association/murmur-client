#!/usr/bin/env bash
# Runs tool/desktop_smoke_test.dart on Linux, in a session of its own: a
# throwaway home folder, a session bus with an unlocked keyring, and a
# display without a screen. The checks themselves are in that file, the
# same for Windows. Run on the packaged folder (package_desktop.dart):
#
#   tool/linux_smoke_test.sh [--wallet-storage] <app folder>
#
# Needs xvfb, openbox, wmctrl, dbus and gnome-keyring: a display, a window
# manager to pass the close request on, a way to send it, and a session
# with an unlocked keyring, as a desktop gives the app. (The app keeps the
# wallet in the keyring, and the plugin for it waits on the app's main
# thread: with a keyring that is locked and can't ask, the app would hang
# before showing anything.) Nothing of the user's is read or changed.
set -euo pipefail

# Everything below runs inside a session bus of its own.
if [ -z "${MURMUR_SMOKE_SESSION:-}" ]; then
  MURMUR_SMOKE_SESSION=1 exec dbus-run-session -- "$0" "$@"
fi

# Downloaded packages stay where they are; everything else moves.
export PUB_CACHE=${PUB_CACHE:-$HOME/.pub-cache}
home=$(mktemp -d)
display='' wm=''
cleanup() {
  for pid in $wm $display; do kill "$pid" 2>/dev/null || true; done
  rm -rf "$home"
}
trap cleanup EXIT

export HOME=$home XDG_DATA_HOME=$home/.local/share XDG_CONFIG_HOME=$home/.config XDG_CACHE_HOME=$home/.cache
export DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 GDK_BACKEND=x11
unset WAYLAND_DISPLAY
Xvfb "$DISPLAY" -screen 0 1280x800x24 >/dev/null 2>&1 & display=$!
sleep 1
openbox >/dev/null 2>&1 & wm=$!
sleep 1
echo -n smoke | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1

dart run tool/desktop_smoke_test.dart "$@"
