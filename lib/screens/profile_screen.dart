import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme_notifier.dart';
import '../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _avatarImage;

  void _changeAvatar() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
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
        content: const Text(
            'Are you sure you want to delete your account and all data?'),
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

  void _changeAppearance(String? value) {
    if (value != null) {
      Provider.of<ThemeNotifier>(context, listen: false).setTheme(value);
      logInfo('Appearance changed to: $value');
    }
  }

  void _changeFont(String? value) {
    if (value != null) {
      Provider.of<ThemeNotifier>(context, listen: false).setFont(value);
      logInfo('Font changed to: $value');
    }
  }

  Future<void> _selectOption({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        int initialIndex = options.indexOf(currentValue);
        FixedExtentScrollController scrollController =
        FixedExtentScrollController(initialItem: initialIndex);
        return Container(
          height: 250,
          padding: const EdgeInsets.only(top: 6.0),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              // Header for the picker
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () {
                        final selected = options[scrollController.selectedItem];
                        onSelected(selected);
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: scrollController,
                  itemExtent: 32.0,
                  onSelectedItemChanged: (int index) {},
                  children: options
                      .map((option) => Center(child: Text(option)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final currentAppearance =
    themeNotifier.currentTheme.brightness == Brightness.light
        ? 'Light'
        : 'Dark';
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
                        : const Image(image: AssetImage('assets/avatar.png'), width: 100, height: 100),
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
                style: TextStyle(color: themeNotifier.textColor),
              ),
              const SizedBox(height: 20),
              // Email field
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                padding: const EdgeInsets.all(12),
                style: TextStyle(color: themeNotifier.textColor),
              ),
              const SizedBox(height: 20),
              // Password field
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                padding: const EdgeInsets.all(12),
                style: TextStyle(color: themeNotifier.textColor),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // Update Profile Button
              CupertinoButton.filled(
                child: const Text('Update Profile'),
                onPressed: _updateProfile,
              ),
              const SizedBox(height: 20),
              // Delete Account Button
              CupertinoButton.filled(
                child: const Text('Delete Account and All Data'),
                onPressed: _deleteAccount,
              ),
              const SizedBox(height: 20),
              // Appearance Selector
              CupertinoListTile(
                title: const Text('Appearance'),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(currentAppearance),
                  onPressed: () async {
                    await _selectOption(
                      context: context,
                      title: 'Select Appearance',
                      options: const ['Light', 'Dark', 'Night', 'ADHD-friendly'],
                      currentValue: currentAppearance,
                      onSelected: _changeAppearance,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Font Selector
              CupertinoListTile(
                title: const Text('Font'),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(themeNotifier.currentFont),
                  onPressed: () async {
                    await _selectOption(
                      context: context,
                      title: 'Select Font',
                      options: const ['Roboto', 'Arial', 'Times New Roman'],
                      currentValue: themeNotifier.currentFont,
                      onSelected: _changeFont,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CupertinoListTile is not provided by default in the Cupertino package.
/// This helper widget replicates a ListTile-like look and feel for Cupertino design.
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget trailing;
  final VoidCallback? onTap;

  const CupertinoListTile(
      {Key? key, required this.title, required this.trailing, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DefaultTextStyle(
              style: const TextStyle(fontSize: 16),
              child: title,
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}