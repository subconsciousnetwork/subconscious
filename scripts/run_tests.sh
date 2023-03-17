#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo "USAGE: run_tests.sh PLATFORM DEVICE OS [XCODE_VERSION]"
  echo "EXAMPLE: run_tests.sh "iOS Simulator" "iPhone 14 Pro" 16.2 14.2"
  exit 1
fi

PLATFORM=$1
DEVICE=$2
OS=$3

if [[ ! -z "$4" ]]; then
  XCODE_PATH="/Applications/Xcode_$4.app"
  sudo xcode-select -switch $XCODE_PATH && /usr/bin/xcodebuild -version
fi

DESTINATION="platform=$PLATFORM"
DESTINATION="$DESTINATION,name=$DEVICE"
DESTINATION="$DESTINATION,OS=$OS"
  
# Run tests
xcodebuild test -project xcode/Subconscious/Subconscious.xcodeproj \
  -scheme "Subconscious (iOS)" \
  -destination "$DESTINATION"
