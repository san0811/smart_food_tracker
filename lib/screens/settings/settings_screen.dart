import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/expiry_notification_settings.dart';
import '../../models/food_item.dart';
import '../../providers/food_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ExpiryNotificationSettings _notificationSettings =
      ExpiryNotificationSettings.defaults();
  bool _isNotificationSettingsLoaded = false;
  bool _compactInventory = false;
  bool _softMotion = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final settings =
        await DatabaseHelper.instance.getExpiryNotificationSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationSettings = settings;
      _isNotificationSettingsLoaded = true;
    });
  }

  Future<void> _saveNotificationSettings(FoodProvider provider) async {
    await DatabaseHelper.instance.saveExpiryNotificationSettings(
      _notificationSettings,
    );
    await provider.refreshExpiryNotifications();
  }

  void _setExpiryAlertsEnabled(bool value, FoodProvider provider) {
    setState(() {
      _notificationSettings = _notificationSettings.copyWith(enabled: value);
    });
    unawaited(_saveNotificationSettings(provider));
  }

  void _toggleReminderDay(int days, FoodProvider provider) {
    if (!_notificationSettings.enabled) {
      return;
    }

    setState(() {
      final updatedDays = Set<int>.from(_notificationSettings.reminderDays);
      if (updatedDays.contains(days)) {
        updatedDays.remove(days);
      } else {
        updatedDays.add(days);
      }
      _notificationSettings = _notificationSettings.copyWith(
        reminderDays: updatedDays,
      );
    });
    unawaited(_saveNotificationSettings(provider));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FoodProvider>(
      builder: (context, provider, _) {
        final mostAdded = _mostAddedItem(provider.items);

        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                _SettingsSection(
                  title: 'Notifications',
                  child: Column(
                    children: [
                      _SwitchRow(
                        icon: Icons.notifications_active_rounded,
                        title: 'Expiry alerts',
                        subtitle:
                            'Start daily reminders when items are nearing expiry',
                        value: _notificationSettings.enabled,
                        onChanged: _isNotificationSettingsLoaded
                            ? (value) => _setExpiryAlertsEnabled(
                                  value,
                                  provider,
                                )
                            : null,
                      ),
                      if (!_isNotificationSettingsLoaded) ...[
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Loading saved notification settings...',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Remind me before expiry',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [7, 5, 3].map((days) {
                          final selected =
                              _notificationSettings.reminderDays.contains(days);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _ChoicePill(
                                label: '$days days',
                                selected: selected,
                                enabled: _notificationSettings.enabled,
                                onTap: _isNotificationSettingsLoaded
                                    ? () => _toggleReminderDay(
                                          days,
                                          provider,
                                        )
                                    : () {},
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Inventory insights',
                  child: Column(
                    children: [
                      _InsightRow(
                        icon: Icons.inventory_2_rounded,
                        label: 'Active items',
                        value: provider.activeInventoryCount.toString(),
                      ),
                      const SizedBox(height: 12),
                      _InsightRow(
                        icon: Icons.history_rounded,
                        label: 'Used items',
                        value: provider.outOfStockCount.toString(),
                      ),
                      const SizedBox(height: 12),
                      _InsightRow(
                        icon: Icons.star_rounded,
                        label: 'Most added',
                        value: mostAdded ?? 'No data yet',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Experience',
                  child: Column(
                    children: [
                      _SwitchRow(
                        icon: Icons.view_agenda_rounded,
                        title: 'Compact inventory',
                        subtitle: 'Show tighter rows when available',
                        value: _compactInventory,
                        onChanged: (value) {
                          setState(() {
                            _compactInventory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _SwitchRow(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Smooth motion',
                        subtitle: 'Use polished page and control animations',
                        value: _softMotion,
                        onChanged: (value) {
                          setState(() {
                            _softMotion = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _mostAddedItem(List<FoodItem> items) {
    if (items.isEmpty) {
      return null;
    }

    final counts = <String, int>{};
    for (final item in items) {
      counts[item.name] = (counts[item.name] ?? 0) + item.stockCount;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return '${sorted.first.key} (${sorted.first.value})';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x12FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingIcon(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppTheme.surface,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected && enabled ? AppTheme.surface : AppTheme.panelSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected && enabled
                ? Colors.transparent
                : const Color(0x14FFFFFF),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected && enabled ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingIcon(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.black, size: 22),
    );
  }
}
