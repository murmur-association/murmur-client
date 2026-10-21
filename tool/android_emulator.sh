#!/usr/bin/env bash
# Boots an Android emulator for the acceptance tests, and prints its serial:
#
#   ACCEPTANCE_DEVICE=$(tool/android_emulator.sh) flutter test tool/acceptance_test.dart
#
# Android 14 (the first to ask for the notification permission, which the
# runner answers), installed with the SDK's own sdkmanager when it isn't there.
# With KVM the emulator is accelerated; without it (GitLab's hosted runners,
# measured 2026-10-20: a boot in about three minutes) it emulates the
# processor. Needs the Android SDK (ANDROID_HOME) and Linux.
set -euo pipefail

image='system-images;android-34;google_apis;x86_64'
sdk=${ANDROID_HOME:?ANDROID_HOME is not set}
# (yes ends by a broken pipe once sdkmanager has read enough: not a failure.)
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install emulator platform-tools "$image" >/dev/null
echo no | avdmanager create avd --force -n murmur-acceptance -k "$image" -d pixel_6 >/dev/null

if [ -w /dev/kvm ]; then accel=on; else accel=off; fi
echo "booting Android 14, acceleration $accel" >&2
start=$(date +%s)
"$sdk/emulator/emulator" -avd murmur-acceptance -accel "$accel" -no-window -no-audio -no-boot-anim -no-snapshot \
  -gpu swiftshader_indirect -cores 4 -memory 4096 > "${TMPDIR:-/tmp}/murmur-emulator.log" 2>&1 &
timeout 1800 adb wait-for-device
timeout 3600 sh -c 'until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d "\r")" = 1 ]; do sleep 10; done'
echo "booted in $(( $(date +%s) - start )) s" >&2
adb devices | awk '/^emulator-/ {print $1; exit}'
