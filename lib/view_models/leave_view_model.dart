import 'dart:async';
import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/attendance_record.dart' as att;
import 'package:kottra_app/models/leave_limits.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/models/payroll_deductions.dart'
    show dropDuplicatePlaceholders;
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/settings_service.dart';
import 'package:kottra_app/services/leave_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:timezone/timezone.dart' as tz;

class LeaveViewModel extends ChangeNotifier {
  LeaveViewModel({
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    LeaveService? leaveService,
    StoreService? storeService,
  })  : _leaveService = leaveService ?? LeaveService(),
        _storeService = storeService ?? StoreService() {
    _subscribeToLeaves();
    _loadStoreTimezone();
  }

  final String storeId;
  final String employeeId;
  final String employeeName;
  final LeaveService _leaveService;
  final StoreService _storeService;

  /// The store's configured IANA timezone, used so leave dates are recorded
  /// as calendar days in the store's timezone rather than the employee
  /// device's local timezone. Falls back to the device timezone until
  /// loaded or if the store hasn't been migrated to set it.
  String? _storeTimezone;

  StreamSubscription<List<LeaveRequest>>? _leaveSub;
  List<LeaveRequest> _leaves = [];
  bool _isLoading = false;
  bool _disposed = false;

  // Yearly leave-limit inputs; see [watchLeaveLimits].
  final List<StreamSubscription<Object?>> _limitSubs = [];
  LeaveLimits _storeLimits = const {};
  LeaveLimits _employeeLimits = const {};
  List<att.AttendanceRecord> _leaveRecords = const [];

  List<LeaveRequest> get leaves => _leaves;

  /// Starts streaming what [balanceFor] needs: the store's and the employee's
  /// leave limits and the employee's Leave attendance. Called by the screen
  /// (not the constructor) so tests can build the view model without Firebase.
  void watchLeaveLimits({
    SettingsService? settingsService,
    EmployeeService? employeeService,
    AttendanceService? attendanceService,
  }) {
    if (employeeId.isEmpty || _limitSubs.isNotEmpty) return;
    void onError(Object e) => debugPrint('Leave limit load error: $e');
    _limitSubs.addAll([
      (settingsService ?? SettingsService())
          .streamHrSettings(storeId)
          .listen((s) {
        _storeLimits = s.leaveLimits;
        if (!_disposed) notifyListeners();
      }, onError: onError),
      (employeeService ?? EmployeeService())
          .streamEmployee(storeId, employeeId)
          .listen((e) {
        _employeeLimits = e?.leaveLimits ?? const {};
        if (!_disposed) notifyListeners();
      }, onError: onError),
      (attendanceService ?? AttendanceService())
          .streamLeaveRecords(storeId, employeeId)
          .listen((records) {
        _leaveRecords = records;
        if (!_disposed) notifyListeners();
      }, onError: onError),
    ]);
  }

  /// The employee's yearly allowance for [type] against a request for
  /// [start]..[end], or null when that type has no limit. Days already taken
  /// come from Leave attendance in the year of [start] (what payroll counts).
  LeaveBalance? balanceFor(LeaveType type, DateTime start, DateTime end) {
    final limit =
        effectiveLeaveLimits(_storeLimits, _employeeLimits)[type.value];
    if (limit == null) return null;
    final year = start.year;
    DateTime local(DateTime d) => tz.TZDateTime.from(d, _storeLocation);
    final used = dropDuplicatePlaceholders(_leaveRecords, local)
        .where((r) =>
            local(r.date.toDate()).year == year &&
            (r.leaveType?.value ?? att.LeaveType.other.value) == type.value)
        .length;
    final lastDay = end.year == year ? end : DateTime(year, 12, 31);
    final requested = DateTime(lastDay.year, lastDay.month, lastDay.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays +
        1;
    return LeaveBalance(limit: limit, used: used, requested: requested);
  }
  bool get isLoading => _isLoading;

  void _subscribeToLeaves() {
    if (employeeId.isEmpty) return;
    _leaveSub?.cancel();
    _leaveSub = _leaveService.streamEmployeeLeaves(storeId, employeeId).listen(
      (data) {
        _leaves = data;
        if (!_disposed) notifyListeners();
      },
      // The listener stops for good after an error (e.g. a missing index),
      // leaving the list frozen — log it so the cause is visible.
      onError: (Object e) => debugPrint('Leave stream error: $e'),
    );
  }

  Future<void> _loadStoreTimezone() async {
    try {
      final store = await _storeService.getStore(storeId);
      _storeTimezone = store?.timezone;
    } catch (e) {
      debugPrint('Error loading store timezone: $e');
    }
  }

  tz.Location get _storeLocation {
    final name = _storeTimezone;
    if (name != null && name.isNotEmpty) {
      try {
        return tz.getLocation(name);
      } catch (_) {
        // Unknown timezone name — fall through to the device timezone.
      }
    }
    try {
      return tz.local;
    } catch (_) {
      // Timezone database not initialized (e.g. in tests) — last resort.
      return tz.UTC;
    }
  }

  /// Reinterprets the calendar day the employee picked (year/month/day) as
  /// midnight in the store's timezone, so the leave date lines up with the
  /// store's calendar regardless of the device's local timezone.
  tz.TZDateTime _asStoreDate(DateTime date) =>
      tz.TZDateTime(_storeLocation, date.year, date.month, date.day);

  Future<void> submitRequest({
    required DateTime startDate,
    required DateTime endDate,
    required LeaveType type,
    required String reason,
    String? actionedBy,
    PlatformFile? attachment,
  }) async {
    if (employeeId.isEmpty) {
      throw Exception('Employee ID is missing');
    }
    
    if (startDate.isAfter(endDate)) {
      throw Exception('Start date must be before or equal to end date.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Please provide a reason.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      String? attachmentUrl;
      if (attachment != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('stores/$storeId/hr_leave_requests/$employeeId/${DateTime.now().millisecondsSinceEpoch}_${attachment.name}');
            
        if (kIsWeb && attachment.bytes != null) {
          final uploadTask = await storageRef.putData(attachment.bytes!);
          attachmentUrl = await uploadTask.ref.getDownloadURL();
        } else if (attachment.path != null) {
          final file = File(attachment.path!);
          final uploadTask = await storageRef.putFile(file);
          attachmentUrl = await uploadTask.ref.getDownloadURL();
        }
      }

      final request = LeaveRequest(
        id: '', // Will be generated by Firestore
        storeId: storeId,
        employeeId: employeeId,
        employeeName: employeeName,
        startDate: _asStoreDate(startDate),
        endDate: _asStoreDate(endDate),
        type: type,
        status: LeaveStatus.pending,
        reason: reason,
        actionedBy: actionedBy,
        attachmentUrl: attachmentUrl,
      );

      await _leaveService.submitLeaveRequest(request);
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _leaveSub?.cancel();
    for (final sub in _limitSubs) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// A leave type's yearly allowance against one request.
class LeaveBalance {
  const LeaveBalance({
    required this.limit,
    required this.used,
    required this.requested,
  });

  final int limit;
  final int used;
  final int requested;

  int get remaining => (limit - used).clamp(0, limit);

  /// Requested days past the allowance — payroll docks them as unpaid.
  int get over => (used + requested - limit).clamp(0, requested);
}
