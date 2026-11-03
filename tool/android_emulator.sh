#!/usr/bin/env bash
# Boots an Android emulator for the acceptance tests, and prints its serial:
#
#   ACCEPTANCE_DEVICE=$(tool/android_emulator.sh) flutter test tool/acceptance_test.dart
#
# Android 14 (the first to ask for the notification permission, which the
# runner answers), installed with the SDK's own sdkmanager when it isn't there.
# With KVM the emulator is accelerated (GitHub's hosted Linux runners); without
# it (GitLab's, measured 2026-10-20: a boot in about three minutes) it
# emulates the processor. Needs the Android SDK (ANDROID_HOME) and Linux.
set -euo pipefail

image='system-images;android-34;google_apis;x86_64'
sdk=${ANDROID_HOME:?ANDROID_HOME is not set}
# One folder for the virtual device, named to both tools: on GitHub's runner
# avdmanager wrote it where the emulator didn't look ("Unknown AVD name").
export ANDROID_AVD_HOME=${ANDROID_AVD_HOME:-$HOME/.android/avd}
mkdir -p "$ANDROID_AVD_HOME"
# (yes ends by a broken pipe once sdkmanager has read enough: not a failure.)
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install emulator platform-tools "$image" >/dev/null
echo no | avdmanager create avd --force -n murmur-acceptance -k "$image" -d pixel_6 >/dev/null

if [ -w /dev/kvm ]; then accel=on; else accel=off; fi
echo "booting Android 14, acceleration $accel" >&2
start=$(date +%s)
log="${TMPDIR:-/tmp}/murmur-emulator.log"
# Its exit status goes into its log: on GitHub's runner it sometimes ended
# mid-suite without a word (137 would say it was killed, 139 that it crashed).
# Appended, so a second boot keeps the first one's ending.
echo "---- booting at $(date -u +%T)" >> "$log"
( "$sdk/emulator/emulator" -avd murmur-acceptance -accel "$accel" -no-window -no-audio -no-boot-anim -no-snapshot \
    -gpu swiftshader_indirect -cores 4 -memory 4096
  echo "---- the emulator exited with status $? at $(date -u +%T)" ) >> "$log" 2>&1 &
emulator=$!
# Until it has booted, or for an hour; an emulator that stops ends the wait.
deadline=$(( start + 3600 ))
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do
  if ! kill -0 "$emulator" 2>/dev/null; then
    echo "the emulator stopped before booting:" >&2
    tail -n 30 "$log" >&2
    exit 1
  fi
  [ "$(date +%s)" -lt "$deadline" ] || { echo "the emulator didn't boot in an hour" >&2; exit 1; }
  sleep 10
done
echo "booted in $(( $(date +%s) - start )) s" >&2
adb devices | awk '/^emulator-/ {print $1; exit}'
