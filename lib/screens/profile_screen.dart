import 'dart:io';

import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _avatarImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    try {
      setState(() => _isUploading = true);
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _avatarImage = File(pickedFile.path);
          _isUploading = false;
        });
        logInfo('Avatar image uploaded: ${pickedFile.path}');
      } else {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      logError('Failed to upload avatar: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to upload image: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _generateAvatar() {
    if (mounted) {
      setState(() {
        _avatarImage = null; // Reset to trigger initials-based avatar
      });
      final name = _nameController.text.trim();
      logInfo('Avatar reset to auto-generated with name: "$name"');
    }
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final email = _emailController.text;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Profile Updated'),
          content: const Text('Your profile has been updated successfully.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      logInfo('Profile updated: Name: $name, Email: $email');
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
          child: const Text('Change Avatar',
              style: TextStyle(color: CupertinoColors.activeBlue)),
          onPressed: _showAvatarOptions,
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
