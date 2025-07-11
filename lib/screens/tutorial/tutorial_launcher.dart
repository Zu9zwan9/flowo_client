import 'package:flutter/cupertino.dart';
import 'package:flowo_client/screens/onboarding/enhanced/welcome_screen.dart';

/// A simple wrapper for the TutorialScreen to be used in other parts of the app.
class TutorialLauncher extends StatelessWidget {
  const TutorialLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    // Launch enhanced onboarding as tutorial, skip name and goal inputs
    return const EnhancedWelcomeScreen(skipNameGoal: true);
  }
}
