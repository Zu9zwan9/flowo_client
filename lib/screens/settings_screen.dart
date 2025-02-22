import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Theme',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            CupertinoSegmentedControl<String>(
              children: const {
                'Light': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Light'),
                ),
                'Night': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Night'),
                ),
                'ADHD': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('ADHD'),
                ),
              },
              onValueChanged: (String value) {
                themeNotifier.setTheme(value);
              },
            ),
            const SizedBox(height: 32.0),
            const Text(
              'Font',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            CupertinoSegmentedControl<String>(
              children: const {
                'Roboto': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Roboto'),
                ),
                'Arial': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Arial'),
                ),
                'Times': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('Times'),
                ),
              },
              groupValue: themeNotifier.currentFont,
              onValueChanged: (String value) {
                themeNotifier.setFont(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
