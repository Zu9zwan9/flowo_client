import 'dart:io';
import 'dart:math';

import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
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
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Get the app's documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${appDir.path}/$fileName');

        // Copy the picked image to the app's documents directory
        await File(pickedFile.path).copy(savedImage.path);

        setState(() {
          _avatarImage = savedImage;
          _isUploading = false;
        });

        // Update the avatar path in the user profile
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
      // For initials avatar, we'll just clear the file
      // so the initials will be shown in the UI
      setState(() {
        _avatarImage = null;
        _isUploading = false;
      });

      // Clear the avatar path in the user profile
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

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUpdating = true);

      try {
        if (_currentProfile == null) {
          // Create a new profile if none exists
          _currentProfile = UserProfile(
            name: _nameController.text,
            email: _emailController.text,
            avatarPath: _avatarImage?.path,
          );
        } else {
          // Update existing profile
          _currentProfile!.name = _nameController.text;
          _currentProfile!.email = _emailController.text;
          _currentProfile!.avatarPath = _avatarImage?.path;
        }

        // Save to Hive
        await _userProfilesBox.put('current', _currentProfile!);

        setState(() => _isUpdating = false);

        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Profile Updated'),
              content: const Text(
                  'Your profile information has been updated successfully.'),
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
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
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
  }

  Future<void> _deleteAccount() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account and all associated data? This action cannot be undone.'),
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
        // Delete the avatar file if it exists
        if (_currentProfile?.avatarPath != null) {
          final avatarFile = File(_currentProfile!.avatarPath!);
          if (avatarFile.existsSync()) {
            await avatarFile.delete();
            logInfo('Deleted avatar file: ${_currentProfile!.avatarPath}');
          }
        }

        // Delete the user profile from the Hive box
        await _userProfilesBox.delete('current');
        _currentProfile = null;

        // Clear the form
        setState(() {
          _nameController.clear();
          _emailController.clear();
          _avatarImage = null;
        });

        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Account Deleted'),
            content: const Text('Your account has been deleted successfully.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
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
            builder: (_) => CupertinoAlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profile'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _nameController,
                  placeholder: 'Name',
                  validator: (value) =>
                      value!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  placeholder: 'Email',
                  validator: (value) => value!.isEmpty ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 32),
                _buildActionButton(
                  text: 'Update Profile',
                  color: CupertinoColors.activeBlue,
                  onPressed: _updateProfile,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'Delete Account',
                  color: CupertinoColors.systemRed,
                  onPressed: _deleteAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final initials = _nameController.text.trim().isNotEmpty
        ? _nameController.text
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : '??';

    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarOptions,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemGrey4,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _isUploading
                ? const CupertinoActivityIndicator(radius: 20)
                : _avatarImage != null
                    ? Image.file(_avatarImage!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAvatarOptions,
          child: const Text('Change Avatar',
              style: TextStyle(color: CupertinoColors.activeBlue)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      style: const TextStyle(fontSize: 16),
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: color,
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white),
      ),
    );
  }

  void _showAvatarOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Avatar Options'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Upload from Gallery'),
            onPressed: () {
              _changeAvatar();
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Generate from Initials'),
            onPressed: () {
              _generateAvatar();
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
