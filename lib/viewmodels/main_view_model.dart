import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_payslip.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/payslip_service.dart';
import 'package:kottra_app/viewmodels/employee_identity.dart';

export 'package:kottra_app/models/hr_employee.dart';
export 'package:kottra_app/models/hr_payslip.dart';

class MainViewModel extends ChangeNotifier {
  MainViewModel({
    AuthServiceBase? authService,
    FirebaseAuth? firebaseAuth,
    EmployeeService? employeeService,
    PayslipService? payslipService,
  })  : _authService = authService ?? AuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _employeeService = employeeService ?? EmployeeService(),
        _payslipService = payslipService ?? PayslipService() {
    _subscribeToEmployee();
    _subscribeToPayslips();
  }

  final AuthServiceBase _authService;
  final FirebaseAuth _firebaseAuth;
  final EmployeeService _employeeService;
  final PayslipService _payslipService;

  StreamSubscription<HREmployee?>? _employeeSub;
  StreamSubscription<List<HRPayslip>>? _payslipSub;

  HREmployee? _employee;
  List<HRPayslip> _payslips = [];

  // ── Navigation ──────────────────────────────────────────────────────────────

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    if (_currentTabIndex == index) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  // ── Identity ─────────────────────────────────────────────────────────────────

  /// Parsed from the Firebase Auth UID (`hr_employee:<storeId>:<employeeId>`).
  ({String storeId, String employeeId})? get _identity {
    final uid = _currentUser?.uid;
    if (uid == null) return null;
    return parseEmployeeUid(uid);
  }

  void _subscribeToEmployee() {
    final identity = _identity;
    if (identity == null) return;

    _employeeSub?.cancel();
    _employeeSub = _employeeService
        .streamEmployee(identity.storeId, identity.employeeId)
        .listen((emp) {
          _employee = emp;
          notifyListeners();
        });
  }

  void _subscribeToPayslips() {
    final identity = _identity;
    if (identity == null) return;

    _payslipSub?.cancel();
    _payslipSub = _payslipService
        .streamEmployeePayslips(identity.employeeId)
        .listen((payslips) {
          _payslips = payslips;
          notifyListeners();
        });
  }

  // ── User info ────────────────────────────────────────────────────────────────

  User? get _currentUser => _firebaseAuth.currentUser;

  String get userName {
    final user = _currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Employee';
  }

  String get userEmail => _currentUser?.email ?? '';

  String get userInitials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : 'E';
  }

  /// Kept for backward-compatibility with existing usages.
  String get userLabel => userName;

  // ── Employee profile ─────────────────────────────────────────────────────────

  String get storeId => _identity?.storeId ?? '';
  String get employeeId => _identity?.employeeId ?? '';
  String get employeeCode => _employee?.employeeCode ?? _identity?.employeeId ?? '—';
  String get position => _employee?.position ?? '—';
  String? get department => _employee?.department;
  String? get workLocation => _employee?.workLocation;
  EmployeeStatus get employeeStatus => _employee?.status ?? EmployeeStatus.active;
  String? get profileImageUrl => _employee?.profileImageThumbnail ?? _employee?.profileImage;

  // ── Payroll ──────────────────────────────────────────────────────────────────

  List<HRPayslip> get payslips => _payslips;

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<void> logout() => _authService.signOut();

  @override
  void dispose() {
    _employeeSub?.cancel();
    _payslipSub?.cancel();
    super.dispose();
  }
}
