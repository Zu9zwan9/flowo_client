import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _avatarImage;

  void _changeAvatar() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
      logInfo('Avatar image changed');
    }
  }

  void _updateProfile() {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Profile Updated'),
        content: const Text('Profile updated successfully'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
    logInfo('Profile updated: $name, $email');
  }

  void _deleteAccount() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account and all data?'),
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

    if (confirm == true) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Account Deleted'),
          content: const Text('Account deleted successfully'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            )
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
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar section
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CupertinoButton(
                    onPressed: _changeAvatar,
                    child: _avatarImage != null
                        ? Image.file(_avatarImage!, width: 100, height: 100)
                        : const Icon(CupertinoIcons.person_circle, size: 100),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _changeAvatar,
                    child: const Icon(CupertinoIcons.camera, size: 28),
                  )
                ],
              ),
              const SizedBox(height: 20),
              // Name field
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Name',
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 20),
              // Email field
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 20),
              // Password field
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                padding: const EdgeInsets.all(12),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // Update Profile Button
              CupertinoButton.filled(
                onPressed: _updateProfile,
                child: const Text('Update Profile'),
              ),
              const SizedBox(height: 20),
              // Delete Account Button
              CupertinoButton.filled(
                onPressed: _deleteAccount,
                child: const Text('Delete Account and All Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
