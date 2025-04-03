#!/bin/bash

# Script to restart Flutter app and avoid "app not found" errors

# Kill any existing Flutter processes
echo "Stopping any existing Flutter processes..."
pkill -f "flutter"

# Wait a moment to ensure processes are terminated
sleep 2

# Start the Flutter app
echo "Starting Flutter app..."
flutter run "$@"
