# App Icon and Launch Image Replacement Instructions

## Issue
The app is currently using placeholder icons for both the app icon and launch image. These need to be replaced with unique, custom icons.

## App Icon Replacement

### Current Configuration
The app icon is configured in `pubspec.yaml` using the `flutter_launcher_icons` package:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#ffffff"
    theme_color: "#ffffff"
  windows:
    generate: true
    image_path: "assets/icon/app_icon.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/icon/app_icon.png"
```

### Steps to Replace
1. Create a new app icon image (1024x1024 pixels recommended) and save it as `app_icon.png`
2. Replace the existing file at `assets/icon/app_icon.png` with your new icon
3. Run the following command to generate all platform-specific icons:
   ```
   flutter pub run flutter_launcher_icons
   ```

## Launch Image Replacement

### Current Configuration
The iOS launch image is configured in `ios/Runner/Assets.xcassets/LaunchImage.imageset/` and contains:
- LaunchImage.png (1x scale)
- LaunchImage@2x.png (2x scale)
- LaunchImage@3x.png (3x scale)

### Steps to Replace
1. Create new launch images at the following sizes:
   - LaunchImage.png: 168x185 pixels (1x)
   - LaunchImage@2x.png: 336x370 pixels (2x)
   - LaunchImage@3x.png: 504x555 pixels (3x)
2. Replace the existing files in `ios/Runner/Assets.xcassets/LaunchImage.imageset/` with your new images
3. Make sure the filenames match exactly: `LaunchImage.png`, `LaunchImage@2x.png`, and `LaunchImage@3x.png`

## Design Recommendations
- The app icon should be simple, recognizable, and represent the Flowo app's purpose
- The launch image should be consistent with the app's branding and provide a smooth transition to the app's main interface
- Both should use colors and design elements that match the app's overall design language
- Avoid using text in the app icon as it may become illegible at smaller sizes