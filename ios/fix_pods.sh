#!/bin/bash

# Navigate to the iOS directory
cd "$(dirname "$0")"

# Clean CocoaPods cache
echo "Cleaning CocoaPods cache..."
pod cache clean --all

# Remove Pods directory and Podfile.lock
echo "Removing Pods directory and Podfile.lock..."
rm -rf Pods
rm -f Podfile.lock

# Install pods
echo "Installing pods..."
pod install

echo "Pod installation completed."