import 'package:flutter/material.dart';
import 'notification_service.dart';
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
          appBar: AppBar(title: const Text('Settings')),
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
                      subtitle: const Text('Enable daily learning reminders'),
                      value: s.notificationsEnabled,
                      onChanged: (value) async {
                        await controller.setNotificationsEnabled(value);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Notifications enabled (daily reminder at 8:00 PM)'
                                    : 'Notifications disabled',
                              ),
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
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await controller.setLanguageCode(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Notifications Debug',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notification_add_outlined),
                      title: const Text('Send test notification'),
                      subtitle: const Text('Show immediately'),
                      onTap: () async {
                        final granted =
                            await NotificationService.instance.requestPermissions();
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification permission denied')),
                          );
                          return;
                        }

                        await NotificationService.instance.showInstantStudyReminder(
                          title: 'Test notification ✅',
                          body: 'Notifications are working on this device.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: const Text('Schedule reminder in 1 minute'),
                      subtitle: const Text('Quick test schedule'),
                      onTap: () async {
                        final now = TimeOfDay.now();
                        final testMinute = (now.minute + 1) % 60;
                        final testHour =
                            now.minute == 59 ? (now.hour + 1) % 24 : now.hour;

                        final granted =
                            await NotificationService.instance.requestPermissions();
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification permission denied')),
                          );
                          return;
                        }

                        await NotificationService.instance.scheduleDailyStudyReminder(
                          hour: testHour,
                          minute: testMinute,
                          title: 'Scheduled test reminder ⏰',
                          body: 'This should fire at the next minute (then repeat daily).',
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Scheduled for ${testHour.toString().padLeft(2, '0')}:${testMinute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cancel_outlined),
                      title: const Text('Cancel daily reminder'),
                      onTap: () async {
                        await NotificationService.instance.cancelDailyStudyReminder();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Daily reminder cancelled')),
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
