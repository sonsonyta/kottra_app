import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_settings.dart';
import 'package:kottra_app/models/payroll_deductions.dart';
import 'package:kottra_app/models/pending_attendance_action.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/attendance_sync_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/location_service.dart';
import 'package:kottra_app/services/offline_attendance_queue.dart';
import 'package:kottra_app/services/settings_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/view_models/employee_identity.dart';
import 'package:timezone/timezone.dart' as tz;

export 'package:kottra_app/models/attendance_record.dart';
export 'package:kottra_app/models/payroll_deductions.dart';
export 'package:kottra_app/services/attendance_service.dart'
    show CheckInResult, CheckOutResult;

class AttendanceViewModel extends ChangeNotifier {
  static const int maxHoursBeforeStaleCheckIn = 18;
  static const int minHoursBeforeNewCheckIn = 8;
  static const Duration optimisticTimeout = Duration(seconds: 10);

  AttendanceViewModel({
    FirebaseAuth? firebaseAuth,
    AttendanceService? attendanceService,
    LocationServiceBase? locationService,
    StoreService? storeService,
    SettingsService? settingsService,
    EmployeeService? employeeService,
    OfflineAttendanceQueue? offlineQueue,
    AttendanceSyncService? syncService,
    ConnectivityProbe? connectivity,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _attendanceService = attendanceService ?? AttendanceService(),
       _locationService = locationService ?? const LocationService(),
       _storeService = storeService ?? StoreService(),
       _settingsService = settingsService ?? SettingsService(),
       _employeeService = employeeService ?? EmployeeService(),
       _queue = offlineQueue ?? OfflineAttendanceQueue() {
    _syncService = syncService ??
        AttendanceSyncService(
          queue: _queue,
          attendanceService: _attendanceService,
          connectivity: connectivity,
        );
    _subscribeToAttendance();
    _subscribeToDeductionInputs();
    _loadStoreTimezone();
    _initOfflineQueue();
  }

  final FirebaseAuth _firebaseAuth;
  final AttendanceService _attendanceService;
  final LocationServiceBase _locationService;
  final StoreService _storeService;
  final SettingsService _settingsService;
  final EmployeeService _employeeService;
  final OfflineAttendanceQueue _queue;
  late final AttendanceSyncService _syncService;

  /// The store's configured IANA timezone (e.g. `Asia/Phnom_Penh`), used so
  /// shift/attendance-day calculations match the server regardless of the
  /// employee device's local timezone. Falls back to the device timezone
  /// until loaded or if the store hasn't been migrated to set it.
  String? _storeTimezone;

  StreamSubscription<List<AttendanceRecord>>? _historySub;
  StreamSubscription<HrSettings>? _settingsSub;
  StreamSubscription<HREmployee?>? _employeeSub;

  HrSettings? _hrSettings;
  HREmployee? _employee;

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

  /// Loads any check-in/out actions queued under this employee, keeps the UI
  /// in sync with queue changes, and starts the background syncer so they
  /// replay as soon as connectivity is available.
  Future<void> _initOfflineQueue() async {
    final identity = _identity;
    if (identity == null) return;
    _queue.addListener(_onQueueChanged);
    await _queue.loadFor(identity.storeId, identity.employeeId);
    _syncService.start();
    if (!_disposed) notifyListeners();
  }

  void _onQueueChanged() {
    if (!_disposed) notifyListeners();
  }

  /// The most recently queued action for this employee, or null when the queue
  /// is empty. Drives the optimistic offline UI state until the action syncs
  /// and the Firestore stream takes over.
  PendingAttendanceAction? get _latestPending {
    final identity = _identity;
    if (identity == null) return null;
    PendingAttendanceAction? latest;
    for (final a in _queue.actions) {
      if (a.storeId == identity.storeId && a.employeeId == identity.employeeId) {
        latest = a;
      }
    }
    return latest;
  }

  /// Whether one or more check-in/out actions are waiting to sync.
  bool get hasPendingSync => _latestPending != null;

  /// Whether the syncer is currently replaying queued actions.
  bool get isSyncing => _syncService.isSyncing;

  String _newLocalId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

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

  /// Streams the two slow-moving inputs to the deduction figure — the store's
  /// HR settings and the employee's own record (salary/currency). The running
  /// deduction itself recomputes live off the attendance stream; these just
  /// keep the config and salary current.
  void _subscribeToDeductionInputs() {
    final identity = _identity;
    if (identity == null) return;

    _settingsSub?.cancel();
    _settingsSub = _settingsService
        .streamHrSettings(identity.storeId)
        .listen((settings) {
          _hrSettings = settings;
          if (!_disposed) notifyListeners();
        }, onError: (Object e) => debugPrint('Error loading HR settings: $e'));

    _employeeSub?.cancel();
    _employeeSub = _employeeService
        .streamEmployee(identity.storeId, identity.employeeId)
        .listen((employee) {
          _employee = employee;
          if (!_disposed) notifyListeners();
        }, onError: (Object e) => debugPrint('Error loading employee: $e'));
  }

  /// The employee's accrued late + absence deductions for the current pay
  /// period, or `null` when unavailable — the settings/employee haven't loaded
  /// yet, or the store has hidden the preview
  /// (`allowDisplayPreviewDeduction` = false). Callers hide their card on null.
  /// Recomputed on demand so it always reflects the latest attendance stream.
  DeductionBreakdown? get periodDeductions {
    final employee = _employee;
    final settings = _hrSettings;
    if (employee == null || settings == null) return null;
    if (!settings.allowDisplayPreviewDeduction) return null;
    return computePeriodDeductions(
      records: _history,
      monthlyBasicSalary: employee.basicSalary,
      currency: employee.currency,
      settings: settings,
      today: _now(),
      toStoreZone: _inStoreZone,
    );
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

    // Ignore records dated after right now — e.g. attendance placeholders
    // created for an approved future leave request. _history is already
    // ordered newest-first by `date`, so a future-dated record would
    // otherwise always outrank today's real check-in/check-out and mask
    // the employee's actual attendance state until that future date passes.
    final relevantHistory = _history.where(
      (r) => !_inStoreZone(r.date.toDate()).isAfter(now),
    );
    if (relevantHistory.isEmpty) {
      _todayRecord = null;
      return;
    }

    final latest = relevantHistory.first;
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
        // If they marked absent, leave, or day off today, they can't check in.
        if (isTodayDate &&
            (latest.status == AttendanceStatus.absent ||
                latest.status == AttendanceStatus.leave ||
                latest.status == AttendanceStatus.dayOff)) {
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
          // If they marked absent, leave, or day off today, they can't check in.
          if (isTodayDate &&
              (latest.status == AttendanceStatus.absent ||
                  latest.status == AttendanceStatus.leave ||
                  latest.status == AttendanceStatus.dayOff)) {
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

  /// The store this employee belongs to, or null before auth is ready. Used by
  /// the QR scanner to check the scanned code targets the right store.
  String? get storeId => _identity?.storeId;

  /// Whether check-in/out should go through a QR scan of the store's posted
  /// code. True only when the master feature flag is on and the store has
  /// opted into [AttendanceMethod.qr]; otherwise the plain button is used.
  bool get usesQrAttendance =>
      FeatureFlags.enableQrAttendance &&
      _hrSettings?.attendanceMethod == AttendanceMethod.qr;

  bool get isOnLeave => _todayRecord?.status == AttendanceStatus.leave;
  bool get isAbsent => _todayRecord?.status == AttendanceStatus.absent;
  bool get isDayOff => _todayRecord?.status == AttendanceStatus.dayOff;
  AttendanceRecord? get todayRecord => _todayRecord;

  bool get isCheckedIn {
    // A queued (offline) action is the freshest intent until it syncs.
    final pending = _latestPending;
    if (pending != null) {
      return pending.kind == PendingAttendanceKind.checkIn;
    }
    final record = _todayRecord;
    if (record?.checkIn != null) {
      return record!.checkOut == null;
    }
    return _optimisticCheckInAt != null;
  }

  DateTime? get checkInTime {
    final pending = _latestPending;
    if (pending?.kind == PendingAttendanceKind.checkIn) {
      return pending!.eventTime;
    }
    // A pending check-out keeps the existing check-in time visible.
    return _todayRecord?.checkIn ?? _optimisticCheckInAt;
  }

  DateTime? get checkOutTime {
    final pending = _latestPending;
    if (pending?.kind == PendingAttendanceKind.checkOut) {
      return pending!.eventTime;
    }
    return _todayRecord?.checkOut;
  }

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
    String? qrToken,
  }) async {
    if (_isActionLoading) return null;
    final identity = _identity;
    if (identity == null) return null;

    _isActionLoading = true;
    notifyListeners();
    try {
      // Capture the real tap time up front so an offline replay records when
      // the employee actually checked in, not when the queue drains.
      final eventAt = DateTime.now();
      final coords = await _tryGetCoords('check-in');

      final online = await _syncService.isOnline();
      if (online) {
        try {
          final result = await _attendanceService.checkIn(
            storeId: identity.storeId,
            employeeId: identity.employeeId,
            latitude: coords?.latitude,
            longitude: coords?.longitude,
            lateCheckInNote: lateCheckInNote,
            earlyCheckOutNote: earlyCheckOutNote,
            leaveNote: leaveNote,
            absentNote: absentNote,
            qrToken: qrToken,
            clientCheckInAt: eventAt.millisecondsSinceEpoch,
          );

          if (result.success && !result.alreadyCheckedIn) {
            _optimisticAttendanceId = result.attendanceId;
            _optimisticCheckInAt = eventAt;
            _optimisticTimer?.cancel();
            _optimisticTimer = Timer(optimisticTimeout, () {
              if (_optimisticCheckInAt != null &&
                  _todayRecord?.checkIn == null) {
                _optimisticCheckInAt = null;
                _optimisticAttendanceId = null;
                if (!_disposed) notifyListeners();
              }
            });
            if (!_disposed) notifyListeners();
          }
          return result;
        } catch (e) {
          // Permanent errors (geofence, scheduled-off, auth) must surface so
          // the employee sees why; only transient/network failures fall back
          // to the offline queue.
          if (!isTransientAttendanceError(e)) rethrow;
          debugPrint('Check-in call failed transiently, queuing offline: $e');
        }
      }

      await _enqueueAction(
        PendingAttendanceAction(
          localId: _newLocalId(),
          kind: PendingAttendanceKind.checkIn,
          storeId: identity.storeId,
          employeeId: identity.employeeId,
          clientEventAt: eventAt.millisecondsSinceEpoch,
          latitude: coords?.latitude,
          longitude: coords?.longitude,
          lateCheckInNote: lateCheckInNote,
          earlyCheckOutNote: earlyCheckOutNote,
          leaveNote: leaveNote,
          absentNote: absentNote,
          qrToken: qrToken,
        ),
      );
      return CheckInResult.queued();
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
    String? qrToken,
  }) async {
    if (_isActionLoading) return null;
    final identity = _identity;
    if (identity == null) return null;

    // The server attendance id when the open record already synced. Null while
    // the matching check-in is itself still queued — the backend then resolves
    // the open record from employeeId on replay.
    final attendanceId = _todayRecord?.id ?? _optimisticAttendanceId;
    // Nothing to check out of unless we're checked in (a queued check-in
    // counts, via isCheckedIn) or we have a concrete record id.
    if (attendanceId == null && !isCheckedIn) return null;

    _isActionLoading = true;
    notifyListeners();
    try {
      final eventAt = DateTime.now();
      final coords = await _tryGetCoords('check-out');

      final online = await _syncService.isOnline();
      // Only call directly when online AND the record already has a server id;
      // otherwise queue it so the syncer replays check-in → check-out in order.
      if (online && attendanceId != null) {
        try {
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
            qrToken: qrToken,
            clientCheckOutAt: eventAt.millisecondsSinceEpoch,
          );

          if (result.success && !result.alreadyCheckedOut) {
            _optimisticAttendanceId = result.attendanceId;
            _optimisticCheckInAt = null;
            _optimisticTimer?.cancel();
            if (!_disposed) notifyListeners();
          }
          return result;
        } catch (e) {
          if (!isTransientAttendanceError(e)) rethrow;
          debugPrint('Check-out call failed transiently, queuing offline: $e');
        }
      }

      await _enqueueAction(
        PendingAttendanceAction(
          localId: _newLocalId(),
          kind: PendingAttendanceKind.checkOut,
          storeId: identity.storeId,
          employeeId: identity.employeeId,
          clientEventAt: eventAt.millisecondsSinceEpoch,
          attendanceId: attendanceId,
          latitude: coords?.latitude,
          longitude: coords?.longitude,
          lateCheckInNote: lateCheckInNote,
          earlyCheckOutNote: earlyCheckOutNote,
          leaveNote: leaveNote,
          absentNote: absentNote,
          qrToken: qrToken,
        ),
      );
      return CheckOutResult.queued();
    } finally {
      _isActionLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<dynamic> _tryGetCoords(String context) async {
    try {
      return await _locationService.getCurrentCoords();
    } catch (e) {
      debugPrint('Location error during $context: $e');
      return null;
    }
  }

  Future<void> _enqueueAction(PendingAttendanceAction action) async {
    await _queue.enqueue(action);
    // Attempt an immediate drain in case connectivity has since returned; the
    // syncer is a no-op when truly offline and retries on the next reconnect.
    unawaited(_syncService.sync());
  }

  @override
  void dispose() {
    _disposed = true;
    _optimisticTimer?.cancel();
    _historySub?.cancel();
    _settingsSub?.cancel();
    _employeeSub?.cancel();
    _queue.removeListener(_onQueueChanged);
    _syncService.dispose();
    super.dispose();
  }
}
