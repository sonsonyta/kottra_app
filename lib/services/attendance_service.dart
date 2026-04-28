import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kottra_app/models/attendance_record.dart';

class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.alreadyCheckedIn,
    required this.attendanceId,
    required this.status,
  });

  final bool success;
  final bool alreadyCheckedIn;
  final String attendanceId;
  final AttendanceStatus status;

  factory CheckInResult.fromMap(Map<Object?, Object?> map) => CheckInResult(
    success: map['success'] as bool? ?? false,
    alreadyCheckedIn: map['alreadyCheckedIn'] as bool? ?? false,
    attendanceId: map['attendanceId'] as String? ?? '',
    status: AttendanceStatus.fromString(map['status'] as String? ?? ''),
  );
}

class CheckOutResult {
  const CheckOutResult({
    required this.success,
    required this.alreadyCheckedOut,
    required this.attendanceId,
  });

  final bool success;
  final bool alreadyCheckedOut;
  final String attendanceId;

  factory CheckOutResult.fromMap(Map<Object?, Object?> map) => CheckOutResult(
    success: map['success'] as bool? ?? false,
    alreadyCheckedOut: map['alreadyCheckedOut'] as bool? ?? false,
    attendanceId: map['attendanceId'] as String? ?? '',
  );
}

/// Invokes a Cloud Function and returns its raw `data` payload.
typedef HttpsCallableInvoker =
    Future<Object?> Function(String name, Map<String, dynamic> params);

class AttendanceService {
  AttendanceService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    HttpsCallableInvoker? callable,
  }) : _firestore = firestore,
       _callable =
           callable ??
           ((name, params) async {
             final fn = (functions ?? FirebaseFunctions.instance).httpsCallable(
               name,
             );
             final result = await fn.call(params);
             return result.data;
           });

  final FirebaseFirestore? _firestore;
  final HttpsCallableInvoker _callable;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      (_firestore ?? FirebaseFirestore.instance).collection(
        'stores/$storeId/hr_attendance',
      );

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

  /// Records a check-in via the `employeeCheckIn` Cloud Function.
  Future<CheckInResult> checkIn({
    required String storeId,
    required String employeeId,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _callable('employeeCheckIn', <String, dynamic>{
      'storeId': storeId,
      'employeeId': employeeId,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });

    if (data is! Map) {
      throw const FormatException(
        'employeeCheckIn returned an invalid payload.',
      );
    }
    return CheckInResult.fromMap(data.cast<Object?, Object?>());
  }

  /// Records a check-out via the `employeeCheckOut` Cloud Function.
  Future<CheckOutResult> checkOut({
    required String storeId,
    required String attendanceId,
    required String employeeId,
    double? latitude,
    double? longitude,
  }) async {
    final data =  await _callable('employeeCheckOut', <String, dynamic>{
      'storeId': storeId,
      'attendanceId': attendanceId,
      'employeeId': employeeId,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });

    if (data is! Map) {
      throw const FormatException(
        'employeeCheckIn returned an invalid payload.',
      );
    }

    return CheckOutResult.fromMap(data.cast<Object?, Object?>());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static DateTime _midnight(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
