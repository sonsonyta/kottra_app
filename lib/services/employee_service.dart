import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/hr_employee.dart';

class EmployeeService {
  EmployeeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String storeId) =>
      _firestore.collection('stores/$storeId/hr_employees');

  // ── Streams ──────────────────────────────────────────────────────────────────

  /// Streams all active employees for a store.
  Stream<List<HREmployee>> streamActiveEmployees(String storeId) {
    return _col(storeId)
        .where('status', isEqualTo: EmployeeStatus.active.value)
        .orderBy('firstName')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => HREmployee.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Streams all employees for a store regardless of status.
  Stream<List<HREmployee>> streamAllEmployees(String storeId) {
    return _col(storeId)
        .orderBy('firstName')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => HREmployee.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Streams a single employee by ID.
  Stream<HREmployee?> streamEmployee(String storeId, String employeeId) {
    return _col(storeId).doc(employeeId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return HREmployee.fromMap(doc.id, doc.data()!);
    });
  }

  // ── Queries ──────────────────────────────────────────────────────────────────

  /// Fetches a single employee by ID.
  Future<HREmployee?> getEmployee(String storeId, String employeeId) async {
    final doc = await _col(storeId).doc(employeeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return HREmployee.fromMap(doc.id, doc.data()!);
  }

  /// Fetches an employee by employee code.
  Future<HREmployee?> getEmployeeByCode(
      String storeId, String employeeCode) async {
    final snap = await _col(storeId)
        .where('employeeCode', isEqualTo: employeeCode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return HREmployee.fromMap(doc.id, doc.data());
  }

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Creates a new employee and returns the generated document ID.
  Future<String> createEmployee(String storeId, HREmployee employee) async {
    final now = Timestamp.now();
    final data = employee.toMap()
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    final ref = await _col(storeId).add(data);
    return ref.id;
  }

  /// Updates an existing employee. Only the provided fields are overwritten.
  Future<void> updateEmployee(
    String storeId,
    String employeeId,
    Map<String, dynamic> fields,
  ) async {
    await _col(storeId).doc(employeeId).update({
      ...fields,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Replaces the full employee document.
  Future<void> setEmployee(String storeId, HREmployee employee) async {
    final data = employee.toMap()..['updatedAt'] = Timestamp.now();
    await _col(storeId).doc(employee.id).set(data);
  }

  /// Soft-deletes by setting status to Terminated.
  Future<void> terminateEmployee(String storeId, String employeeId) async {
    await updateEmployee(storeId, employeeId, {
      'status': EmployeeStatus.terminated.value,
    });
  }

  /// Hard-deletes the employee document. Use with caution.
  Future<void> deleteEmployee(String storeId, String employeeId) async {
    await _col(storeId).doc(employeeId).delete();
  }
}