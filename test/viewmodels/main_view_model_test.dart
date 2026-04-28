import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/payslip_service.dart';
import 'package:kottra_app/viewmodels/employee_identity.dart';
import 'package:kottra_app/viewmodels/main_view_model.dart';

class FakeUser implements User {
  FakeUser({required this.uid, this.email, this.displayName});

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.user});

  final User? user;

  @override
  User? get currentUser => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeAuthService implements AuthServiceBase {
  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEmployeeToken(String loginToken) async {}

  @override
  Future<void> signOut() async {}
}

class FakeEmployeeService implements EmployeeService {
  @override
  Stream<List<HREmployee>> streamActiveEmployees(String storeId) =>
      Stream.value(const []);

  @override
  Stream<List<HREmployee>> streamAllEmployees(String storeId) =>
      Stream.value(const []);

  @override
  Stream<HREmployee?> streamEmployee(String storeId, String employeeId) =>
      Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakePayslipService implements PayslipService {
  @override
  Stream<List<HRPayslip>> streamEmployeePayslips(String employeeId) =>
      Stream.value(const []);

  @override
  Stream<List<HRPayslip>> streamRunPayslips(String payrollRunId) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('parseEmployeeUid', () {
    test('parses a valid hr_employee uid', () {
      expect(
        parseEmployeeUid('hr_employee:store-1:emp-1'),
        (storeId: 'store-1', employeeId: 'emp-1'),
      );
    });

    test('returns null for invalid uid formats', () {
      expect(parseEmployeeUid('hr_employee:store-1'), isNull);
      expect(parseEmployeeUid('user:store-1:emp-1'), isNull);
    });
  });

  group('MainViewModel', () {
    test('updates tab index and notifies listeners', () {
      final viewModel = MainViewModel(
        authService: FakeAuthService(),
        firebaseAuth: FakeFirebaseAuth(user: FakeUser(uid: 'hr_employee:s:e')),
        employeeService: FakeEmployeeService(),
        payslipService: FakePayslipService(),
      );
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setTabIndex(1);

      expect(viewModel.currentTabIndex, 1);
      expect(notifications, 1);

      viewModel.setTabIndex(1); // no-op
      expect(notifications, 1);

      viewModel.dispose();
    });

    test('userName falls back to email prefix', () {
      final viewModel = MainViewModel(
        authService: FakeAuthService(),
        firebaseAuth: FakeFirebaseAuth(
          user: FakeUser(uid: 'hr_employee:s:e', email: 'alex@example.com'),
        ),
        employeeService: FakeEmployeeService(),
        payslipService: FakePayslipService(),
      );

      expect(viewModel.userName, 'alex');

      viewModel.dispose();
    });
  });
}
