import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/screens/onboarding/name_input_screen.dart';
import 'package:flowo_client/services/onboarding/onboarding_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../tutorial/tutorial_screen.dart';

/// A widget that checks if onboarding is completed and shows the appropriate screen
class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper>
    with SingleTickerProviderStateMixin {
  late OnboardingService _onboardingService;
  bool _isOnboardingCompleted = false;
  bool _isInitialized = false;
  bool _showTutorial = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeOnboarding();
    }
  }

  Future<void> _initializeOnboarding() async {
    final userProfileBox = Provider.of<Box<UserProfile>>(context);
    _onboardingService = OnboardingService(userProfileBox);

    // Simulate a short delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));

    // Provide haptic feedback when ready
    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        _isOnboardingCompleted = _onboardingService.isOnboardingCompleted();
        _showTutorial = _isOnboardingCompleted;
        _isInitialized = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    if (!_isInitialized) {
      return CupertinoPageScaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(radius: 15),
                const SizedBox(height: 16),
                Text(
                  'Loading your experience...',
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Provider<OnboardingService>.value(
      value: _onboardingService,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child:
            _isOnboardingCompleted
                ? _showTutorial
                    ? TutorialScreen(
                      onComplete: () {
                        setState(() {
                          _showTutorial = false;
                        });
                      },
                    )
                    : const HomeScreen(initialExpanded: false)
                : const NameInputScreen(),
      ),
    );
  }
}
