import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/salary_advance.dart';

class SalaryAdvanceService {
  SalaryAdvanceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_salary_advances');

  Future<void> submitAdvanceRequest(SalaryAdvance advance) async {
    final docRef = _col(advance.storeId).doc();
    await docRef.set(advance.toMap());
  }

  Stream<List<SalaryAdvance>> streamEmployeeAdvances(
    String storeId,
    String employeeId,
  ) {
    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SalaryAdvance.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Streams every salary advance for the store, newest first. Used by the
  /// manager/owner to review and action requests across all employees.
  Stream<List<SalaryAdvance>> streamStoreAdvances(String storeId) {
    return _col(storeId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SalaryAdvance.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Approves or rejects a pending advance request — the same write the POS
  /// makes (`HrAdvanceService.updateAdvanceStatus`). Approved advances are
  /// then deducted in full by the next payroll run.
  Future<void> setAdvanceStatus({
    required String storeId,
    required String advanceId,
    required AdvanceStatus status,
    required String actionedBy,
    String? actionReason,
  }) async {
    await _col(storeId).doc(advanceId).update({
      'status': status.value,
      'actionedBy': actionedBy,
      'actionedAt': FieldValue.serverTimestamp(),
      if (actionReason != null && actionReason.isNotEmpty)
        'actionReason': actionReason,
    });
  }
}
