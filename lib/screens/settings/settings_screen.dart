import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Profile',
      'Change Password',
      'Notifications',
      'Payment Method',
      'Favorite Diets',
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x12FFFFFF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harit Cooper',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'harit@email.com',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.panel,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x12FFFFFF)),
              ),
              child: Column(
                children: [
                  for (final item in items) _SettingsTile(label: item),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _StandaloneTile(label: 'Meal Preferences'),
            const SizedBox(height: 12),
            const _StandaloneTile(label: 'Subscription'),
            const SizedBox(height: 12),
            const _StandaloneTile(label: 'Log Out'),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
    );
  }
}

class _StandaloneTile extends StatelessWidget {
  const _StandaloneTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white70,
        ),
      ),
    );
  }
}
