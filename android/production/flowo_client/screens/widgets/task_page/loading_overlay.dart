import 'package:flutter/cupertino.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemBackground.withOpacity(0.7),
      child: const Center(child: CupertinoActivityIndicator(radius: 20)),
    );
  }
}
