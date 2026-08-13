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
}
