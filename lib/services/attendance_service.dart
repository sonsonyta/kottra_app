import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/attendance_record.dart';

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _firestore.collection('stores/$storeId/hr_attendance');

  // ── Streams ──────────────────────────────────────────────────────────────────

  /// Streams the current employee's attendance record for today.
  Stream<AttendanceRecord?> streamTodayRecord(
    String storeId,
    String employeeId,
  ) {
    final midnight = _midnight(DateTime.now());

    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: Timestamp.fromDate(midnight))
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final doc = snap.docs.first;
          return AttendanceRecord.fromMap(doc.id, doc.data());
        });
  }

  /// Streams the employee's full attendance history, newest first.
  Stream<List<AttendanceRecord>> streamHistory(
    String storeId,
    String employeeId, {
    int limit = 30,
  }) {
    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates or updates today's record with the check-in timestamp.
  Future<void> checkIn({
    required String storeId,
    required String employeeId,
    required String employeeName,
  }) async {
    final now = DateTime.now();
    final midnight = _midnight(now);

    final status = now.hour * 60 + now.minute > 9 * 60
        ? AttendanceStatus.late
        : AttendanceStatus.present;

    final existing = await _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: Timestamp.fromDate(midnight))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'checkIn': Timestamp.fromDate(now),
        'checkOut': FieldValue.delete(),
        'workingHours': FieldValue.delete(),
        'status': status.value,
      });
    } else {
      await _col(storeId).add({
        'storeId': storeId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'date': Timestamp.fromDate(midnight),
        'checkIn': Timestamp.fromDate(now),
        'checkOut': null,
        'status': status.value,
      });
    }
  }

  /// Updates today's record with the check-out timestamp and calculated hours.
  Future<void> checkOut({
    required String storeId,
    required String recordId,
    required DateTime checkInTime,
  }) async {
    final now = DateTime.now();
    final workingHours = double.parse(
      (now.difference(checkInTime).inMinutes / 60).toStringAsFixed(2),
    );

    await _col(storeId).doc(recordId).update({
      'checkOut': Timestamp.fromDate(now),
      'workingHours': workingHours,
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static DateTime _midnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}