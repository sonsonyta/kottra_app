import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/pending_attendance_action.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/attendance_sync_service.dart';
import 'package:kottra_app/services/offline_attendance_queue.dart';

class InMemoryPendingStore implements PendingActionStore {
  final Map<String, List<String>> data = {};

  @override
  Future<List<String>> read(String key) async => data[key] ?? const [];

  @override
  Future<void> write(String key, List<String> values) async {
    if (values.isEmpty) {
      data.remove(key);
    } else {
      data[key] = List.of(values);
    }
  }
}

/// Attendance service whose check-in result/error can be scripted per call by
/// local id, so tests can make specific queued actions fail.
class ScriptedAttendanceService implements AttendanceService {
  final List<String> checkedInEvents = [];
  final Map<int, Object> errorByClientTime = {};

  @override
  Future<CheckInResult> checkIn({
    required String storeId,
    required String employeeId,
    double? latitude,
    double? longitude,
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
    String? qrToken,
    int? clientCheckInAt,
  }) async {
    final error = errorByClientTime[clientCheckInAt];
    if (error != null) throw error;
    checkedInEvents.add('$clientCheckInAt');
    return CheckInResult(
      success: true,
      alreadyCheckedIn: false,
      attendanceId: 'att-$clientCheckInAt',
      status: AttendanceStatus.present,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeConnectivityProbe implements ConnectivityProbe {
  FakeConnectivityProbe({this.online = true});
  bool online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> hasConnection() async => online;

  @override
  Stream<bool> get onOnline => _controller.stream;
}

PendingAttendanceAction _checkIn(int clientEventAt) => PendingAttendanceAction(
      localId: 'a$clientEventAt',
      kind: PendingAttendanceKind.checkIn,
      storeId: 'store-1',
      employeeId: 'emp-1',
      clientEventAt: clientEventAt,
    );

Future<OfflineAttendanceQueue> _queueWith(
    List<PendingAttendanceAction> actions) async {
  final queue = OfflineAttendanceQueue(store: InMemoryPendingStore());
  await queue.loadFor('store-1', 'emp-1');
  for (final a in actions) {
    await queue.enqueue(a);
  }
  return queue;
}

void main() {
  group('AttendanceSyncService.sync', () {
    test('drains all actions FIFO when online', () async {
      final queue = await _queueWith([_checkIn(1), _checkIn(2)]);
      final service = ScriptedAttendanceService();
      final sync = AttendanceSyncService(
        queue: queue,
        attendanceService: service,
        connectivity: FakeConnectivityProbe(online: true),
      );

      await sync.sync();

      expect(service.checkedInEvents, ['1', '2']);
      expect(queue.isEmpty, isTrue);
    });

    test('does nothing while offline', () async {
      final queue = await _queueWith([_checkIn(1)]);
      final service = ScriptedAttendanceService();
      final sync = AttendanceSyncService(
        queue: queue,
        attendanceService: service,
        connectivity: FakeConnectivityProbe(online: false),
      );

      await sync.sync();

      expect(service.checkedInEvents, isEmpty);
      expect(queue.isNotEmpty, isTrue, reason: 'stays queued for reconnect');
    });

    test('stops on a transient error and keeps the action queued', () async {
      final queue = await _queueWith([_checkIn(1), _checkIn(2)]);
      final service = ScriptedAttendanceService()
        ..errorByClientTime[1] = TimeoutException('blip');
      final sync = AttendanceSyncService(
        queue: queue,
        attendanceService: service,
        connectivity: FakeConnectivityProbe(online: true),
      );

      await sync.sync();

      expect(service.checkedInEvents, isEmpty);
      expect(queue.actions.map((a) => a.localId), ['a1', 'a2'],
          reason: 'nothing dropped; ordering preserved');
    });

    test('drops a permanently-failing action and continues', () async {
      final queue = await _queueWith([_checkIn(1), _checkIn(2)]);
      final service = ScriptedAttendanceService()
        ..errorByClientTime[1] = StateError('scheduled off');
      final sync = AttendanceSyncService(
        queue: queue,
        attendanceService: service,
        connectivity: FakeConnectivityProbe(online: true),
      );

      await sync.sync();

      expect(service.checkedInEvents, ['2'], reason: 'poison action dropped');
      expect(queue.isEmpty, isTrue);
      expect(sync.lastError, isNotNull);
    });
  });
}
