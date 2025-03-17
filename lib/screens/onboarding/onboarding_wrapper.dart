import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/screens/onboarding/name_input_screen.dart';
import 'package:flowo_client/services/onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

/// A widget that checks if onboarding is completed and shows the appropriate screen
class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  late OnboardingService _onboardingService;
  bool _isOnboardingCompleted = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeOnboarding();
    }
  }

  void _initializeOnboarding() {
    final userProfileBox = Provider.of<Box<UserProfile>>(context);
    _onboardingService = OnboardingService(userProfileBox);

    setState(() {
      _isOnboardingCompleted = _onboardingService.isOnboardingCompleted();
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const CupertinoActivityIndicator();
    }

    return Provider<OnboardingService>.value(
      value: _onboardingService,
      child:
          _isOnboardingCompleted ? const HomeScreen() : const NameInputScreen(),
    );
  }
}
