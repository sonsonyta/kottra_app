import 'package:cloud_firestore/cloud_firestore.dart';

/// A store-wide public holiday.
///
/// Mirrors the POS `HRHoliday` model, stored at `stores/{storeId}/hr_holidays`.
/// Carries both an English (`name`) and optional Khmer (`nameKH`) label so the
/// app can show the holiday in the user's language.
class Holiday {
  const Holiday({
    required this.id,
    required this.storeId,
    required this.name,
    this.nameKH,
    required this.date,
  });

  final String id;
  final String storeId;
  final String name;
  final String? nameKH;
  final DateTime date;

  /// The holiday name for the given locale language code, falling back to the
  /// English name when a Khmer label is absent.
  String localizedName(String languageCode) {
    if (languageCode == 'km' && (nameKH?.trim().isNotEmpty ?? false)) {
      return nameKH!;
    }
    return name;
  }

  factory Holiday.fromMap(String id, Map<String, dynamic> map) {
    return Holiday(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameKH: map['nameKH'] as String?,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
