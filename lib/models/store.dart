class Store {
  const Store({required this.id, this.timezone});

  final String id;

  /// IANA timezone name (e.g. `Asia/Phnom_Penh`) used to interpret this
  /// store's shift times and attendance dates. Null for stores that
  /// haven't been migrated yet — callers should fall back to device time.
  final String? timezone;

  factory Store.fromMap(String id, Map<String, dynamic> map) => Store(
        id: id,
        timezone: map['timezone'] as String?,
      );
}
