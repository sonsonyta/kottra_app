import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/hr_payslip.dart';

class PayslipService {
  PayslipService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'payslips';

  Query<Map<String, dynamic>> _group() =>
      _firestore.collectionGroup(_collectionName);

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _firestore.collection('stores/$storeId/$_collectionName');

  // ── Streams ──────────────────────────────────────────────────────────────────

  /// Streams an employee's payslips across all stores, pending first then
  /// paid by date desc.
  Stream<List<HRPayslip>> streamEmployeePayslips(String employeeId) {
    return _group()
        .where('employeeId', isEqualTo: employeeId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => HRPayslip.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) {
        if (a.status != b.status) {
          return a.status == PayslipStatus.pending ? -1 : 1;
        }
        final aDate = a.paidDate;
        final bDate = b.paidDate;
        if (aDate == null && bDate == null) {
          return b.payrollRunId.compareTo(a.payrollRunId);
        }
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Streams all payslips for a payroll run across all stores.
  Stream<List<HRPayslip>> streamRunPayslips(String payrollRunId) {
    return _group()
        .where('payrollRunId', isEqualTo: payrollRunId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => HRPayslip.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  Future<HRPayslip?> getPayslip(String storeId, String payslipId) async {
    final doc = await _col(storeId).doc(payslipId).get();
    if (!doc.exists || doc.data() == null) return null;
    return HRPayslip.fromMap(doc.id, doc.data()!);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new payslip and returns the generated document ID.
  Future<String> createPayslip(String storeId, HRPayslip payslip) async {
    final ref = await _col(storeId).add(payslip.toMap());
    return ref.id;
  }

  /// Marks a payslip as paid with the current timestamp.
  Future<void> markAsPaid(String storeId, String payslipId) async {
    await _col(storeId).doc(payslipId).update({
      'status': PayslipStatus.paid.value,
      'paidDate': Timestamp.now(),
    });
  }

  Future<void> updatePayslip(
    String storeId,
    String payslipId,
    Map<String, dynamic> fields,
  ) async {
    await _col(storeId).doc(payslipId).update(fields);
  }

  Future<void> deletePayslip(String storeId, String payslipId) async {
    await _col(storeId).doc(payslipId).delete();
  }
}
