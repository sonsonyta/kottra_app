class Store {
  const Store({required this.id, this.name, this.timezone});

  final String id;

  /// Human-readable store name shown in the app. Null for stores whose
  /// document has no `storeName` field yet — callers should fall back gracefully.
  final String? name;

  /// IANA timezone name (e.g. `Asia/Phnom_Penh`) used to interpret this
  /// store's shift times and attendance dates. Null for stores that
  /// haven't been migrated yet — callers should fall back to device time.
  final String? timezone;

  factory Store.fromMap(String id, Map<String, dynamic> map) => Store(
        id: id,
        name: map['storeName'] as String?,
        timezone: map['timezone'] as String?,
      );
}
