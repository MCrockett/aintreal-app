#!/bin/bash
# Full clean - removes all build artifacts
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER=~/Library/flutter/bin/flutter

cd "$PROJECT_DIR"

echo "Running flutter clean..."
$FLUTTER clean

echo "Removing additional build artifacts..."
rm -rf "$PROJECT_DIR/build"
rm -rf "$PROJECT_DIR/android/.gradle"
rm -rf "$PROJECT_DIR/android/app/build"
rm -rf "$PROJECT_DIR/ios/Pods"
rm -rf "$PROJECT_DIR/ios/.symlinks"
rm -rf "$PROJECT_DIR/ios/Flutter/Flutter.framework"
rm -rf "$PROJECT_DIR/ios/Flutter/Flutter.podspec"

echo "Clean complete!"
