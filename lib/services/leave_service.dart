import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/leave_request.dart';

class LeaveService {
  LeaveService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_leave_requests');

  Future<void> submitLeaveRequest(LeaveRequest request) async {
    final docRef = _col(request.storeId).doc();
    final map = request.toMap();
    await docRef.set(map);
  }

  Future<List<LeaveRequest>> fetchEmployeeLeaves(
    String storeId,
    String employeeId,
  ) async {
    final snapshot = await _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('requestedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<LeaveRequest>> streamEmployeeLeaves(
    String storeId,
    String employeeId,
  ) {
    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Streams every leave request for the store, newest first. Used by the
  /// manager/owner to review and action requests across all employees.
  Stream<List<LeaveRequest>> streamStoreLeaves(String storeId) {
    return _col(storeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Approves or rejects a leave request, recording who actioned it and why.
  Future<void> setLeaveStatus({
    required String storeId,
    required String requestId,
    required LeaveStatus status,
    required String actionedBy,
    String? actionReason,
    LeaveType? leaveType,
    LeaveType? requestedLeaveType,
  }) async {
    await _col(storeId).doc(requestId).update({
      'status': status.value,
      // Approver override of the type, written in the same update as the
      // approval so the leave trigger sees the final type. Mirrors the POS:
      // `leaveType` + `type`, keeping the employee's choice in
      // `requestedLeaveType`.
      if (leaveType != null) ...{
        'leaveType': leaveType.value,
        'type': leaveType.value,
        if (requestedLeaveType != null)
          'requestedLeaveType': requestedLeaveType.value,
      },
      'actionedBy': actionedBy,
      'actionedAt': FieldValue.serverTimestamp(),
      if (actionReason != null && actionReason.isNotEmpty)
        'actionReason': actionReason,
    });
  }
}
