import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/leave_request.dart';

class LeaveService {
  LeaveService._();

  static final LeaveService instance = LeaveService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _db.collection('stores/$storeId/hr_leaves');

  Future<void> submitLeaveRequest(LeaveRequest request) async {
    final docRef = _col(request.storeId).doc();
    final map = request.toMap();
    await docRef.set(map);
  }

  Future<List<LeaveRequest>> fetchEmployeeLeaves(String storeId, String employeeId) async {
    final snapshot = await _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<LeaveRequest>> streamEmployeeLeaves(String storeId, String employeeId) {
    return _col(storeId)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequest.fromMap(doc.id, doc.data()))
            .toList());
  }
}
