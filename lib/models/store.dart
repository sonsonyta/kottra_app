class Store {
  const Store({
    required this.id,
    this.name,
    this.timezone,
    this.checkInWindowEnabled = false,
    this.checkInEarlyMinutes = 60,
  });

  final String id;

  /// Human-readable store name shown in the app. Null for stores whose
  /// document has no `storeName` field yet — callers should fall back gracefully.
  final String? name;

  /// IANA timezone name (e.g. `Asia/Phnom_Penh`) used to interpret this
  /// store's shift times and attendance dates. Null for stores that
  /// haven't been migrated yet — callers should fall back to device time.
  final String? timezone;

  /// When true, employees may only check in from [checkInEarlyMinutes]
  /// before their scheduled start until its end. Enforced by the
  /// `employeeCheckInV1` Cloud Function; the app mirrors it to explain why.
  final bool checkInWindowEnabled;
  final int checkInEarlyMinutes;

  factory Store.fromMap(String id, Map<String, dynamic> map) => Store(
        id: id,
        name: map['storeName'] as String?,
        timezone: map['timezone'] as String?,
        checkInWindowEnabled: map['checkInWindowEnabled'] == true,
        checkInEarlyMinutes: switch (map['checkInEarlyMinutes']) {
          final num n when n >= 0 => n.toInt(),
          _ => 60,
        },
      );
}
