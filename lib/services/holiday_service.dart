import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/holiday.dart';

/// Reads store-wide public holidays. Read-only: holidays are managed in the POS.
class HolidayService {
  HolidayService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_holidays');

  /// Fetches every holiday falling within [month], ordered by date. Mirrors the
  /// POS `getHolidaysByMonth` date-range query.
  Future<List<Holiday>> fetchMonth(String storeId, DateTime month) async {
    if (storeId.isEmpty) return const [];

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

    final snap = await _col(storeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .get();

    return snap.docs
        .map((doc) => Holiday.fromMap(doc.id, doc.data()))
        .toList();
  }
}
