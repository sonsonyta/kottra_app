import 'dart:async';
import 'package:kottra_app/services/notification_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_payroll_run.dart';
import 'package:kottra_app/models/hr_payslip.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/payroll_run_service.dart';
import 'package:kottra_app/services/payslip_service.dart';
import 'package:kottra_app/view_models/employee_identity.dart';

export 'package:kottra_app/models/hr_employee.dart';
export 'package:kottra_app/models/hr_payslip.dart';

class MainViewModel extends ChangeNotifier {
  MainViewModel({
    AuthServiceBase? authService,
    FirebaseAuth? firebaseAuth,
    EmployeeService? employeeService,
    PayslipService? payslipService,
    PayrollRunService? payrollRunService,
  })  : _authService = authService ?? AuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _employeeService = employeeService ?? EmployeeService(),
        _payslipService = payslipService ?? PayslipService(),
        _payrollRunService = payrollRunService ?? PayrollRunService() {
    _subscribeToEmployee();
    _subscribeToPayslips();
    _subscribeToRuns();
  }

  final AuthServiceBase _authService;
  final FirebaseAuth _firebaseAuth;
  final EmployeeService _employeeService;
  final PayslipService _payslipService;
  final PayrollRunService _payrollRunService;

  StreamSubscription<HREmployee?>? _employeeSub;
  StreamSubscription<List<HRPayslip>>? _payslipSub;
  StreamSubscription<List<HRPayrollRun>>? _runsSub;

  HREmployee? _employee;
  List<HRPayslip> _payslips = [];
  List<HRPayrollRun> _runs = [];

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

  bool _fcmTokenSynced = false;

  void _subscribeToEmployee() {
    final identity = _identity;
    if (identity == null) return;

    _employeeSub?.cancel();
    _employeeSub = _employeeService
        .streamEmployee(identity.storeId, identity.employeeId)
        .listen((emp) async {
          _employee = emp;
          notifyListeners();

          if (emp != null && !_fcmTokenSynced) {
            _fcmTokenSynced = true;
            try {
              final token = await NotificationService.instance.getFcmToken();
              if (token != null && emp.fcmToken != token) {
                await _employeeService.updateEmployee(
                  identity.storeId,
                  identity.employeeId,
                  {'fcmToken': token},
                );
              }
            } catch (e) {
              debugPrint('Error updating FCM token: $e');
            }
          }
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

  void _subscribeToRuns() {
    final identity = _identity;
    if (identity == null) return;

    _runsSub?.cancel();
    _runsSub = _payrollRunService
        .streamStoreRuns(identity.storeId)
        .listen((runs) {
          _runs = runs;
          notifyListeners();
        });
  }

  // ── User info ────────────────────────────────────────────────────────────────

  User? get _currentUser => _firebaseAuth.currentUser;

  String get userName {
    if (_employee != null && _employee!.fullName.trim().isNotEmpty) {
      return _employee!.fullName;
    }
    final user = _currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Employee';
  }

  String get userInitials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : 'E';
  }

  // ── Employee info shared across tabs ───────────────────────────────────────────

  String get storeId => _identity?.storeId ?? '';
  String get employeeId => _identity?.employeeId ?? '';
  String? get startWorkingTime => _employee?.startWorkingTime;
  String? get endWorkingTime => _employee?.endWorkingTime;
  int? get lateTime => _employee?.lateTime;
  String? get profileImageUrl {
    final url = _employee?.profileImageThumbnail ?? _employee?.profileImage;
    return _resolveEmulatorUrl(url);
  }

  /// In debug mode the Storage emulator returns download URLs pointing at
  /// `localhost`/`127.0.0.1`, which the Android emulator cannot reach — it must
  /// use `10.0.2.2` (matching the emulator host wired up in `main.dart`).
  String? _resolveEmulatorUrl(String? url) {
    if (url == null) return null;
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  // ── Payroll ──────────────────────────────────────────────────────────────────

  List<HRPayslip> get payslips => _payslips;

  /// The employee's payslip for the current calendar month, resolved by
  /// matching the payslip's run id to a payroll run whose month is this month.
  /// Null when no payroll run exists for the current month yet.
  HRPayslip? get currentMonthPayslip {
    final now = DateTime.now();
    final currentRunIds = _runs
        .where((r) => r.month.year == now.year && r.month.month == now.month)
        .map((r) => r.id)
        .toSet();
    if (currentRunIds.isEmpty) return null;
    for (final p in _payslips) {
      if (currentRunIds.contains(p.payrollRunId)) return p;
    }
    return null;
  }

  /// Total deduction for the current month (0 when there is no payslip yet).
  double get currentMonthDeduction =>
      currentMonthPayslip?.totalDeductions ?? 0;

  /// Whether the current-month deductions are a provisional preview: the
  /// payroll run exists (so the backend has computed a draft payslip per its
  /// deduction policy) but has not been finalized/paid yet. Employees can view
  /// these figures before payroll is run, but they may still change.
  bool get isCurrentMonthDeductionPreview =>
      currentMonthPayslip?.status == PayslipStatus.pending;

  // ── Auth ─────────────────────────────────────────────────────────────────────

  Future<void> logout() => _authService.signOut();

  @override
  void dispose() {
    _employeeSub?.cancel();
    _payslipSub?.cancel();
    _runsSub?.cancel();
    super.dispose();
  }
}
