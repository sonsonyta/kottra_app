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

  StreamSubscription<AttendanceRecord?>? _todaySub;
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

    _todaySub?.cancel();
    _todaySub = _attendanceService
        .streamTodayRecord(identity.storeId, identity.employeeId)
        .listen((record) {
      _todayRecord = record;
      if (record?.checkIn != null) {
        _optimisticAttendanceId = null;
        _optimisticCheckInAt = null;
      }
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

  Future<CheckInResult?> checkIn() async {
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

  Future<CheckOutResult?> checkOut() async {
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
      );

      if (result.success && !result.alreadyCheckedOut) {
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

  @override
  void dispose() {
    _todaySub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}

