import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/payroll_record.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/services/employee_service.dart';

export 'package:kottra_app/models/attendance_record.dart';
export 'package:kottra_app/models/hr_employee.dart';
export 'package:kottra_app/models/payroll_record.dart';

/// Parses a UID of the form `hr_employee:<storeId>:<employeeId>` into its parts.
/// Returns null if the format doesn't match.
({String storeId, String employeeId})? parseEmployeeUid(String uid) {
  final parts = uid.split(':');
  if (parts.length != 3 || parts[0] != 'hr_employee') return null;
  return (storeId: parts[1], employeeId: parts[2]);
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    AuthServiceBase? authService,
    FirebaseAuth? firebaseAuth,
    AttendanceService? attendanceService,
    EmployeeService? employeeService,
  })  : _authService = authService ?? AuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _attendanceService = attendanceService ?? AttendanceService(),
        _employeeService = employeeService ?? EmployeeService() {
    _subscribeToAttendance();
    _subscribeToEmployee();
  }

  final AuthServiceBase _authService;
  final FirebaseAuth _firebaseAuth;
  final AttendanceService _attendanceService;
  final EmployeeService _employeeService;

  StreamSubscription<AttendanceRecord?>? _todaySub;
  StreamSubscription<List<AttendanceRecord>>? _historySub;
  StreamSubscription<HREmployee?>? _employeeSub;

  AttendanceRecord? _todayRecord;
  List<AttendanceRecord> _history = [];
  HREmployee? _employee;

  bool _isActionLoading = false;

  /// True while a check-in or check-out write is in progress.
  bool get isActionLoading => _isActionLoading;

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

  void _subscribeToAttendance() {
    final identity = _identity;
    if (identity == null) return;

    _todaySub?.cancel();
    _todaySub = _attendanceService
        .streamTodayRecord(identity.storeId, identity.employeeId)
        .listen((record) {
          _todayRecord = record;
          notifyListeners();
        });

    _historySub?.cancel();
    _historySub = _attendanceService
        .streamHistory(identity.storeId, identity.employeeId)
        .listen((records) {
          _history = records;
          notifyListeners();
        });
  }

  // ── Attendance state ─────────────────────────────────────────────────────────

  bool get isCheckedIn =>
      _todayRecord?.checkIn != null && _todayRecord?.checkOut == null;

  DateTime? get checkInTime => _todayRecord?.checkIn;
  DateTime? get checkOutTime => _todayRecord?.checkOut;

  Future<void> checkIn() async {
    final identity = _identity;
    if (identity == null) return;
    _isActionLoading = true;
    notifyListeners();
    try {
      await _attendanceService.checkIn(
        storeId: identity.storeId,
        employeeId: identity.employeeId,
        employeeName: userName,
      );
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkOut() async {
    final record = _todayRecord;
    final identity = _identity;
    if (identity == null || record == null || record.checkIn == null) return;
    _isActionLoading = true;
    notifyListeners();
    try {
      await _attendanceService.checkOut(
        storeId: identity.storeId,
        recordId: record.id,
        checkInTime: record.checkIn!,
      );
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  List<AttendanceRecord> get attendanceRecords => _history;

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

  String get employeeCode => _employee?.employeeCode ?? _identity?.employeeId ?? '—';
  String get position => _employee?.position ?? '—';
  String? get department => _employee?.department;
  String? get workLocation => _employee?.workLocation;
  EmployeeStatus get employeeStatus => _employee?.status ?? EmployeeStatus.active;
  String? get profileImageUrl => _employee?.profileImageThumbnail ?? _employee?.profileImage;

  // ── Payroll (mock) ────────────────────────────────────────────────────────────

  List<PayrollRecord> get payrollRecords => const [
        PayrollRecord(
          month: 'March 2026',
          baseSalary: 5000,
          deductions: 450,
          netPay: 4550,
          status: 'paid',
        ),
        PayrollRecord(
          month: 'February 2026',
          baseSalary: 5000,
          deductions: 420,
          netPay: 4580,
          status: 'paid',
        ),
        PayrollRecord(
          month: 'January 2026',
          baseSalary: 5000,
          deductions: 480,
          netPay: 4520,
          status: 'paid',
        ),
        PayrollRecord(
          month: 'December 2025',
          baseSalary: 5000,
          deductions: 400,
          netPay: 4600,
          status: 'paid',
        ),
      ];

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<void> logout() => _authService.signOut();

  @override
  void dispose() {
    _todaySub?.cancel();
    _historySub?.cancel();
    _employeeSub?.cancel();
    super.dispose();
  }
}
