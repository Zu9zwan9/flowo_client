import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../design/glassmorphic_container.dart';
import '../design/glassmorphic_form_widgets.dart';
import '../models/task.dart';
import '../theme_notifier.dart';
import 'pomodoro_screen.dart';

class TaskSelectionScreen extends StatefulWidget {
  const TaskSelectionScreen({Key? key}) : super(key: key);

  @override
  State<TaskSelectionScreen> createState() => _TaskSelectionScreenState();
}

class _TaskSelectionScreenState extends State<TaskSelectionScreen> {
  Task? _selectedTask;
  int _customDuration = 25 * 60 * 1000; // Default 25 minutes
  bool _useCustomDuration = false;

  @override
  Widget build(BuildContext context) {
    // Access theme notifier for glassmorphic styling
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    final tasksBox = Hive.box<Task>('tasks');
    final tasks = tasksBox.values.where((task) => !task.isDone).toList();

    // Create vibrant color accents
    final primaryColor = themeNotifier.primaryColor;
    final accentColor = CupertinoColors.systemTeal;
    final secondaryAccent = CupertinoColors.systemIndigo;

    // Create gradient colors for various elements
    final headerGradient = [
      primaryColor.withOpacity(0.7),
      accentColor.withOpacity(0.5),
    ];

    final buttonGradient = [primaryColor, secondaryAccent];

    return CupertinoPageScaffold(
      // Apply glassmorphic styling to navigation bar
      navigationBar: CupertinoNavigationBar(
        backgroundColor: themeNotifier.backgroundColor.withOpacity(0.8),
        border: null, // Remove default border
        middle: const Text(
          'Select Task for Pomodoro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      child: Container(
        // Add a subtle gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeNotifier.backgroundColor,
              themeNotifier.backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glassmorphic section title
                GlassmorphicContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  borderRadius: BorderRadius.circular(16.0),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: glassmorphicTheme.defaultOpacity,
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor: headerGradient[0].withOpacity(0.3),
                  backgroundColor: headerGradient[1].withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose a task to work on:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a task for your Pomodoro focus session',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Task selection list with glassmorphic styling
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: glassmorphicTheme.defaultBlur / 2,
                        sigmaY: glassmorphicTheme.defaultBlur / 2,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeNotifier.backgroundColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: glassmorphicTheme.borderColor,
                            width: glassmorphicTheme.defaultBorderWidth,
                          ),
                        ),
                        child:
                            tasks.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.doc_text_search,
                                        size: 48,
                                        color: CupertinoColors.systemGrey
                                            .withOpacity(0.6),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No tasks available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Create a task first to start a Pomodoro session',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: tasks.length,
                                  itemBuilder: (context, index) {
                                    final task = tasks[index];
                                    final isSelected =
                                        _selectedTask?.id == task.id;

                                    // Determine task color based on priority or category
                                    final taskColor =
                                        isSelected
                                            ? primaryColor
                                            : index % 3 == 0
                                            ? accentColor
                                            : index % 3 == 1
                                            ? secondaryAccent
                                            : CupertinoColors.systemOrange;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTask = task;
                                          });
                                        },
                                        child: GlassmorphicContainer(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          blur: glassmorphicTheme.defaultBlur,
                                          opacity: isSelected ? 0.25 : 0.15,
                                          borderWidth:
                                              glassmorphicTheme
                                                  .defaultBorderWidth,
                                          borderColor:
                                              isSelected
                                                  ? taskColor.withOpacity(0.6)
                                                  : glassmorphicTheme
                                                      .borderColor,
                                          backgroundColor:
                                              isSelected
                                                  ? taskColor.withOpacity(0.15)
                                                  : themeNotifier
                                                      .backgroundColor
                                                      .withOpacity(0.1),
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Task status icon with animated container
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      isSelected
                                                          ? taskColor
                                                              .withOpacity(0.2)
                                                          : themeNotifier
                                                              .backgroundColor
                                                              .withOpacity(0.1),
                                                  border: Border.all(
                                                    color: taskColor
                                                        .withOpacity(0.5),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    isSelected
                                                        ? CupertinoIcons
                                                            .checkmark_circle_fill
                                                        : CupertinoIcons.circle,
                                                    color: taskColor,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),

                                              // Task details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      task.title,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            isSelected
                                                                ? taskColor
                                                                : themeNotifier
                                                                    .textColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Estimated time: ${_formatTime(task.estimatedTime)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            CupertinoColors
                                                                .systemGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Duration selection with glassmorphic styling
                GlassmorphicContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  borderRadius: BorderRadius.circular(16.0),
                  blur: glassmorphicTheme.defaultBlur,
                  opacity: glassmorphicTheme.defaultOpacity,
                  borderWidth: glassmorphicTheme.defaultBorderWidth,
                  borderColor: buttonGradient[1].withOpacity(0.3),
                  backgroundColor: buttonGradient[0].withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Custom styled switch
                          Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color:
                                    _useCustomDuration
                                        ? primaryColor.withOpacity(0.6)
                                        : glassmorphicTheme.borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: CupertinoSwitch(
                              value: _useCustomDuration,
                              activeColor: primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _useCustomDuration = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Use custom duration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  _useCustomDuration
                                      ? primaryColor
                                      : themeNotifier.textColor,
                            ),
                          ),
                        ],
                      ),

                      if (_useCustomDuration) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Duration:',
                              style: TextStyle(
                                fontSize: 16,
                                color: themeNotifier.textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _formatTime(_customDuration),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Glassmorphic slider
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: glassmorphicTheme.defaultBlur / 2,
                              sigmaY: glassmorphicTheme.defaultBlur / 2,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeNotifier.backgroundColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: glassmorphicTheme.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '5 min',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                      Text(
                                        '60 min',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  CupertinoSlider(
                                    min: 5 * 60 * 1000, // 5 minutes
                                    max: 60 * 60 * 1000, // 60 minutes
                                    divisions: 55,
                                    activeColor: primaryColor,
                                    thumbColor: CupertinoColors.white,
                                    value: _customDuration.toDouble(),
                                    onChanged: (value) {
                                      setState(() {
                                        _customDuration = value.toInt();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Glassmorphic start button
                GestureDetector(
                  onTap:
                      _selectedTask != null || _useCustomDuration
                          ? () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (context) => PomodoroScreen(
                                      task: _selectedTask,
                                      customDuration:
                                          _useCustomDuration
                                              ? _customDuration
                                              : null,
                                    ),
                              ),
                            );
                          }
                          : null,
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 56,
                    borderRadius: BorderRadius.circular(16.0),
                    blur: glassmorphicTheme.defaultBlur,
                    opacity: 0.2,
                    borderWidth: glassmorphicTheme.defaultBorderWidth,
                    borderColor:
                        _selectedTask != null || _useCustomDuration
                            ? buttonGradient[0].withOpacity(0.6)
                            : CupertinoColors.systemGrey.withOpacity(0.3),
                    backgroundColor:
                        _selectedTask != null || _useCustomDuration
                            ? buttonGradient[1].withOpacity(0.3)
                            : CupertinoColors.systemGrey.withOpacity(0.1),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.timer,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start Pomodoro',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
