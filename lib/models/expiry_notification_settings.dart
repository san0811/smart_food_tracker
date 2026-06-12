class ExpiryNotificationSettings {
  ExpiryNotificationSettings({
    required this.enabled,
    required Set<int> reminderDays,
  }) : reminderDays = Set<int>.from(reminderDays);

  final bool enabled;
  final Set<int> reminderDays;

  factory ExpiryNotificationSettings.defaults() {
    return ExpiryNotificationSettings(
      enabled: true,
      reminderDays: {7},
    );
  }

  ExpiryNotificationSettings copyWith({
    bool? enabled,
    Set<int>? reminderDays,
  }) {
    return ExpiryNotificationSettings(
      enabled: enabled ?? this.enabled,
      reminderDays: reminderDays ?? this.reminderDays,
    );
  }

  Map<String, dynamic> toMap() {
    final days = reminderDays.toList()..sort();
    return {
      'enabled': enabled,
      'reminderDays': days,
    };
  }
}
