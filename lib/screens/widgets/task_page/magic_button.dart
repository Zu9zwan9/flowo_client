import 'package:flutter/cupertino.dart';

class MagicButton extends StatelessWidget {
  final VoidCallback onGenerate;

  const MagicButton({required this.onGenerate, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemIndigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: CupertinoColors.systemIndigo.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.sparkles,
            size: 40,
            color: CupertinoColors.systemIndigo,
          ),
          const SizedBox(height: 12),
          Text(
            'Task Breakdown Options',
            style: theme.textTheme.navTitleTextStyle.copyWith(
              color: CupertinoColors.systemIndigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let AI break this task into subtasks or add them manually below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onPressed: onGenerate,
            child: const Text('Generate Subtasks with AI'),
          ),
        ],
      ),
    );
  }
}
