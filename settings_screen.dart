import 'package:flutter/material.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _languageLabel(String code) {
    switch (code) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = SettingsController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final s = controller.settings;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme across the app'),
                      value: s.darkMode,
                      onChanged: (value) async {
                        await controller.setDarkMode(value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: const Text('Enable learning reminders and updates'),
                      value: s.notificationsEnabled,
                      onChanged: (value) async {
                        await controller.setNotificationsEnabled(value);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Notifications enabled'
                                    : 'Notifications disabled',
                              ),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: Text(_languageLabel(s.languageCode)),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: s.languageCode,
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'vi',
                              child: Text('Tiếng Việt'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await controller.setLanguageCode(value);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Language set to ${_languageLabel(value)}',
                                  ),
                                  duration: const Duration(milliseconds: 900),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'App',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('Educational App v1.0.0'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Educational App',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2026 Your Team',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Reset Settings'),
                      subtitle: const Text('Restore default preferences'),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Reset Settings?'),
                                content: const Text(
                                  'This will reset theme, notifications, and language to default values.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!confirmed) return;

                        await controller.resetToDefaults();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings reset to default'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
