import 'package:flutter/cupertino.dart';
import 'tutorial_screen.dart';

/// A simple wrapper for the TutorialScreen to be used in other parts of the app.
class TutorialLauncher extends StatelessWidget {
  const TutorialLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return const TutorialScreen();
  }
}
