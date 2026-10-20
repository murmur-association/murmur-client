#!/usr/bin/env bash
# Boots an iPhone simulator for the iOS acceptance tests, and prints its id:
#
#   ACCEPTANCE_DEVICE=$(tool/ios_simulator.sh) flutter test tool/acceptance_test.dart
#
# The newest iOS runtime Xcode has, and an iPhone that runtime says it
# supports (not every iPhone Xcode knows runs every runtime). A fresh
# simulator has no passcode set, and its key store then asks nothing: the
# app's vault keeps the wallet there, as on an iPhone, with nobody to answer
# (the tests' driver expects it). Needs macOS with Xcode.
set -euo pipefail

read -r runtime device <<< "$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
ios = [r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS" and r["isAvailable"]][-1]
phones = [d["identifier"] for d in ios["supportedDeviceTypes"] if d["productFamily"] == "iPhone"]
print(ios["identifier"], phones[-1])')"
echo "runtime $runtime, device type $device" >&2
udid=$(xcrun simctl create murmur-acceptance "$device" "$runtime")
xcrun simctl boot "$udid"
xcrun simctl bootstatus "$udid" -b >&2
echo "$udid"
