import 'package:flutter/cupertino.dart';

import '../../../models/task.dart';

class TaskDescription extends StatelessWidget {
  final Task task;
  final TextEditingController controller;

  const TaskDescription({
    required this.task,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Description',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: 'Add notes about this task...',
            minLines: 3,
            maxLines: 5,
            padding: const EdgeInsets.all(10),
            style: theme.textTheme.textStyle,
            decoration: BoxDecoration(
              border: Border.all(color: theme.barBackgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {
              task.notes = value.isEmpty ? null : value;
              task.save();
            },
          ),
        ],
      ),
    );
  }
}
