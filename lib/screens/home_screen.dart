import 'dart:ui';

import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/screens/add_item_screen.dart';
import 'package:flowo_client/screens/analytics_screen.dart';
import 'package:flowo_client/screens/calendar_screen.dart';
import 'package:flowo_client/screens/profile_screen.dart';
import 'package:flowo_client/screens/settings_screen.dart';
import 'package:flowo_client/screens/task_list_screen.dart';
import 'package:flowo_client/screens/widgets/sidebar_menu_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An enhanced HomeScreen with improved UI/UX following iOS design guidelines
///
/// This screen serves as the main container for the app, providing:
/// - A polished Cupertino-style sidebar navigation
/// - Smooth transitions between screens
/// - Intuitive navigation with haptic feedback
/// - Consistent styling and visual hierarchy
/// - Accessibility considerations
/// - Support for all themes (Light, Night, ADHD)
class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final bool initialExpanded;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.initialExpanded = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late bool _isExpanded;
  bool _isTransitioning = false;

  // Animation controller for page transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Page controller for smooth transitions
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _isExpanded = widget.initialExpanded;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Jump to initial page without animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex != 0) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });

    _animationController.value = 1.0; // Start fully visible
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // List of pages with their respective icons and labels
  final List<({Widget page, IconData icon, String label, Color accentColor})>
  _pageData = const [
    (
      page: CalendarScreen(),
      icon: CupertinoIcons.calendar,
      label: 'Calendar',
      accentColor: CupertinoColors.systemBlue,
    ),
    (
      page: TaskListScreen(),
      icon: CupertinoIcons.list_bullet,
      label: 'Tasks',
      accentColor: CupertinoColors.systemGreen,
    ),
    (
      page: AddItemScreen(),
      icon: CupertinoIcons.add_circled,
      label: 'Add Task',
      accentColor: CupertinoColors.systemIndigo,
    ),
    (
      page: ProfileScreen(),
      icon: CupertinoIcons.person,
      label: 'Profile',
      accentColor: CupertinoColors.systemOrange,
    ),
    (
      page: SettingsScreen(),
      icon: CupertinoIcons.settings,
      label: 'Settings',
      accentColor: CupertinoColors.systemGrey,
    ),
    (
      page: AnalyticsScreen(),
      icon: CupertinoIcons.chart_bar_alt_fill,
      label: 'Analytics',
      accentColor: CupertinoColors.systemPurple,
    ),
  ];

  // Navigate to a specific page with animation
  void _navigateToPage(int index) {
    if (_selectedIndex == index) {
      // If already on this page, just close the sidebar
      setState(() {
        _isExpanded = false;
      });
      return;
    }

    setState(() {
      _isTransitioning = true;
      _selectedIndex = index;
      _isExpanded = false;
    });

    // Reset animation and start it
    _animationController.reset();
    _animationController.forward();

    // Animate to the selected page
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          setState(() {
            _isTransitioning = false;
          });
        });
  }

  // Toggle sidebar visibility with haptic feedback
  void _toggleSidebar() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Main content area with PageView for smooth transitions
          Positioned.fill(
            child: BlocProvider.value(
              value: context.read<CalendarCubit>(),
              child: PageView.builder(
                controller: _pageController,
                physics:
                    _isTransitioning
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  if (!_isTransitioning) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  }
                },
                itemCount: _pageData.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity:
                            index == _selectedIndex
                                ? _fadeAnimation.value
                                : 1.0 - _fadeAnimation.value,
                        child: child,
                      );
                    },
                    child: _pageData[index].page,
                  );
                },
              ),
            ),
          ),

          // Sidebar overlay with blur effect
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color:
                        isDarkMode
                            ? CupertinoColors.black.withOpacity(0.5)
                            : CupertinoColors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),

          // Enhanced sidebar with animations and styling
          AnimatedPositioned(
            key: const ValueKey('sidebar'),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isExpanded ? 0 : -320,
            top: 0,
            bottom: 0,
            width: 320,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sidebar header with app logo/name
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    isDarkMode
                                        ? CupertinoColors.darkBackgroundGray
                                            .withOpacity(0.3)
                                        : CupertinoColors.systemGrey5,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons.calendar_today,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Flowo',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? CupertinoColors.white
                                                : CupertinoColors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Productivity App',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? CupertinoColors.systemGrey
                                                : CupertinoColors.systemGrey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Navigation menu items
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _pageData.length,
                            itemBuilder: (context, index) {
                              final item = _pageData[index];
                              final isSelected = index == _selectedIndex;

                              return SidebarMenuItem(
                                icon: item.icon,
                                label: item.label,
                                accentColor: item.accentColor,
                                isSelected: isSelected,
                                onTap: () => _navigateToPage(index),
                              );
                            },
                          ),
                        ),

                        // Footer with version info
                        Flexible(
                          fit: FlexFit.loose,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'FLOWO 1.0.0',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Menu button to toggle sidebar

          // Menu button to toggle sidebar (hamburger menu only)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Visibility(
                visible: !_isExpanded, // Only show when sidebar is closed
                child: GestureDetector(
                  onTap: _toggleSidebar,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? CupertinoColors.darkBackgroundGray
                                    .withOpacity(0.8)
                                : CupertinoColors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.line_horizontal_3,
                          color:
                              isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button (x-mark) on right side of sidebar when expanded
          Positioned(
            top: 0,
            left:
                _isExpanded
                    ? 288
                    : -50, // Position on right side of sidebar when open
            child: SafeArea(
              child: Visibility(
                visible: _isExpanded,
                child: GestureDetector(
                  onTap: _toggleSidebar,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? CupertinoColors.darkBackgroundGray
                                    .withOpacity(0.8)
                                : CupertinoColors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.xmark,
                          color:
                              isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
