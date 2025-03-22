import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../design/animated_particles_background.dart';
import '../design/glassmorphic_container.dart';
import '../theme_notifier.dart';
import 'widgets/cupertino_divider.dart';
import 'widgets/glassmorphic_settings_button.dart';
import 'widgets/sidebar_menu_item.dart';

/// A showcase screen demonstrating the Glassmorphic UI components
class GlassmorphicShowcaseScreen extends StatefulWidget {
  const GlassmorphicShowcaseScreen({Key? key}) : super(key: key);

  @override
  State<GlassmorphicShowcaseScreen> createState() =>
      _GlassmorphicShowcaseScreenState();
}

class _GlassmorphicShowcaseScreenState
    extends State<GlassmorphicShowcaseScreen> {
  bool _useParticles = true;
  bool _useGradients = true;
  bool _useShimmer = true;
  int _selectedSidebarItem = 0;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    final Widget content = CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Glassmorphic UI Showcase'),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.7),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title section
            GlassmorphicCard(
              useGradient: _useGradients,
              showShimmer: _useShimmer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glassmorphic UI Components',
                    style:
                        CupertinoTheme.of(
                          context,
                        ).textTheme.navLargeTitleTextStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A showcase of the modern, vibrant Glassmorphic UI design for the app',
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(color: CupertinoColors.secondaryLabel),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings section
            Text(
              'Settings',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Animated Particles',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                      CupertinoSwitch(
                        value: _useParticles,
                        onChanged:
                            (value) => setState(() => _useParticles = value),
                        activeColor: glassmorphicTheme.accentColor,
                      ),
                    ],
                  ),
                  const CupertinoDivider(
                    height: 1.0,
                    useGradient: true,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gradient Effects',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                      CupertinoSwitch(
                        value: _useGradients,
                        onChanged:
                            (value) => setState(() => _useGradients = value),
                        activeColor: glassmorphicTheme.accentColor,
                      ),
                    ],
                  ),
                  const CupertinoDivider(
                    height: 1.0,
                    useGradient: true,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shimmer Effects',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                      CupertinoSwitch(
                        value: _useShimmer,
                        onChanged:
                            (value) => setState(() => _useShimmer = value),
                        activeColor: glassmorphicTheme.accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons section
            Text(
              'Buttons',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassmorphicSettingsButton(
                    label: 'Primary Button',
                    onPressed: () {},
                    isPrimary: true,
                    useAnimatedPress: true,
                    icon: CupertinoIcons.star_fill,
                  ),
                  const SizedBox(height: 16),
                  GlassmorphicSettingsButton(
                    label: 'Secondary Button',
                    onPressed: () {},
                    useAnimatedPress: true,
                    icon: CupertinoIcons.heart,
                  ),
                  const SizedBox(height: 16),
                  GlassmorphicSettingsButton(
                    label: 'Destructive Button',
                    onPressed: () {},
                    isDestructive: true,
                    useAnimatedPress: true,
                    icon: CupertinoIcons.delete,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sidebar items section
            Text(
              'Sidebar Menu Items',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            GlassmorphicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SidebarMenuItem(
                    icon: CupertinoIcons.home,
                    label: 'Home',
                    accentColor: glassmorphicTheme.accentColor,
                    isSelected: _selectedSidebarItem == 0,
                    onTap: () => setState(() => _selectedSidebarItem = 0),
                  ),
                  SidebarMenuItem(
                    icon: CupertinoIcons.calendar,
                    label: 'Calendar',
                    accentColor: glassmorphicTheme.accentColor,
                    isSelected: _selectedSidebarItem == 1,
                    onTap: () => setState(() => _selectedSidebarItem = 1),
                  ),
                  SidebarMenuItem(
                    icon: CupertinoIcons.chart_bar,
                    label: 'Analytics',
                    accentColor: glassmorphicTheme.accentColor,
                    isSelected: _selectedSidebarItem == 2,
                    onTap: () => setState(() => _selectedSidebarItem = 2),
                  ),
                  SidebarMenuItem(
                    icon: CupertinoIcons.settings,
                    label: 'Settings',
                    accentColor: glassmorphicTheme.accentColor,
                    isSelected: _selectedSidebarItem == 3,
                    onTap: () => setState(() => _selectedSidebarItem = 3),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Containers section
            Text(
              'Glassmorphic Containers',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GlassmorphicContainer(
                    height: 100,
                    useGradient: _useGradients,
                    showShimmer: _useShimmer,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Basic',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassmorphicContainer(
                    height: 100,
                    useGradient: _useGradients,
                    gradientColors: [
                      glassmorphicTheme.accentColor,
                      glassmorphicTheme.secondaryAccentColor,
                    ],
                    showShimmer: _useShimmer,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Gradient',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassmorphicContainer(
              height: 100,
              borderRadius: BorderRadius.circular(50),
              useGradient: _useGradients,
              showShimmer: _useShimmer,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Rounded',
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Credits section
            GlassmorphicCard(
              useGradient: true,
              showShimmer: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Modern Glassmorphic UI',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .navTitleTextStyle
                        .copyWith(color: glassmorphicTheme.accentColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A beautiful, vibrant design system for the smart time management app',
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with animated particles if enabled
    return _useParticles
        ? AnimatedParticlesBackground(
          particleCount: 30,
          speedFactor: 0.5,
          particleOpacity: 0.3,
          child: content,
        )
        : content;
  }
}
