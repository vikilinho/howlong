#!/bin/bash
set -e

export PATH="/Users/victor/flutter/bin:$PATH"

VIDEO_PATH="/Users/victor/Development/HowLong/howlong_promo_demo.mp4"
DEVICE_ID="A5CB33BE-A08B-49E8-A56B-DFC75D78028B"

# Clean up any previous recording
rm -f "$VIDEO_PATH"

echo ">>> Starting screen recording..."
xcrun simctl io "$DEVICE_ID" recordVideo "$VIDEO_PATH" &
RECORD_PID=$!
sleep 2

echo ">>> Running integration test on simulator..."
flutter test integration_test/promo_recording_test.dart -d "$DEVICE_ID" || true

echo ">>> Stopping screen recording..."
kill -SIGINT "$RECORD_PID" 2>/dev/null || true
wait "$RECORD_PID" 2>/dev/null || true

sleep 2

if [ -f "$VIDEO_PATH" ]; then
  echo ">>> Recording saved to: $VIDEO_PATH"
  ls -lh "$VIDEO_PATH"
else
  echo ">>> ERROR: Recording file not found!"
fi
