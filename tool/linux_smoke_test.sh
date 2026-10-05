#!/usr/bin/env bash
# Tries the built Linux app as a user would start it, without a screen:
# it must start, run its own node as a child when that's switched on, and
# stop the node when its window is closed. Run after
# `flutter build linux --release` and `dart run tool/bundle_node.dart`:
#
#   tool/linux_smoke_test.sh [bundle folder]
#
# Needs xvfb, openbox, wmctrl, dbus and gnome-keyring: a display, a window
# manager to pass the close request on, a way to send it, and a session
# with an unlocked keyring, as a desktop gives the app. (The app keeps the
# wallet in the keyring, and the plugin for it waits on the app's main
# thread: with a keyring that is locked and can't ask, the app would hang
# before showing anything.) Settings and data go to a
# throwaway home folder, so nothing of the user's is read or changed.
# Build with --dart-define=MURMUR_LOCAL_NODE_SPEC=demo to keep the node off
# the public network.
set -euo pipefail

# Everything below runs inside a session bus of its own.
if [ -z "${MURMUR_SMOKE_SESSION:-}" ]; then
  MURMUR_SMOKE_SESSION=1 exec dbus-run-session -- "$0" "$@"
fi

arch=$(uname -m | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')
bundle=${1:-build/linux/$arch/release/bundle}
[ -x "$bundle/murmur_client" ] || { echo "no app in $bundle: build it first"; exit 1; }
[ -x "$bundle/murmur-node" ] || { echo "no node in $bundle: run dart run tool/bundle_node.dart"; exit 1; }

home=$(mktemp -d)
app='' display='' wm=''
cleanup() {
  for pid in $app $wm $display; do kill "$pid" 2>/dev/null || true; done
  pkill -f "$bundle/murmur-node" 2>/dev/null || true
  rm -rf "$home"
}
trap cleanup EXIT

export HOME=$home XDG_DATA_HOME=$home/.local/share XDG_CONFIG_HOME=$home/.config XDG_CACHE_HOME=$home/.cache
# The app's settings (shared_preferences), under its application id: its
# own node switched on, as the Chain tab's switch would.
mkdir -p "$XDG_DATA_HOME/info.murmur.client"
echo '{"flutter.run_local_node":true}' > "$XDG_DATA_HOME/info.murmur.client/shared_preferences.json"

export DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 GDK_BACKEND=x11
Xvfb "$DISPLAY" -screen 0 1280x800x24 >/dev/null 2>&1 & display=$!
sleep 1
openbox >/dev/null 2>&1 & wm=$!
sleep 1
echo -n smoke | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1

"$bundle/murmur_client" >"$home/app.log" 2>&1 & app=$!

wait_for() { # <seconds> <what> <command...>
  local n=$1 what=$2; shift 2
  for _ in $(seq "$((n * 2))"); do "$@" >/dev/null 2>&1 && return 0; sleep 0.5; done
  echo "FAILED: $what"; echo "--- the app's output:"; tail -n 30 "$home/app.log"; exit 1
}

wait_for 30 "no window titled Murmur appeared" sh -c "wmctrl -l | grep -q ' Murmur$'"
echo "window: $(wmctrl -l | sed 's/^[^ ]* *[^ ]* *[^ ]* //')"

wait_for 30 "the node didn't start as the app's child" pgrep -P "$app" -f murmur-node
node=$(pgrep -P "$app" -f murmur-node)
echo "node: pid $node, child of the app ($app)"
echo "node options: $(tr '\0' ' ' < "/proc/$node/cmdline" | cut -d' ' -f2-)"

wmctrl -c Murmur
wait_for 20 "the app didn't exit after its window was closed" sh -c "! kill -0 $app 2>/dev/null"
wait_for 10 "the node kept running after the app closed" sh -c "! kill -0 $node 2>/dev/null"
echo "closing the window stopped the app and its node"
echo "OK"
