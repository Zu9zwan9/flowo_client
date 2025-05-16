import 'package:flutter/cupertino.dart';

class CupertinoDivider extends StatelessWidget {
  final double height;
  final Color? color;

  const CupertinoDivider({super.key, this.height = 1.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color ?? CupertinoColors.systemGrey5,
    );
  }
}
