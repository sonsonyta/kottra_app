import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/location_service.dart';
import 'package:kottra_app/viewmodels/employee_identity.dart';

export 'package:kottra_app/models/attendance_record.dart';
export 'package:kottra_app/services/attendance_service.dart' show CheckInResult;

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel({
    FirebaseAuth? firebaseAuth,
    AttendanceService? attendanceService,
    LocationServiceBase? locationService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _attendanceService = attendanceService ?? AttendanceService(),
        _locationService = locationService ?? const LocationService() {
    _subscribeToAttendance();
  }

  final FirebaseAuth _firebaseAuth;
  final AttendanceService _attendanceService;
  final LocationServiceBase _locationService;

  StreamSubscription<List<AttendanceRecord>>? _historySub;

  AttendanceRecord? _todayRecord;
  List<AttendanceRecord> _history = [];

  String? _optimisticAttendanceId;
  DateTime? _optimisticCheckInAt;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

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
        .streamHistory(identity.storeId, identity.employeeId)
        .listen((records) {
      _history = records;
      _updateTodayRecord();
      notifyListeners();
    });
  }

  void _updateTodayRecord() {
    if (_history.isEmpty) {
      _todayRecord = null;
      return;
    }

    final latest = _history.first;
    // If the latest record is still active (checked in but not checked out),
    // treat it as the current active record, even if it started yesterday.
    if (latest.checkIn != null && latest.checkOut == null) {
      _todayRecord = latest;
    } else {
      final now = DateTime.now();
      final recordDate = latest.date.toDate();
      final isTodayDate = recordDate.year == now.year && recordDate.month == now.month && recordDate.day == now.day;
      
      if (latest.checkOut != null) {
        final hoursSinceCheckOut = now.difference(latest.checkOut!).inHours;
        if (hoursSinceCheckOut < 10) {
          // Less than 10 hours since check-out
          _todayRecord = latest;
        } else {
          // More than 10 hours since check-out
          // If they marked absent or leave today, they can't check in.
          if (isTodayDate && (latest.status == AttendanceStatus.absent || latest.status == AttendanceStatus.leave)) {
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

  Future<CheckInResult?> checkIn({
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
  }) async {
    final identity = _identity;
    if (identity == null) return null;

    _isActionLoading = true;
    notifyListeners();
    try {
      final coords = await _locationService.getCurrentCoords();
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
        notifyListeners();
      }
      return result;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<CheckOutResult?> checkOut({
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
  }) async {
    final identity = _identity;
    if (identity == null) return null;

    final attendanceId = _todayRecord?.id ?? _optimisticAttendanceId;
    if (attendanceId == null) return null;

    _isActionLoading = true;
    notifyListeners();
    try {
      final coords = await _locationService.getCurrentCoords();
      final result  = await _attendanceService.checkOut(
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
        notifyListeners();
      }
      return result;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }
}

