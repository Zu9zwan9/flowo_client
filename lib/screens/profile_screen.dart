import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart';
import 'dart:io';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully')),
    );
    logInfo('Profile updated: $name, $email');
  }

  void _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account and all data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account deleted successfully')),
      );
      logWarning('Account deleted');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
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

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarImage != null ? FileImage(_avatarImage!) : const AssetImage('assets/avatar.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _changeAvatar,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: themeNotifier.textColor),
              ),
              style: TextStyle(color: themeNotifier.textColor),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: themeNotifier.textColor),
              ),
              style: TextStyle(color: themeNotifier.textColor),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: themeNotifier.textColor),
              ),
              style: TextStyle(color: themeNotifier.textColor),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete Account and All Data'),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Appearance'),
              trailing: DropdownButton<String>(
                value: themeNotifier.currentTheme.brightness == Brightness.light ? 'Light' : 'Dark',
                items: const [
                  DropdownMenuItem(value: 'Light', child: Text('Light')),
                  DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                  DropdownMenuItem(value: 'Night', child: Text('Night')),
                  DropdownMenuItem(value: 'ADHD', child: Text('ADHD-friendly')),
                ],
                onChanged: _changeAppearance,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Font'),
              trailing: DropdownButton<String>(
                value: themeNotifier.currentFont,
                items: const [
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                  DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                  DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman')),
                ],
                onChanged: _changeFont,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
