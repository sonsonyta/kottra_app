import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/day_off_schedule.dart';

/// Reads an employee's scheduled days off. Read-only: the schedule is written
/// by the POS. The document id encodes employee + month, so a single month is
/// a direct document lookup rather than a query.
class DayOffService {
  DayOffService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_day_off_schedules');

  /// `yyyy-MM` key used in the day-off document id, matching the POS.
  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  static String docId(String employeeId, DateTime month) =>
      '${employeeId}_${_monthKey(month)}';

  /// Fetches the employee's day-off schedule for [month]. Returns null when no
  /// days off have been scheduled for that month.
  Future<DayOffSchedule?> fetchMonth(
    String storeId,
    String employeeId,
    DateTime month,
  ) async {
    if (storeId.isEmpty || employeeId.isEmpty) return null;
    final snap = await _col(storeId).doc(docId(employeeId, month)).get();
    if (!snap.exists) return null;
    return DayOffSchedule.fromMap(snap.id, snap.data()!);
  }

  /// Streams the employee's day-off schedule for [month], emitting null while
  /// none is scheduled.
  Stream<DayOffSchedule?> streamMonth(
    String storeId,
    String employeeId,
    DateTime month,
  ) {
    if (storeId.isEmpty || employeeId.isEmpty) {
      return Stream.value(null);
    }
    return _col(storeId).doc(docId(employeeId, month)).snapshots().map(
          (snap) => snap.exists
              ? DayOffSchedule.fromMap(snap.id, snap.data()!)
              : null,
        );
  }
}
