import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: Text(_themeLabel(settings.themeMode)),
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                settings.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            onTap: () {
              final next = settings.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              settings.setThemeMode(next);
            },
          ),
          const Divider(height: 1),

          // Row 2: Notifications enable/disable
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Enable Notifications'),
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (val) {
                settings.setNotificationsEnabled(val);
              },
            ),
            onTap: () {
              settings.setNotificationsEnabled(!settings.notificationsEnabled);
            },
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }
}


