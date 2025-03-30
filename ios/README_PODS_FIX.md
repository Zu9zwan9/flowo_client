# Fix for "Framework 'Pods_Runner' not found" Error

If you're encountering the error "Framework 'Pods_Runner' not found" when building your iOS app, this is typically related to issues with CocoaPods integration. This README provides instructions on how to fix this issue.

## Solution

We've provided a script that will help fix this issue by:
1. Cleaning the CocoaPods cache
2. Removing the existing Pods directory and Podfile.lock
3. Reinstalling all pods

### Using the Fix Script

1. Open Terminal
2. Navigate to your project's iOS directory:
   ```
   cd /path/to/your/project/ios
   ```
3. Run the fix script:
   ```
   ./fix_pods.sh
   ```
4. Wait for the script to complete. This may take a few minutes.
5. Once completed, open your project in Xcode:
   ```
   open Runner.xcworkspace
   ```
6. Build and run your project

### Manual Fix

If the script doesn't work for you, you can try these manual steps:

1. Open Terminal
2. Navigate to your project's iOS directory:
   ```
   cd /path/to/your/project/ios
   ```
3. Clean CocoaPods cache:
   ```
   pod cache clean --all
   ```
4. Remove Pods directory and Podfile.lock:
   ```
   rm -rf Pods
   rm -f Podfile.lock
   ```
5. Install pods:
   ```
   pod install
   ```
6. Open your project in Xcode:
   ```
   open Runner.xcworkspace
   ```
7. Build and run your project

## Additional Troubleshooting

If you're still experiencing issues after running the script or following the manual steps, try these additional troubleshooting steps:

1. Make sure you're using the latest version of CocoaPods:
   ```
   sudo gem install cocoapods
   ```

2. Make sure you're opening the `.xcworkspace` file, not the `.xcodeproj` file.

3. Try cleaning the build folder in Xcode:
   - In Xcode, go to Product > Clean Build Folder
   - Then build and run your project again

4. Check if your Podfile has the correct iOS platform version specified.

5. Make sure all your pods are compatible with your iOS deployment target.