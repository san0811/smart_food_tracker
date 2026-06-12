import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/expiry_notification_settings.dart';
import '../models/food_item.dart';

class ExpiryNotificationService {
  ExpiryNotificationService._();

  static final ExpiryNotificationService instance =
      ExpiryNotificationService._();

  static const MethodChannel _channel = MethodChannel(
    'com.fridgi.app/expiry_notifications',
  );

  Future<bool> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final granted = await _channel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final granted = await _channel.invokeMethod<bool>(
        'hasNotificationPermission',
      );
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> syncFromInventory(List<FoodItem> items) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final activeItems = items.where((item) => item.isInInventory).toList();
    final settings = await DatabaseHelper.instance
        .getExpiryNotificationSettings();
    if (!settings.enabled) {
      await clear();
      return;
    }

    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      return;
    }

    final requests = _buildRequests(activeItems, settings);
    if (requests.isEmpty) {
      await clear();
      return;
    }

    try {
      await _channel.invokeMethod<void>('syncExpiryNotifications', {
        'requests': requests,
      });
    } on PlatformException {
      // The app still works if notification scheduling fails, so keep this
      // failure silent and let the UI continue.
    }
  }

  Future<void> clear() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('clearExpiryNotifications');
    } on PlatformException {
      // Ignore platform failures when notifications are unavailable.
    }
  }

  Future<void> cancelForItem(int itemId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('clearExpiryNotificationsForItem', {
        'itemId': itemId,
      });
    } on PlatformException {
      // Ignore platform failures when notifications are unavailable.
    }
  }

  List<Map<String, Object?>> _buildRequests(
    List<FoodItem> items,
    ExpiryNotificationSettings settings,
  ) {
    final now = DateTime.now();
    final reminderWindow = _maxReminderWindow(settings.reminderDays);
    final today = DateTime(now.year, now.month, now.day);

    final requests = <Map<String, Object?>>[];

    for (final item in items) {
      final id = item.id;
      final expiryDate = item.expiryDate;
      if (id == null ||
          !item.isInInventory ||
          expiryDate == null ||
          expiryDate.trim().isEmpty) {
        continue;
      }

      final parsedExpiry = DateTime.tryParse(expiryDate.trim());
      if (parsedExpiry == null) {
        continue;
      }

      final expiryDateOnly = DateTime(
        parsedExpiry.year,
        parsedExpiry.month,
        parsedExpiry.day,
      );

      final daysRemaining = expiryDateOnly.difference(today).inDays;
      if (daysRemaining < 0) {
        continue;
      }

      final firstOffset = daysRemaining > reminderWindow
          ? daysRemaining - reminderWindow
          : 0;

      for (var offset = firstOffset; offset <= daysRemaining; offset++) {
        final daysLeft = daysRemaining - offset;
        final triggerAt = now.add(Duration(days: offset));

        requests.add({
          'notificationId': _notificationId(id, daysLeft),
          'workName': 'expiry_${id}_$daysLeft',
          'itemTag': 'item_$id',
          'scheduleAtMillis': triggerAt.millisecondsSinceEpoch,
          'title': _titleFor(item, daysLeft),
          'body': _bodyFor(item, daysLeft),
        });
      }
    }

    return requests;
  }

  int _maxReminderWindow(Set<int> reminderDays) {
    if (reminderDays.isEmpty) {
      return 7;
    }

    return reminderDays.reduce((a, b) => a > b ? a : b);
  }

  int _notificationId(int itemId, int daysLeft) {
    return itemId * 1000 + daysLeft;
  }

  String _titleFor(FoodItem item, int daysBefore) {
    if (daysBefore <= 0) {
      return '${item.name} expires today';
    }

    if (daysBefore == 1) {
      return '${item.name} expires tomorrow';
    }

    return '${item.name} expires in $daysBefore days';
  }

  String _bodyFor(FoodItem item, int daysBefore) {
    final detail = item.packageDetail;
    final brand = item.brand?.trim();
    final leading = brand == null || brand.isEmpty ? '' : '$brand - ';

    if (daysBefore <= 0) {
      return '$leading${item.category} item with $detail is due today.';
    }

    return '$leading${item.category} item with $detail needs attention soon.';
  }
}
