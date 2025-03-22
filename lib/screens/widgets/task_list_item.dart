import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../models/task.dart';
import '../../theme_notifier.dart';

/// A glassmorphic task list item with vibrant accents
class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color categoryColor;
  final bool hasSubtasks;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onToggleCompletion;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.categoryColor,
    this.hasSubtasks = false,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onToggleCompletion,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25, // 90 degrees (1/4 of a full rotation)
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    final textColor = CupertinoColors.label.resolveFrom(context);
    final secondaryTextColor = CupertinoColors.secondaryLabel.resolveFrom(
      context,
    );
    final taskColor =
        widget.task.color != null
            ? Color(widget.task.color!)
            : widget.categoryColor;

    // Determine if we should use a gradient based on task properties
    final useGradient = !widget.task.isDone && widget.task.priority > 1;

    // Create gradient colors based on task color
    final gradientColors = [taskColor, taskColor.withOpacity(0.7)];

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() => _isPressed = false);
          }
        });
        widget.onTap();
      },
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(12),
        blur: glassmorphicTheme.defaultBlur * 0.8,
        opacity: _isPressed ? 0.3 : 0.2,
        borderRadius: BorderRadius.circular(16),
        borderWidth: 1.5,
        borderColor: taskColor.withOpacity(0.3),
        backgroundColor:
            isDarkMode
                ? CupertinoColors.darkBackgroundGray.withOpacity(0.4)
                : CupertinoColors.white.withOpacity(0.4),
        useGradient: useGradient,
        gradientColors: gradientColors,
        showShimmer: widget.task.priority > 2 && !widget.task.isDone,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 46,
              decoration: BoxDecoration(
                color: taskColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.task.title} (${widget.task.scheduledTasks.length})',
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.task.isDone ? secondaryTextColor : textColor,
                      decoration:
                          widget.task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.task.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.task.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        decoration:
                            widget.task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.hasSubtasks && widget.onToggleExpand != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onToggleExpand,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle:
                          _expandAnimation.value *
                          2 *
                          3.14159, // Convert to radians
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                    );
                  },
                ),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onToggleCompletion,
              child: Icon(
                widget.task.isDone
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color:
                    widget.task.isDone
                        ? glassmorphicTheme.accentColor
                        : secondaryTextColor,
                size: 24,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.pencil,
                size: 24,
                color: secondaryTextColor,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onEdit();
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.delete,
                size: 24,
                color: glassmorphicTheme.secondaryAccentColor,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
