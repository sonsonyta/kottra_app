import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/location_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/view_models/employee_identity.dart';
import 'package:timezone/timezone.dart' as tz;

export 'package:kottra_app/models/attendance_record.dart';
export 'package:kottra_app/services/attendance_service.dart' show CheckInResult;

class AttendanceViewModel extends ChangeNotifier {
  static const int maxHoursBeforeStaleCheckIn = 18;
  static const int minHoursBeforeNewCheckIn = 8;
  static const Duration optimisticTimeout = Duration(seconds: 10);

  AttendanceViewModel({
    FirebaseAuth? firebaseAuth,
    AttendanceService? attendanceService,
    LocationServiceBase? locationService,
    StoreService? storeService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _attendanceService = attendanceService ?? AttendanceService(),
       _locationService = locationService ?? const LocationService(),
       _storeService = storeService ?? StoreService() {
    _subscribeToAttendance();
    _loadStoreTimezone();
  }

  final FirebaseAuth _firebaseAuth;
  final AttendanceService _attendanceService;
  final LocationServiceBase _locationService;
  final StoreService _storeService;

  /// The store's configured IANA timezone (e.g. `Asia/Phnom_Penh`), used so
  /// shift/attendance-day calculations match the server regardless of the
  /// employee device's local timezone. Falls back to the device timezone
  /// until loaded or if the store hasn't been migrated to set it.
  String? _storeTimezone;

  StreamSubscription<List<AttendanceRecord>>? _historySub;

  AttendanceRecord? _todayRecord;
  List<AttendanceRecord> _history = [];

  String? _optimisticAttendanceId;
  DateTime? _optimisticCheckInAt;
  Timer? _optimisticTimer;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  bool _disposed = false;

  ({String storeId, String employeeId})? get _identity {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return null;
    return parseEmployeeUid(uid);
  }

  void _subscribeToAttendance() {
    final identity = _identity;
    if (identity == null) return;

    _historySub?.cancel();
    _historySub = _attendanceService
        .streamHistory(identity.storeId, identity.employeeId, limit: 90)
        .listen((records) {
          _history = records;
          _updateTodayRecord();
          notifyListeners();
        });
  }

  Future<void> _loadStoreTimezone() async {
    final identity = _identity;
    if (identity == null) return;

    try {
      final store = await _storeService.getStore(identity.storeId);
      _storeTimezone = store?.timezone;
    } catch (e) {
      debugPrint('Error loading store timezone: $e');
    }
    if (_disposed) return;
    _updateTodayRecord();
    notifyListeners();
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

  /// The current wall-clock time in the store's timezone.
  tz.TZDateTime _now() => tz.TZDateTime.now(_storeLocation);

  /// Converts an absolute instant to the store's timezone.
  tz.TZDateTime _inStoreZone(DateTime instant) =>
      tz.TZDateTime.from(instant, _storeLocation);

  void _updateTodayRecord() {
    if (_history.isEmpty) {
      _todayRecord = null;
      return;
    }

    final now = _now();

    final latest = _history.first;
    final recordDate = _inStoreZone(latest.date.toDate());
    final isTodayDate =
        recordDate.year == now.year &&
        recordDate.month == now.month &&
        recordDate.day == now.day;
    // If the latest record is still active (checked in but not checked out),
    // treat it as the current active record, even if it started yesterday.
    if (latest.checkIn != null && latest.checkOut == null) {
      // if miss check out and check in more than maxHoursBeforeStaleCheckIn hours
      final hoursSinceCheckIn = now.difference(latest.checkIn!).inHours;

      if (hoursSinceCheckIn > maxHoursBeforeStaleCheckIn) {
        // More than maxHoursBeforeStaleCheckIn hours since check-in
        // If they marked absent or leave today, they can't check in.
        if (isTodayDate &&
            (latest.status == AttendanceStatus.absent ||
                latest.status == AttendanceStatus.leave)) {
          _todayRecord = latest;
        } else {
          _todayRecord = null;
        }
      } else {
        _todayRecord = latest;
      }
    } else {
      if (latest.checkOut != null) {
        final hoursSinceCheckOut = now.difference(latest.checkOut!).inHours;
        if (hoursSinceCheckOut < minHoursBeforeNewCheckIn) {
          // Less than minHoursBeforeNewCheckIn hours since check-out
          _todayRecord = latest;
        } else {
          // More than minHoursBeforeNewCheckIn hours since check-out
          // If they marked absent or leave today, they can't check in.
          if (isTodayDate &&
              (latest.status == AttendanceStatus.absent ||
                  latest.status == AttendanceStatus.leave)) {
            _todayRecord = latest;
          } else {
            _todayRecord = null;
          }
        }
      } else {
        // No checkOut time, so they are either still checked in (handled above)
        // or they were marked absent/leave (which has no checkIn/checkOut).
        if (isTodayDate) {
          _todayRecord = latest;
        } else {
          _todayRecord = null;
        }
      }
    }

    if (_todayRecord?.checkIn != null) {
      _optimisticTimer?.cancel();
      _optimisticTimer = null;
      _optimisticAttendanceId = null;
      _optimisticCheckInAt = null;
    }
  }

  bool get isOnLeave => _todayRecord?.status == AttendanceStatus.leave;
  bool get isAbsent => _todayRecord?.status == AttendanceStatus.absent;
  AttendanceRecord? get todayRecord => _todayRecord;

  bool get isCheckedIn {
    final record = _todayRecord;
    if (record?.checkIn != null) {
      return record!.checkOut == null;
    }
    return _optimisticCheckInAt != null;
  }

  DateTime? get checkInTime => _todayRecord?.checkIn ?? _optimisticCheckInAt;
  DateTime? get checkOutTime => _todayRecord?.checkOut;

  List<AttendanceRecord> get attendanceRecords => _history;

  List<AttendanceRecord> getRecordsForDay(DateTime day) {
    return _history.where((r) {
      final rDate = r.date.toDate();
      return rDate.year == day.year && rDate.month == day.month && rDate.day == day.day;
    }).toList();
  }

  bool isLateCheckIn(String? startWorkingTime, int? lateTime) {
    if (startWorkingTime == null || startWorkingTime.isEmpty) return false;
    final parts = startWorkingTime.split(':');
    if (parts.length != 2) return false;
    final startHour = int.tryParse(parts[0]) ?? 0;
    final startMin = int.tryParse(parts[1]) ?? 0;
    final grace = lateTime ?? 0;

    final now = _now();
    final limitTime = tz.TZDateTime(_storeLocation, now.year, now.month, now.day, startHour, startMin)
        .add(Duration(minutes: grace));

    return now.isAfter(limitTime);
  }

  bool isEarlyCheckOut(String? startWorkingTime, String? endWorkingTime) {
    if (endWorkingTime == null || endWorkingTime.isEmpty || startWorkingTime == null || startWorkingTime.isEmpty) return false;

    final startParts = startWorkingTime.split(':');
    final endParts = endWorkingTime.split(':');

    if (startParts.length != 2 || endParts.length != 2) return false;

    final startHour = int.tryParse(startParts[0]) ?? 0;
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMin = int.tryParse(endParts[1]) ?? 0;

    final now = _now();
    tz.TZDateTime endTime = tz.TZDateTime(_storeLocation, now.year, now.month, now.day, endHour, endMin);

    // Cross-day schedule detection
    if (endHour < startHour) {
      if (now.hour >= startHour) {
        // If checking out before midnight (e.g., 23:00), the shift ends tomorrow.
        endTime = endTime.add(const Duration(days: 1));
      }
    }

    return now.isBefore(endTime);
  }

  Future<CheckInResult?> checkIn({
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
  }) async {
    if (_isActionLoading) return null;
    final identity = _identity;
    if (identity == null) return null;

    _isActionLoading = true;
    notifyListeners();
    try {
      dynamic coords;
      try {
        coords = await _locationService.getCurrentCoords();
      } catch (e) {
        debugPrint('Location error during check-in: $e');
      }

      final result = await _attendanceService.checkIn(
        storeId: identity.storeId,
        employeeId: identity.employeeId,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
        lateCheckInNote: lateCheckInNote,
        earlyCheckOutNote: earlyCheckOutNote,
        leaveNote: leaveNote,
        absentNote: absentNote,
      );

      if (result.success && !result.alreadyCheckedIn) {
        _optimisticAttendanceId = result.attendanceId;
        _optimisticCheckInAt = DateTime.now();
        _optimisticTimer?.cancel();
        _optimisticTimer = Timer(optimisticTimeout, () {
          if (_optimisticCheckInAt != null && _todayRecord?.checkIn == null) {
            _optimisticCheckInAt = null;
            _optimisticAttendanceId = null;
            if (!_disposed) notifyListeners();
          }
        });
        if (!_disposed) notifyListeners();
      }
      return result;
    } finally {
      _isActionLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<CheckOutResult?> checkOut({
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
  }) async {
    if (_isActionLoading) return null;
    final identity = _identity;
    if (identity == null) return null;

    final attendanceId = _todayRecord?.id ?? _optimisticAttendanceId;
    if (attendanceId == null) return null;

    _isActionLoading = true;
    notifyListeners();
    try {
      dynamic coords;
      try {
        coords = await _locationService.getCurrentCoords();
      } catch (e) {
        debugPrint('Location error during check-out: $e');
      }

      final result = await _attendanceService.checkOut(
        storeId: identity.storeId,
        attendanceId: attendanceId,
        employeeId: identity.employeeId,
        latitude: coords?.latitude,
        longitude: coords?.longitude,
        lateCheckInNote: lateCheckInNote,
        earlyCheckOutNote: earlyCheckOutNote,
        leaveNote: leaveNote,
        absentNote: absentNote,
      );

      if (result.success && !result.alreadyCheckedOut) {
        _optimisticAttendanceId = result.attendanceId;
        _optimisticCheckInAt = null;
        _optimisticTimer?.cancel();
        if (!_disposed) notifyListeners();
      }
      return result;
    } finally {
      _isActionLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _optimisticTimer?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}
