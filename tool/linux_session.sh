#!/usr/bin/env bash
# Runs a command on Linux in a session of its own: a throwaway home folder,
# a session bus with an unlocked keyring, and a display without a screen.
# What the tests of the Linux app run in, each of them the same test as on
# the other systems:
#
#   tool/linux_session.sh dart run tool/desktop_smoke_test.dart [--wallet-storage] <app folder>
#   tool/linux_session.sh flutter test tool/acceptance_test.dart
#   MURMUR_KEYRING=locked tool/linux_session.sh dart run tool/desktop_smoke_test.dart <app folder>
#
# Needs xvfb, openbox, wmctrl, dbus and gnome-keyring (and xdotool for the
# acceptance tests' file dialog): a display, a window
# manager to pass the close request on, a way to send it, and a session
# with an unlocked keyring, as a desktop gives the app; with
# MURMUR_KEYRING=locked, a locked one with nobody to answer its prompt.
# (The app keeps the wallet in the keyring, and the plugin for it waits on
# the app's main thread: with a keyring that is locked and can't ask, the
# app once hung before showing anything; it now checks first.) Nothing of
# the user's is read or changed.
set -euo pipefail

# Everything below runs inside a session bus of its own.
if [ -z "${MURMUR_TEST_SESSION:-}" ]; then
  MURMUR_TEST_SESSION=1 exec dbus-run-session -- "$0" "$@"
fi

# Downloaded packages stay where they are; everything else moves.
export PUB_CACHE=${PUB_CACHE:-$HOME/.pub-cache}
home=$(mktemp -d)
display='' wm='' notifier=''
cleanup() {
  for pid in $notifier $wm $display; do kill "$pid" 2>/dev/null || true; done
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
if [ "${MURMUR_KEYRING:-}" = locked ]; then
  # The keyring locked, with nobody to answer its password prompt: where the
  # app used to hang before showing anything (lib/services/keyring.dart). It
  # must now start all the same, without a stored wallet.
  dbus-send --session --print-reply --dest=org.freedesktop.secrets /org/freedesktop/secrets \
    org.freedesktop.Secret.Service.Lock array:objpath:/org/freedesktop/secrets/collection/login >/dev/null
fi

# A notification server, as a desktop has, that keeps what it's given in a
# log the tests read (tool/notification_server.dart); it's ready once the
# log exists.
export MURMUR_NOTIFY_LOG=$home/notifications.log
dart run tool/notification_server.dart "$MURMUR_NOTIFY_LOG" & notifier=$!
for _ in $(seq 150); do [ -e "$MURMUR_NOTIFY_LOG" ] && break; sleep 0.2; done
[ -e "$MURMUR_NOTIFY_LOG" ] || { echo 'the notification server did not start' >&2; exit 1; }

"$@"
