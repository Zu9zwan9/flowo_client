import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../design/glassmorphic_container.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../theme_notifier.dart';

class TaskBreakdownScreen extends StatelessWidget {
  final Task task;

  const TaskBreakdownScreen({required this.task, super.key});

  Future<List<Task>> generateTaskBreakdown(String taskDescription) async {
    // Simulate an API call to generate task breakdown
    await Future.delayed(Duration(seconds: 2));
    return [
      Task(
        id: UniqueKey().toString(),
        title: 'Subtask 1',
        priority: 1,
        deadline: 0,
        estimatedTime: 0,
        category: Category(name: 'General'),
      ),
      Task(
        id: UniqueKey().toString(),
        title: 'Subtask 2',
        priority: 1,
        deadline: 0,
        estimatedTime: 0,
        category: Category(name: 'General'),
      ),
      Task(
        id: UniqueKey().toString(),
        title: 'Subtask 3',
        priority: 1,
        deadline: 0,
        estimatedTime: 0,
        category: Category(name: 'General'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${task.title} - Subtasks'),
      ),
      child: FutureBuilder<List<Task>>(
        future: generateTaskBreakdown(task.notes ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No subtasks found'));
          } else {
            final subtasks = snapshot.data!;
            return ListView.builder(
              itemCount: subtasks.length,
              itemBuilder: (context, index) {
                return GlassmorphicCupertinoListTile(
                  title: Text(subtasks[index].title),
                  onTap: () {
                    // Handle tap on subtask
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

/// A Cupertino-style list tile with glassmorphic effect
class GlassmorphicCupertinoListTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double minLeadingWidth;
  final bool useGradient;
  final List<Color>? gradientColors;
  final bool showShimmer;

  const GlassmorphicCupertinoListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.minLeadingWidth = 28.0,
    this.useGradient = false,
    this.gradientColors,
    this.showShimmer = false,
    super.key,
  });

  @override
  State<GlassmorphicCupertinoListTile> createState() =>
      _GlassmorphicCupertinoListTileState();
}

class _GlassmorphicCupertinoListTileState
    extends State<GlassmorphicCupertinoListTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    final effectivePadding =
        widget.padding ??
        const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0);

    final effectiveBackgroundColor =
        widget.backgroundColor ??
        (isDarkMode
            ? CupertinoColors.darkBackgroundGray.withOpacity(0.4)
            : CupertinoColors.white.withOpacity(0.4));

    final effectiveGradientColors =
        widget.gradientColors ?? glassmorphicTheme.gradientColors;

    Widget content = Row(
      children: [
        if (widget.leading != null) ...[
          SizedBox(width: widget.minLeadingWidth, child: widget.leading),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(
                style: CupertinoTheme.of(context).textTheme.textStyle,
                child: widget.title,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.textStyle.copyWith(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                  child: widget.subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: GlassmorphicContainer(
          padding: effectivePadding,
          blur: glassmorphicTheme.defaultBlur * 0.7,
          opacity: _isPressed ? 0.3 : 0.2,
          borderRadius: BorderRadius.circular(12),
          borderWidth: 1.0,
          borderColor: glassmorphicTheme.accentColor.withOpacity(0.2),
          backgroundColor: effectiveBackgroundColor,
          useGradient: widget.useGradient,
          gradientColors: effectiveGradientColors,
          showShimmer: widget.showShimmer,
          child: content,
        ),
      ),
    );
  }
}
