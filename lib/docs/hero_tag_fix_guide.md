# Hero Tag Fix Guide

## Problem

When using multiple `CupertinoNavigationBar` widgets in your Flutter app, you may encounter this error:

```
There are multiple heroes that share the same tag within a subtree.
```

This happens because `CupertinoNavigationBar` uses a default hero tag, which causes conflicts when multiple navigation bars appear in the same navigation stack.

## Solution

### Basic Fix

For every `CupertinoNavigationBar` in your app, add a unique `heroTag` parameter:

```dart
CupertinoNavigationBar(
  middle: Text('Screen Title'),
  heroTag: HeroTagManager.getNavigationBarTag('unique_screen_name'),
)
```

### Naming Conventions

Use consistent naming for screen identifiers:
- Use snake_case for screen names
- Make names descriptive (e.g., 'user_profile', 'settings_page')
- For nested screens, consider using prefixes (e.g., 'settings_notifications')

### Special Cases

1. **Multiple Navigation Bars in One Screen**

   When you have multiple navigation bars in the same screen:

   ```dart
   CupertinoNavigationBar(
     middle: Text('Main Header'),
     heroTag: HeroTagManager.getSpecificNavigationBarTag('screen_name', 'main_nav'),
   )
   
   CupertinoNavigationBar(
     middle: Text('Secondary Header'),
     heroTag: HeroTagManager.getSpecificNavigationBarTag('screen_name', 'secondary_nav'),
   )
   ```

2. **Disabling Hero Animation**

   If you don't need hero animations for a particular navigation bar:

   ```dart
   CupertinoNavigationBar(
     middle: Text('Screen Title'),
     heroTag: HeroTagManager.disabledHeroTag,
   )
   ```

3. **Context-Dependent Tags**

   For dynamically created navigation bars:

   ```dart
   CupertinoNavigationBar(
     middle: Text('Dynamic Screen'),
     heroTag: HeroTagManager.getUniqueTag(context, 'some_identifier'),
   )
   ```

## Testing

After implementing these fixes:

1. Test navigation between all screens in your app
2. Check transitions with hero animations
3. Verify that no hero tag errors appear in the console

Remember: Every `CupertinoNavigationBar` in your navigation stack must have a unique hero tag!
