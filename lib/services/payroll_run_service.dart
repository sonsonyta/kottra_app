import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/hr_payroll_run.dart';

class PayrollRunService {
  PayrollRunService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'hr_payroll_runs';

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _firestore.collection('stores/$storeId/$_collectionName');

  /// Streams the payroll runs for a store (used to resolve a payslip's month).
  Stream<List<HRPayrollRun>> streamStoreRuns(String storeId) {
    return _col(storeId).snapshots().map((snap) => snap.docs
        .map((doc) => HRPayrollRun.fromMap(doc.id, doc.data()))
        .toList());
  }
}
