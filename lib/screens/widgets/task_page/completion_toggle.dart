import 'package:flutter/cupertino.dart';

class CompletionToggle extends StatelessWidget {
  final bool isDone;
  final VoidCallback onPressed;

  const CompletionToggle({
    required this.isDone,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color:
                isDone
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemGrey,
            size: 18,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isDone ? 'Completed' : 'Mark as completed',
              style: theme.textTheme.textStyle.copyWith(
                color:
                    isDone
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemGrey,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
