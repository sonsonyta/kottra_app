import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/early_leave_request.dart';

class EarlyLeaveService {
  EarlyLeaveService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_early_leave_requests');

  Future<void> submitRequest(EarlyLeaveRequest request) async {
    await _col(request.storeId).doc().set(request.toMap());
  }

  Stream<List<EarlyLeaveRequest>> streamEmployeeRequests(
    String storeId,
    String employeeId,
  ) {
    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EarlyLeaveRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Every early-leave request for the store, newest first (manager review).
  Stream<List<EarlyLeaveRequest>> streamStoreRequests(String storeId) {
    return _col(storeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EarlyLeaveRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Approves or rejects a request. Nothing else to write: payroll looks up
  /// approved requests itself when it skips early check-out minutes.
  Future<void> setStatus({
    required EarlyLeaveRequest request,
    required EarlyLeaveStatus status,
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
  }
}
