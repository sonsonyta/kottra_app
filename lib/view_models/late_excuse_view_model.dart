import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/late_excuse_request.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/late_excuse_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:timezone/timezone.dart' as tz;

class LateExcuseViewModel extends ChangeNotifier {
  LateExcuseViewModel({
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    LateExcuseService? lateExcuseService,
    AttendanceService? attendanceService,
    StoreService? storeService,
  })  : _lateExcuseService = lateExcuseService ?? LateExcuseService(),
        _attendanceService = attendanceService ?? AttendanceService(),
        _storeService = storeService ?? StoreService() {
    _subscribe();
    _loadStoreTimezone();
  }

  /// How far ahead an employee can request an excuse for an upcoming day.
  static const upcomingWindowDays = 30;

  final String storeId;
  final String employeeId;
  final String employeeName;

  final LateExcuseService _lateExcuseService;
  final AttendanceService _attendanceService;
  final StoreService _storeService;

  /// The store's IANA timezone, so an upcoming day is recorded as a calendar
  /// day in the store's timezone (matching how the check-in function resolves
  /// "today"). Falls back to the device timezone until loaded.
  String? _storeTimezone;

  StreamSubscription<List<LateExcuseRequest>>? _requestSub;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSub;

  List<LateExcuseRequest> _requests = [];
  List<AttendanceRecord> _history = [];
  bool _isLoading = false;
  bool _disposed = false;

  List<LateExcuseRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  /// Late days the employee can still request an excuse for: actually late,
  /// not already forgiven, and without an existing pending or approved request.
  List<AttendanceRecord> get excusableLateDays {
    final blockedDates = _requestedDays;

    return _history
        .where((a) =>
            a.lateMinutes > 0 &&
            !a.lateExcused &&
            !blockedDates.contains(_dayKey(a.date.toDate())))
        .toList();
  }

  /// Days that already have a pending or approved request.
  Set<String> get _requestedDays => _requests
      .where((r) => r.status != LateExcuseStatus.rejected)
      .map((r) => _dayKey(r.date))
      .toSet();

  DateTime get firstUpcomingDay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get lastUpcomingDay =>
      firstUpcomingDay.add(const Duration(days: upcomingWindowDays));

  /// Whether [day] can be picked as an upcoming late day: today or later
  /// within the window, not already requested, and not yet checked in (a day
  /// with a late check-in is requested from [excusableLateDays] instead).
  bool isUpcomingDaySelectable(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    if (date.isBefore(firstUpcomingDay) || date.isAfter(lastUpcomingDay)) {
      return false;
    }
    final key = _dayKey(date);
    if (_requestedDays.contains(key)) return false;
    return !_history.any((a) => _dayKey(a.date.toDate()) == key);
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _subscribe() {
    if (employeeId.isEmpty) return;

    _requestSub?.cancel();
    _requestSub = _lateExcuseService
        .streamEmployeeRequests(storeId, employeeId)
        .listen(
      (data) {
        _requests = data;
        if (!_disposed) notifyListeners();
      },
      // The listener stops for good after an error (e.g. a missing index),
      // leaving the list frozen — log it so the cause is visible.
      onError: (Object e) => debugPrint('Late excuse stream error: $e'),
    );

    _attendanceSub?.cancel();
    _attendanceSub = _attendanceService
        .streamHistory(storeId, employeeId, limit: 60)
        .listen(
      (data) {
        _history = data;
        if (!_disposed) notifyListeners();
      },
      onError: (Object e) => debugPrint('Attendance history stream error: $e'),
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

  /// Requests an excuse for a late day that has already happened.
  Future<void> submitRequest({
    required AttendanceRecord record,
    required String reason,
  }) =>
      _submit(
        date: record.date.toDate(),
        attendanceId: record.id,
        lateMinutes: record.lateMinutes,
        reason: reason,
      );

  /// Requests an excuse in advance for a day the employee expects to be late.
  /// No attendance record exists yet; if approved before check-in, the
  /// check-in marks the day excused.
  Future<void> submitUpcomingRequest({
    required DateTime day,
    required String reason,
  }) {
    if (!isUpcomingDaySelectable(day)) {
      throw Exception('This day cannot be selected.');
    }
    return _submit(
      date: tz.TZDateTime(_storeLocation, day.year, day.month, day.day),
      reason: reason,
    );
  }

  Future<void> _submit({
    required DateTime date,
    required String reason,
    String? attendanceId,
    int? lateMinutes,
  }) async {
    if (employeeId.isEmpty) {
      throw Exception('Employee ID is missing');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Please provide a reason.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final request = LateExcuseRequest(
        id: '', // Generated by Firestore.
        storeId: storeId,
        employeeId: employeeId,
        employeeName: employeeName,
        date: date,
        attendanceId: attendanceId,
        lateMinutes: lateMinutes,
        reason: reason.trim(),
        status: LateExcuseStatus.pending,
      );
      await _lateExcuseService.submitRequest(request);
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestSub?.cancel();
    _attendanceSub?.cancel();
    super.dispose();
  }
}
