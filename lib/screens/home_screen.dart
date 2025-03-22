import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design/animated_particles_background.dart';
import '../../design/glassmorphic_container.dart';
import '../../theme_notifier.dart';
import '../../blocs/tasks_controller/tasks_controller_cubit.dart';

import '../../screens/daily_overview_screen.dart';
import '../../screens/task_list_screen.dart';
import '../../screens/add_item_screen.dart';
import '../../screens/task_selection_screen.dart';
import '../../screens/ambient_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/analytics_screen.dart';

import 'widgets/menu_button.dart';
import 'widgets/sidebar_menu_item.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  bool _isSidebarOpen = false;
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sidebarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex != 0) {
        _pageController.jumpToPage(_selectedIndex);
      }
    });
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
      page: const DailyOverviewScreen(),
      icon: CupertinoIcons.home,
      label: 'Today',
      accentColor: CupertinoColors.systemBlue,
    ),
    (
      page: const TaskListScreen(),
      icon: CupertinoIcons.list_bullet,
      label: 'Tasks',
      accentColor: CupertinoColors.systemGreen,
    ),
    (
      page: const AddItemScreen(),
      icon: CupertinoIcons.add_circled,
      label: 'Create',
      accentColor: CupertinoColors.systemIndigo,
    ),
    (
      page: const TaskSelectionScreen(),
      icon: CupertinoIcons.timer,
      label: 'Pomodoro',
      accentColor: CupertinoColors.systemRed,
    ),
    (
      page: const AmbientScreen(),
      icon: CupertinoIcons.music_note_2,
      label: 'Ambient',
      accentColor: CupertinoColors.systemTeal,
    ),
    (
      page: const ProfileScreen(),
      icon: CupertinoIcons.person,
      label: 'Profile',
      accentColor: CupertinoColors.systemOrange,
    ),
    (
      page: const SettingsScreen(),
      icon: CupertinoIcons.settings,
      label: 'Settings',
      accentColor: CupertinoColors.systemGrey,
    ),
    (
      page: const AnalyticsScreen(),
      icon: CupertinoIcons.chart_bar_alt_fill,
      label: 'Analytics',
      accentColor: CupertinoColors.systemPurple,
    ),
  ];

  void _navigateToPage(int index) {
    if (_selectedIndex == index && _isSidebarOpen) {
      _toggleSidebar();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (_isSidebarOpen) {
            _toggleSidebar();
          }
        });
  }

  void _toggleSidebar() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    if (_isSidebarOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _pageData[_selectedIndex].label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: MenuButton(isExpanded: _isSidebarOpen, onTap: _toggleSidebar),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 20,
            speedFactor: 0.3,
            particleOpacity: 0.4,
            child: BlocProvider.value(
              value: context.read<CalendarCubit>(),
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                itemCount: _pageData.length,
                itemBuilder: (context, index) {
                  return _pageData[index].page;
                },
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-280 * (1 - _sidebarAnimation.value), 0),
                child:
                    _isSidebarOpen
                        ? GestureDetector(
                          onTap: _toggleSidebar,
                          behavior: HitTestBehavior.translucent,
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                GlassmorphicContainer(
                                  width: 280,
                                  height: MediaQuery.of(context).size.height,
                                  blur: glassmorphicTheme.defaultBlur,
                                  opacity: 0.7,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  borderWidth: 0,
                                  backgroundColor:
                                      isDarkMode
                                          ? CupertinoColors.black.withOpacity(
                                            0.2,
                                          )
                                          : CupertinoColors.white.withOpacity(
                                            0.2,
                                          ),
                                  useGradient: true,
                                  gradientColors: [
                                    glassmorphicTheme.accentColor.withOpacity(
                                      0.1,
                                    ),
                                    glassmorphicTheme.secondaryAccentColor
                                        .withOpacity(0.05),
                                  ],
                                  child: SafeArea(
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      CupertinoColors
                                                          .systemIndigo,
                                                      CupertinoColors
                                                          .systemBlue,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  CupertinoIcons.calendar_today,
                                                  color: CupertinoColors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Flowo',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          isDarkMode
                                                              ? CupertinoColors
                                                                  .white
                                                              : CupertinoColors
                                                                  .black,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Smart Time Management',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          CupertinoColors
                                                              .systemGrey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            physics:
                                                const ClampingScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            itemCount: _pageData.length,
                                            itemBuilder: (context, index) {
                                              final item = _pageData[index];
                                              return SidebarMenuItem(
                                                icon: item.icon,
                                                label: item.label,
                                                accentColor: item.accentColor,
                                                isSelected:
                                                    index == _selectedIndex,
                                                onTap:
                                                    () =>
                                                        _navigateToPage(index),
                                              );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'Flowo v1.0.0',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color:
                                        isDarkMode
                                            ? CupertinoColors.black.withOpacity(
                                              0.4,
                                            )
                                            : CupertinoColors.systemGrey
                                                .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }
}
