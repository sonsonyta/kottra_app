import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/late_excuse_request.dart';

class LateExcuseService {
  LateExcuseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_late_excuse_requests');

  Future<void> submitRequest(LateExcuseRequest request) async {
    final docRef = _col(request.storeId).doc();
    await docRef.set(request.toMap());
  }

  Stream<List<LateExcuseRequest>> streamEmployeeRequests(
    String storeId,
    String employeeId,
  ) {
    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LateExcuseRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Streams every late-excuse request for the store, newest first. Used by the
  /// manager/owner to review and action requests across all employees.
  Stream<List<LateExcuseRequest>> streamStoreRequests(String storeId) {
    return _col(storeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LateExcuseRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Approves or rejects a late-excuse request. On approval the referenced
  /// attendance record (when known) is flagged `lateExcused` so that day's
  /// lateness is excluded from the late-arrival deduction — the same effect the
  /// POS produces when HR approves.
  Future<void> setStatus({
    required LateExcuseRequest request,
    required LateExcuseStatus status,
    required String actionedBy,
    String? actionReason,
  }) async {
    await _col(request.storeId).doc(request.id).update({
      'status': status.value,
      'actionedBy': actionedBy,
      'actionedAt': FieldValue.serverTimestamp(),
      if (actionReason != null && actionReason.isNotEmpty)
        'actionReason': actionReason,
    });

    final attendanceId = request.attendanceId;
    if (status == LateExcuseStatus.approved &&
        attendanceId != null &&
        attendanceId.isNotEmpty) {
      await _db
          .collection('stores/${request.storeId}/hr_attendance')
          .doc(attendanceId)
          .update({'lateExcused': true});
    }
  }
}
