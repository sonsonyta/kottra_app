import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kottra_app/models/attendance_record.dart';

class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.alreadyCheckedIn,
    required this.attendanceId,
    required this.status,
    this.queuedOffline = false,
  });

  final bool success;
  final bool alreadyCheckedIn;
  final String attendanceId;
  final AttendanceStatus status;

  /// True when the device was offline and the check-in was saved to the local
  /// queue for automatic sync rather than confirmed by the backend.
  final bool queuedOffline;

  factory CheckInResult.fromMap(Map<Object?, Object?> map) => CheckInResult(
    success: map['success'] as bool? ?? false,
    alreadyCheckedIn: map['alreadyCheckedIn'] as bool? ?? false,
    attendanceId: map['attendanceId'] as String? ?? '',
    status: AttendanceStatus.fromString(map['status'] as String? ?? ''),
  );

  /// A synthetic result standing in for a check-in that was queued offline.
  factory CheckInResult.queued() => const CheckInResult(
    success: true,
    alreadyCheckedIn: false,
    attendanceId: '',
    status: AttendanceStatus.present,
    queuedOffline: true,
  );
}

class CheckOutResult {
  const CheckOutResult({
    required this.success,
    required this.alreadyCheckedOut,
    required this.attendanceId,
    this.queuedOffline = false,
  });

  final bool success;
  final bool alreadyCheckedOut;
  final String attendanceId;

  /// True when the device was offline and the check-out was saved to the local
  /// queue for automatic sync rather than confirmed by the backend.
  final bool queuedOffline;

  factory CheckOutResult.fromMap(Map<Object?, Object?> map) => CheckOutResult(
    success: map['success'] as bool? ?? false,
    alreadyCheckedOut: map['alreadyCheckedOut'] as bool? ?? false,
    attendanceId: map['attendanceId'] as String? ?? '',
  );

  /// A synthetic result standing in for a check-out that was queued offline.
  factory CheckOutResult.queued() => const CheckOutResult(
    success: true,
    alreadyCheckedOut: false,
    attendanceId: '',
    queuedOffline: true,
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
             final fn = (functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1')).httpsCallable(
               name,
               options: HttpsCallableOptions(
                 limitedUseAppCheckToken: true,
                 // Fail fast when the network is unreachable so an offline
                 // check-in/out falls into the local queue promptly instead of
                 // blocking on the default ~70s callable timeout.
                 timeout: const Duration(seconds: 20),
               ),
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

  /// Streams every employee's attendance record for a single calendar [day]
  /// across the whole store, ordered by check-in time then name. Used by the
  /// manager/owner attendance view. Records are matched on the `date` field,
  /// which is stored at the start of the store's calendar day.
  Stream<List<AttendanceRecord>> streamStoreAttendanceByDate(
    String storeId,
    DateTime day,
  ) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _col(storeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final records = snap.docs
          .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => a.employeeName
            .toLowerCase()
            .compareTo(b.employeeName.toLowerCase()));
      return records;
    });
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Records a check-in via the `employeeCheckIn` Cloud Function.
  Future<CheckInResult> checkIn({
    required String storeId,
    required String employeeId,
    double? latitude,
    double? longitude,
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
    String? qrToken,
    String? checkInPhotoUrl,
    int? clientCheckInAt,
  }) async {
    final data = await _callable('employeeCheckInV1', <String, dynamic>{
      'storeId': storeId,
      'employeeId': employeeId,
      'latitude': ?latitude,
      'longitude': ?longitude,
      // Epoch ms of the actual tap; sent so a queued offline check-in records
      // when it happened, not when the queue drained. The backend clamps it.
      'clientCheckInAt': ?clientCheckInAt,
      if (lateCheckInNote != null && lateCheckInNote.isNotEmpty) 'lateCheckInNote': lateCheckInNote,
      if (earlyCheckOutNote != null && earlyCheckOutNote.isNotEmpty) 'earlyCheckOutNote': earlyCheckOutNote,
      if (leaveNote != null && leaveNote.isNotEmpty) 'leaveNote': leaveNote,
      if (absentNote != null && absentNote.isNotEmpty) 'absentNote': absentNote,
      // Raw scanned QR payload, sent when the store uses QR attendance. The
      // backend can verify it (e.g. once tokens are signed/rotating); unknown
      // to older functions, which safely ignore it.
      if (qrToken != null && qrToken.isNotEmpty) 'qrToken': qrToken,
      // Storage download URL of the check-in photo, sent when the store
      // requires a photo on attendance. Uploaded by the client before this call.
      if (checkInPhotoUrl != null && checkInPhotoUrl.isNotEmpty) 'checkInPhotoUrl': checkInPhotoUrl,
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
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
    String? qrToken,
    String? checkOutPhotoUrl,
    int? clientCheckOutAt,
  }) async {
    final data =  await _callable('employeeCheckOutV1', <String, dynamic>{
      'storeId': storeId,
      'attendanceId': attendanceId,
      'employeeId': employeeId,
      'latitude': ?latitude,
      'longitude': ?longitude,
      // Epoch ms of the actual tap; sent so a queued offline check-out records
      // when it happened, not when the queue drained. The backend clamps it.
      'clientCheckOutAt': ?clientCheckOutAt,
      if (lateCheckInNote != null && lateCheckInNote.isNotEmpty) 'lateCheckInNote': lateCheckInNote,
      if (earlyCheckOutNote != null && earlyCheckOutNote.isNotEmpty) 'earlyCheckOutNote': earlyCheckOutNote,
      if (leaveNote != null && leaveNote.isNotEmpty) 'leaveNote': leaveNote,
      if (absentNote != null && absentNote.isNotEmpty) 'absentNote': absentNote,
      if (qrToken != null && qrToken.isNotEmpty) 'qrToken': qrToken,
      // Storage download URL of the check-out photo, sent when the store
      // requires a photo on attendance. Uploaded by the client before this call.
      if (checkOutPhotoUrl != null && checkOutPhotoUrl.isNotEmpty) 'checkOutPhotoUrl': checkOutPhotoUrl,
    });

    if (data is! Map) {
      throw const FormatException(
        'employeeCheckIn returned an invalid payload.',
      );
    }

    return CheckOutResult.fromMap(data.cast<Object?, Object?>());
  }

}
