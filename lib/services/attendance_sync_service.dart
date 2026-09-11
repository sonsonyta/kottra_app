import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:kottra_app/models/pending_attendance_action.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/offline_attendance_queue.dart';

/// Thrown internally when a replay fails for a reason worth retrying later
/// (no network, backend unavailable). Permanent failures propagate instead so
/// the action is dropped rather than poisoning the queue forever.
class _TransientSyncError implements Exception {
  const _TransientSyncError(this.message);
  final String message;
}

/// Firebase Functions error codes that are transient — the same request may
/// succeed once connectivity/backend recover, so we keep the action queued.
const Set<String> _transientCodes = {
  'unavailable',
  'deadline-exceeded',
  'internal',
  'resource-exhausted',
  'aborted',
  'cancelled',
  'unknown',
};

/// Whether a failed check-in/out call is worth queuing and retrying rather than
/// surfacing to the employee. Only genuine connectivity/backend-availability
/// failures qualify; anything else (geofence, scheduled-off, auth, or an
/// unexpected programming error) is permanent and must propagate.
bool isTransientAttendanceError(Object error) {
  if (error is FirebaseFunctionsException) {
    return _transientCodes.contains(error.code);
  }
  if (error is TimeoutException) return true;
  if (error is SocketException) return true;
  if (error is HandshakeException) return true;
  return false;
}

/// Minimal connectivity abstraction so the syncer can be exercised in tests
/// without the platform plugin.
abstract class ConnectivityProbe {
  /// Whether a network link is currently present.
  Future<bool> hasConnection();

  /// Emits `true` whenever the device gains a usable link.
  Stream<bool> get onOnline;
}

/// Default probe backed by connectivity_plus. Link presence only — a real
/// request that still fails just stays queued for the next attempt.
class ConnectivityPlusProbe implements ConnectivityProbe {
  ConnectivityPlusProbe([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _hasLink(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasLink(results);
  }

  @override
  Stream<bool> get onOnline =>
      _connectivity.onConnectivityChanged.map(_hasLink).where((online) => online);
}

/// Drains the [OfflineAttendanceQueue] against the backend, oldest action
/// first, whenever connectivity is available. Owns a connectivity subscription
/// so a device coming back online auto-syncs without user action.
class AttendanceSyncService extends ChangeNotifier {
  AttendanceSyncService({
    required OfflineAttendanceQueue queue,
    required AttendanceService attendanceService,
    ConnectivityProbe? connectivity,
  })  : _queue = queue,
        _attendanceService = attendanceService,
        _connectivity = connectivity ?? ConnectivityPlusProbe();

  final OfflineAttendanceQueue _queue;
  final AttendanceService _attendanceService;
  final ConnectivityProbe _connectivity;

  /// How often to re-attempt a drain while actions remain queued. Guards
  /// against a single transient failure (e.g. an App Check attestation race at
  /// cold start) leaving the queue stuck when the device stays continuously
  /// online and never fires an offline→online transition.
  static const Duration retryInterval = Duration(seconds: 30);

  StreamSubscription<bool>? _connSub;
  Timer? _retryTimer;
  bool _isSyncing = false;
  String? _lastError;
  bool _disposed = false;

  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  /// Begins auto-syncing: kicks a sync now, on every connectivity change that
  /// reports a usable link, and on a periodic timer while the queue is
  /// non-empty (so a transient failure eventually recovers on its own).
  void start() {
    _connSub ??= _connectivity.onOnline.listen(
      (_) => unawaited(sync()),
      onError: (Object e) => debugPrint('Connectivity stream error: $e'),
    );
    _queue.addListener(_manageRetryTimer);
    _manageRetryTimer();
    unawaited(sync());
  }

  /// Runs the retry timer only while something is queued; stops it once the
  /// queue drains so we don't wake up on a fixed interval for no reason.
  void _manageRetryTimer() {
    if (_disposed) return;
    if (_queue.isNotEmpty) {
      _retryTimer ??=
          Timer.periodic(retryInterval, (_) => unawaited(sync()));
    } else {
      _retryTimer?.cancel();
      _retryTimer = null;
    }
  }

  /// Whether the device currently reports a network link. This reflects link
  /// presence, not guaranteed internet reachability — a replay that still fails
  /// simply stays queued.
  Future<bool> isOnline() async {
    try {
      return await _connectivity.hasConnection();
    } catch (_) {
      // If connectivity can't be determined, assume online and let the actual
      // call decide; a failure falls back to the queue.
      return true;
    }
  }

  /// Replays queued actions FIFO. No-op when already running, when the queue is
  /// empty, or when the device reports no connectivity (the reconnect listener
  /// will drive the next attempt). Stops early on the first transient failure
  /// so ordering is preserved for the next attempt.
  Future<void> sync() async {
    if (_isSyncing || _queue.isEmpty) return;
    if (!await isOnline()) return;
    _isSyncing = true;
    _lastError = null;
    _safeNotify();
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final action = _queue.actions.first;
        try {
          await _replay(action);
          await _queue.remove(action.localId);
        } on _TransientSyncError catch (e) {
          _lastError = e.message;
          // Leave the action (and everything after it) queued for next time.
          break;
        } catch (e) {
          // Permanent failure: drop so it can't block the rest of the queue,
          // but surface it so the UI/logs can explain the lost action.
          _lastError = _describe(e);
          debugPrint('Dropping attendance action ${action.localId}: $_lastError');
          await _queue.remove(action.localId);
        }
      }
    } finally {
      _isSyncing = false;
      _safeNotify();
    }
  }

  Future<void> _replay(PendingAttendanceAction action) async {
    try {
      if (action.kind == PendingAttendanceKind.checkIn) {
        await _attendanceService.checkIn(
          storeId: action.storeId,
          employeeId: action.employeeId,
          latitude: action.latitude,
          longitude: action.longitude,
          lateCheckInNote: action.lateCheckInNote,
          earlyCheckOutNote: action.earlyCheckOutNote,
          leaveNote: action.leaveNote,
          absentNote: action.absentNote,
          qrToken: action.qrToken,
          clientCheckInAt: action.clientEventAt,
        );
      } else {
        await _attendanceService.checkOut(
          storeId: action.storeId,
          // Empty attendanceId lets the backend resolve the open record from
          // employeeId — needed when the matching check-in was itself offline
          // and only just replayed.
          attendanceId: action.attendanceId ?? '',
          employeeId: action.employeeId,
          latitude: action.latitude,
          longitude: action.longitude,
          lateCheckInNote: action.lateCheckInNote,
          earlyCheckOutNote: action.earlyCheckOutNote,
          leaveNote: action.leaveNote,
          absentNote: action.absentNote,
          qrToken: action.qrToken,
          clientCheckOutAt: action.clientEventAt,
        );
      }
    } catch (e) {
      if (isTransientAttendanceError(e)) {
        throw _TransientSyncError(_describe(e));
      }
      rethrow; // permanent — caller drops it
    }
  }

  String _describe(Object e) {
    if (e is FirebaseFunctionsException) return e.message ?? e.code;
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _queue.removeListener(_manageRetryTimer);
    _connSub?.cancel();
    super.dispose();
  }
}
