import 'dart:ui';

import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/screens/add_item_screen.dart';
import 'package:flowo_client/screens/analytics/analytics_screen.dart';
import 'package:flowo_client/screens/calendar/daily_overview_screen.dart';
import 'package:flowo_client/screens/profile/profile_screen.dart';
import 'package:flowo_client/screens/settings/settings_screen.dart';
import 'package:flowo_client/screens/task/task_list_screen.dart';
import 'package:flowo_client/screens/widgets/sidebar_menu_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/gradient_theme.dart';
import 'calendar/calendar_screen.dart';

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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _isExpanded = widget.initialExpanded;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex != 0) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });

    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  final List<({Widget page, IconData icon, String label, Color accentColor})>
  _pageData = [
    (
      page: DailyOverviewScreen(),
      icon: CupertinoIcons.home,
      label: 'Today',
      accentColor: CupertinoColors.systemBlue,
    ),
    (
      page: CalendarScreen(),
      icon: CupertinoIcons.calendar,
      label: 'Calendar',
      accentColor: CupertinoColors.systemPink,
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
      label: 'Create',
      accentColor: CupertinoColors.systemIndigo,
    ),
    (
      page: ProfileScreen(),
      icon: CupertinoIcons.person,
      label: 'Profile',
      accentColor: CupertinoColors.systemOrange,
    ),
    (
      page: AnalyticsScreen(),
      icon: CupertinoIcons.chart_bar_alt_fill,
      label: 'Analytics',
      accentColor: CupertinoColors.systemPurple,
    ),
    (
      page: SettingsScreen(),
      icon: CupertinoIcons.settings,
      label: 'Settings',
      accentColor: CupertinoColors.systemGrey,
    ),
  ];

  // (
  //   page: NotificationTestScreen(),
  //   icon: CupertinoIcons.bell,
  //   label: 'Test Notifications',
  //   accentColor: CupertinoColors.systemTeal,
  // ),

  void _navigateToPage(int index) {
    if (_selectedIndex == index) {
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

    _animationController.reset();
    _animationController.forward();

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

  void _toggleSidebar() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GradientTheme(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_pageData[_selectedIndex].label),
          leading: GestureDetector(
            onTap: _toggleSidebar,
            child: const Icon(CupertinoIcons.line_horizontal_3),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              top: 0, // Adjust for navigation bar height
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
                    color: CupertinoTheme.of(context).scaffoldBackgroundColor,
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
                                    color: CupertinoColors.systemIndigo,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  textColor:
                                      isDarkMode
                                          ? CupertinoColors.white
                                          : CupertinoColors.black,
                                );
                              },
                            ),
                          ),
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
          ],
        ),
      ),
    );
  }
}
