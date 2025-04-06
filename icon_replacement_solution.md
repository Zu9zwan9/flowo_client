# App Icon and Launch Image Replacement Solution

## Issue Summary
The app is currently using placeholder icons for both the app icon and launch image. These need to be replaced with unique, custom icons.

## Solution Steps

### 1. App Icon Replacement

#### Requirements:
- Create a new app icon image (1024x1024 pixels)
- The icon should be simple, recognizable, and represent the Flowo app's purpose
- Use colors and design elements that match the app's overall design language
- Avoid using text in the app icon as it may become illegible at smaller sizes

#### Implementation Steps:
1. Create a new app icon using image editing software (Photoshop, Sketch, Figma, etc.)
2. Save the icon as a PNG file with dimensions 1024x1024 pixels
3. Replace the existing file at `assets/icon/app_icon.png` with your new icon
4. Run the following command to generate all platform-specific icons:
   ```
   flutter pub run flutter_launcher_icons
   ```

### 2. Launch Image Replacement

#### Requirements:
- Create new launch images at three different sizes
- The launch image should be consistent with the app's branding
- It should provide a smooth transition to the app's main interface
- Use colors and design elements that match the app's overall design language

#### Implementation Steps:
1. Create new launch images using image editing software at the following sizes:
   - LaunchImage.png: 168x185 pixels (1x)
   - LaunchImage@2x.png: 336x370 pixels (2x)
   - LaunchImage@3x.png: 504x555 pixels (3x)
2. Save each image as a PNG file with the exact filenames:
   - `LaunchImage.png`
   - `LaunchImage@2x.png`
   - `LaunchImage@3x.png`
3. Replace the existing files in `ios/Runner/Assets.xcassets/LaunchImage.imageset/` with your new images

### 3. Verification

After replacing the icons and running the flutter_launcher_icons tool, verify the changes:

1. Check that the app icon has been updated in:
   - Android: `android/app/src/main/res/mipmap-*/launcher_icon.png`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Web: `web/icons/`
   - Windows: `windows/runner/resources/app_icon.ico`
   - macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

2. Check that the launch images have been updated in:
   - iOS: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

3. Build and run the app on different platforms to ensure the new icons are displayed correctly.

## Design Recommendations

### App Icon Design:
- Use a simple, recognizable symbol that represents the Flowo app's purpose
- Consider using a flowing design element to represent the "flow" in Flowo
- Use a color palette that matches the app's branding
- Ensure the design works well at small sizes (e.g., on a home screen)
- Test the icon against different backgrounds (light, dark, colorful)

### Launch Image Design:
- Keep it simple and aligned with the app's branding
- Consider using the same color scheme as the app icon for consistency
- The launch image should provide a smooth visual transition to the app's main interface
- Avoid including text that might become outdated (version numbers, etc.)

## Technical Notes
- The flutter_launcher_icons package is already configured in pubspec.yaml
- No changes to configuration files are needed, just replace the image files
- The app icon will be automatically resized for different platforms and device sizes
- Make sure to test the app on different devices to ensure the icons look good at all sizes