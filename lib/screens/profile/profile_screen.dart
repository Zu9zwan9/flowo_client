import 'dart:io';

import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/screens/analytics/analytics_screen.dart';
import 'package:flowo_client/screens/onboarding/name_input_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _avatarImage;
  bool _isUploading = false;
  bool _isUpdating = false;
  late Box<UserProfile> _userProfilesBox;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfilesBox = await Hive.openBox<UserProfile>('user_profiles');
      final profile = _userProfilesBox.get('current');

      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          _nameController.text = profile.name;
          _emailController.text = profile.email;

          if (profile.avatarPath != null) {
            _avatarImage = File(profile.avatarPath!);
            if (!_avatarImage!.existsSync()) {
              _avatarImage = null;
            }
          }
        });
        logInfo('Loaded user profile: ${profile.name}');
      } else {
        logWarning('No user profile found');
      }
    } catch (e) {
      logError('Error loading user profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    setState(() => _isUploading = true);

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');

        await File(pickedFile.path).copy(savedImage.path);

        setState(() {
          _avatarImage = savedImage;
          _isUploading = false;
        });

        if (_currentProfile != null) {
          _currentProfile!.avatarPath = savedImage.path;
          await _userProfilesBox.put('current', _currentProfile!);
        }

        logInfo('Avatar saved to: ${savedImage.path}');
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      logError('Error changing avatar: $e');
    }
  }

  Future<void> _generateAvatar() async {
    setState(() => _isUploading = true);

    try {
      setState(() {
        _avatarImage = null;
        _isUploading = false;
      });

      if (_currentProfile != null) {
        _currentProfile!.avatarPath = null;
        await _userProfilesBox.put('current', _currentProfile!);
      }

      logInfo('Avatar generated from initials');
    } catch (e) {
      setState(() => _isUploading = false);
      logError('Error generating avatar: $e');
    }
  }

  String? _nameError;
  String? _emailError;

  Future<void> _validateAndUpdateProfile() async {
    setState(() {
      _nameError = null;
      _emailError = null;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Name is required';
      });
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
      return;
    } else if (!RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    ).hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Enter a valid email address';
      });
      return;
    }

    await _updateProfile();
  }

  Future<void> _updateProfile() async {
    setState(() => _isUpdating = true);

    try {
      if (_currentProfile == null) {
        _currentProfile = UserProfile(
          name: _nameController.text,
          email: _emailController.text,
          avatarPath: _avatarImage?.path,
        );
      } else {
        _currentProfile!.name = _nameController.text;
        _currentProfile!.email = _emailController.text;
        _currentProfile!.avatarPath = _avatarImage?.path;
      }

      await _userProfilesBox.put('current', _currentProfile!);

      setState(() => _isUpdating = false);

      if (mounted) {
        HapticFeedback.mediumImpact();

        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text('Profile Updated'),
                content: const Text(
                  'Your profile information has been updated successfully.',
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }

      logInfo('Profile updated successfully');
    } catch (e) {
      setState(() => _isUpdating = false);
      logError('Error updating profile: $e');

      if (mounted) {
        HapticFeedback.vibrate();

        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text('Update Failed'),
                content: Text('Failed to update profile: ${e.toString()}'),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account and all associated data? This action cannot be undone.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        if (_currentProfile?.avatarPath != null) {
          final avatarFile = File(_currentProfile!.avatarPath!);
          if (avatarFile.existsSync()) {
            await avatarFile.delete();
            logInfo('Deleted avatar file: ${_currentProfile!.avatarPath}');
          }
        }

        await _userProfilesBox.delete('current');
        _currentProfile = null;

        setState(() {
          _nameController.clear();
          _emailController.clear();
          _avatarImage = null;
        });

        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
                title: const Text('Account Deleted'),
                content: const Text(
                  'Your account has been deleted successfully.',
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          CupertinoPageRoute(
                            builder: (context) => const NameInputScreen(),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      }
                    },
                  ),
                ],
              ),
        );
        logWarning('Account deleted');
      } catch (e) {
        logError('Error deleting account: $e');
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder:
                (_) => CupertinoAlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to delete account: ${e.toString()}'),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
          );
        }
      }
    }
  }

  Future<void> _clearAppData() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Clear All App Data'),
            content: const Text(
              'Are you sure you want to clear all app data? This will reset the app to its initial state, deleting all tasks, settings, and profile information. This action cannot be undone.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Clear Data'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        // Delete avatar file if exists
        if (_currentProfile?.avatarPath != null) {
          final avatarFile = File(_currentProfile!.avatarPath!);
          if (avatarFile.existsSync()) {
            await avatarFile.delete();
            logInfo('Deleted avatar file: ${_currentProfile!.avatarPath}');
          }
        }

        // First close our known box reference
        await _userProfilesBox.close();
        logInfo('Closed user_profiles box directly');

        // List all the box names used in the app
        final boxNames = [
          'tasks',
          'scheduled_tasks',
          'user_settings',
          'user_profiles',
          'pomodoro_sessions',
          'categories_box',
          'ambient_scenes',
        ];

        // Process each box
        for (final boxName in boxNames) {
          try {
            final box = Hive.box(boxName);
            await box.clear();
          } catch (e) {
            // Log but continue with other boxes
            logWarning('Issue with box $boxName during reset: $e');
          }
        }

        // Update UI state
        setState(() {
          _nameController.clear();
          _emailController.clear();
          _avatarImage = null;
          _currentProfile = null;
        });

        // Show confirmation dialog
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder:
                (_) => CupertinoAlertDialog(
                  title: const Text('App Data Cleared'),
                  content: const Text(
                    'All app data has been cleared successfully. The app will now restart as if opened for the first time.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (mounted) {
                          // Navigate to the onboarding screen
                          Navigator.of(context).pushAndRemoveUntil(
                            CupertinoPageRoute(
                              builder: (context) => const NameInputScreen(),
                            ),
                            (route) => false, // Remove all previous routes
                          );
                        }
                      },
                    ),
                  ],
                ),
          );
        }
        logWarning('All app data cleared');
      } catch (e) {
        logError('Error clearing app data: $e');
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder:
                (_) => CupertinoAlertDialog(
                  title: const Text('Error'),
                  content: Text('Failed to clear app data: ${e.toString()}'),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatarSection(),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemBackground.darkColor
                        : CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey5.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      top: 16.0,
                      bottom: 8.0,
                    ),
                    child: Text(
                      'PERSONAL INFORMATION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: _buildNameField(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    child: _buildEmailField(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 8.0,
              ),
              child: Text(
                'Your personal information is used to identify you in the app.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemBackground.darkColor
                        : CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey5.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(16),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _validateAndUpdateProfile();
                    },
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_crop_circle_badge_checkmark,
                          color: CupertinoColors.activeBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Update Profile',
                            style: TextStyle(
                              color: CupertinoTheme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey2,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: CupertinoColors.systemGrey5,
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(16),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.graph_circle,
                          color: CupertinoColors.activeOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View Analytics & Insights',
                            style: TextStyle(
                              color: CupertinoTheme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey2,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemBackground.darkColor
                        : CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey5.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      top: 16.0,
                      bottom: 8.0,
                    ),
                    child: Text(
                      'DANGER ZONE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemRed,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(16),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _deleteAccount();
                    },
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.systemRed,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: CupertinoColors.systemGrey5,
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(16),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _clearAppData();
                    },
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.trash,
                          color: CupertinoColors.systemRed,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Clear App Data',
                            style: TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 8.0,
              ),
              child: Text(
                'Deleting your account or clearing app data will permanently remove all your data from the app. These actions cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Flowo v1.0.0',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final initials =
        _nameController.text.trim().isNotEmpty
            ? _nameController.text
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase()
            : '??';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          Semantics(
            label: 'Profile picture',
            hint: 'Double tap to change your profile picture',
            image: _avatarImage != null,
            button: true,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showAvatarOptions();
              },
              child: Hero(
                tag: 'profile_avatar',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.systemGrey5.darkColor
                            : CupertinoColors.systemGrey5,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      _isUploading
                          ? const CupertinoActivityIndicator(radius: 20)
                          : _avatarImage != null
                          ? Image.file(
                            _avatarImage!,
                            fit: BoxFit.cover,
                            semanticLabel: 'Your profile picture',
                          )
                          : Center(
                            child: ExcludeSemantics(
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      CupertinoTheme.of(context).brightness ==
                                              Brightness.dark
                                          ? CupertinoColors.white
                                          : CupertinoColors.black,
                                ),
                              ),
                            ),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Change avatar button',
            hint: 'Double tap to change your profile picture',
            button: true,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.selectionClick();
                _showAvatarOptions();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.camera,
                    size: 16,
                    color: CupertinoTheme.of(context).primaryColor,
                    semanticLabel: 'Camera icon',
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Change Avatar',
                    style: TextStyle(
                      color: CupertinoTheme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_nameController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Semantics(
                label: 'User name: ${_nameController.text}',
                header: true,
                child: Text(
                  _nameController.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        CupertinoTheme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.person,
                size: 18,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Name text field',
            hint: 'Enter your full name',
            textField: true,
            child: CupertinoTextField(
              controller: _nameController,
              placeholder: 'Enter your name',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      _nameError != null
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey4,
                ),
              ),
              style: const TextStyle(fontSize: 16),
              placeholderStyle: const TextStyle(
                color: CupertinoColors.systemGrey2,
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                  semanticLabel: 'Person icon',
                ),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                if (_nameError != null) {
                  setState(() {
                    _nameError = null;
                  });
                }
              },
              autofocus: false,
              autocorrect: true,
              enableSuggestions: true,
            ),
          ),
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 12.0),
              child: Semantics(
                label: 'Name error: $_nameError',
                liveRegion: true,
                child: Text(
                  _nameError!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.mail,
                size: 18,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Email text field',
            hint: 'Enter your email address',
            textField: true,
            child: CupertinoTextField(
              controller: _emailController,
              placeholder: 'Enter your email',
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      _emailError != null
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemGrey4,
                ),
              ),
              style: const TextStyle(fontSize: 16),
              placeholderStyle: const TextStyle(
                color: CupertinoColors.systemGrey2,
              ),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(
                  CupertinoIcons.mail_solid,
                  color: CupertinoColors.systemGrey,
                  size: 18,
                  semanticLabel: 'Email icon',
                ),
              ),
              clearButtonMode: OverlayVisibilityMode.editing,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              onChanged: (value) {
                if (_emailError != null) {
                  setState(() {
                    _emailError = null;
                  });
                }
              },
              autofocus: false,
              enableSuggestions: true,
              textCapitalization: TextCapitalization.none,
            ),
          ),
          if (_emailError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 12.0),
              child: Semantics(
                label: 'Email error: $_emailError',
                liveRegion: true,
                child: Text(
                  _emailError!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAvatarOptions() {
    HapticFeedback.mediumImpact();

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Avatar Options'),
            message: const Text(
              'Choose how you want to set your profile picture',
            ),
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.activeBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Upload from Gallery',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ],
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _changeAvatar();
                  Navigator.pop(context);
                },
              ),
              CupertinoActionSheetAction(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.textformat_abc,
                      color: CupertinoColors.activeBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Generate from Initials',
                      style: TextStyle(color: CupertinoColors.activeBlue),
                    ),
                  ],
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _generateAvatar();
                  Navigator.pop(context);
                },
              ),
              if (Platform.isIOS || Platform.isAndroid)
                CupertinoActionSheetAction(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.camera,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Take Photo',
                        style: TextStyle(color: CupertinoColors.activeBlue),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);

                    setState(() => _isUploading = true);
                    try {
                      final pickedFile = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        preferredCameraDevice: CameraDevice.front,
                      );

                      if (pickedFile != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName =
                            'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final savedImage = File('${appDir.path}/$fileName');

                        await File(pickedFile.path).copy(savedImage.path);

                        setState(() {
                          _avatarImage = savedImage;
                          _isUploading = false;
                        });

                        if (_currentProfile != null) {
                          _currentProfile!.avatarPath = savedImage.path;
                          await _userProfilesBox.put(
                            'current',
                            _currentProfile!,
                          );
                        }

                        logInfo('Avatar saved to: ${savedImage.path}');
                      } else {
                        setState(() => _isUploading = false);
                      }
                    } catch (e) {
                      setState(() => _isUploading = false);
                      logError('Error taking photo: $e');
                    }
                  },
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('Cancel'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ),
    );
  }
}
