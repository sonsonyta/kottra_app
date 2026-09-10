import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_settings.dart';
import 'package:kottra_app/models/store.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/attendance_sync_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/location_service.dart';
import 'package:kottra_app/services/offline_attendance_queue.dart';
import 'package:kottra_app/services/settings_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/view_models/attendance_view_model.dart';

class FakeUser implements User {
  FakeUser({required this.uid});

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.user});

  final User? user;

  @override
  User? get currentUser => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeAttendanceService implements AttendanceService {
  String? lastStoreId;
  String? lastEmployeeId;
  String? lastAttendanceId;
  double? lastLatitude;
  double? lastLongitude;
  String? lastQrToken;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  Object? checkInError;
  CheckInResult checkInResult = const CheckInResult(
    success: true,
    alreadyCheckedIn: false,
    attendanceId: 'att-1',
    status: AttendanceStatus.present,
  );
  CheckOutResult checkOutResult = const CheckOutResult(
    success: true,
    alreadyCheckedOut: false,
    attendanceId: 'att-1',
  );

  int? lastClientCheckInAt;
  int? lastClientCheckOutAt;

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
    checkInCalls++;
    lastStoreId = storeId;
    lastEmployeeId = employeeId;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastQrToken = qrToken;
    lastClientCheckInAt = clientCheckInAt;

    if (checkInError != null) throw checkInError!;
    return checkInResult;
  }

  @override
  Future<CheckOutResult> checkOut({
    required String storeId,
    required String attendanceId,
    required String employeeId,
    double? latitude,
    double? longitude,
    String? lateCheckInNote,
    String? earlyCheckOutNote,
    String? leaveNote,
    String? absentNote,
    String? qrToken,
    int? clientCheckOutAt,
  }) async {
    checkOutCalls++;
    lastStoreId = storeId;
    lastEmployeeId = employeeId;
    lastAttendanceId = attendanceId;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastQrToken = qrToken;
    lastClientCheckOutAt = clientCheckOutAt;

    return checkOutResult;
  }

  List<AttendanceRecord> history = const [];

  @override
  Stream<List<AttendanceRecord>> streamHistory(
    String storeId,
    String employeeId, {
    int limit = 30,
  }) => Stream.value(history);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeStoreService implements StoreService {
  FakeStoreService({this.store});

  final Store? store;

  @override
  Future<Store?> getStore(String storeId) async => store;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeSettingsService implements SettingsService {
  FakeSettingsService({this.settings});

  final HrSettings? settings;

  @override
  Stream<HrSettings> streamHrSettings(String storeId) =>
      settings == null ? const Stream.empty() : Stream.value(settings!);

  @override
  Future<HrSettings> getHrSettings(String storeId) async =>
      settings ?? HrSettings.defaults;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeEmployeeService implements EmployeeService {
  FakeEmployeeService({this.employee});

  final HREmployee? employee;

  @override
  Stream<HREmployee?> streamEmployee(String storeId, String employeeId) =>
      Stream.value(employee);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeLocationService implements LocationServiceBase {
  FakeLocationService({this.coords, this.error});

  final LocationCoords? coords;
  final Object? error;
  int calls = 0;

  @override
  Future<LocationCoords?> getCurrentCoords() async {
    calls++;
    if (error != null) throw error!;
    return coords;
  }
}

/// In-memory queue store so tests never touch SharedPreferences.
class InMemoryPendingStore implements PendingActionStore {
  final Map<String, List<String>> _data = {};

  @override
  Future<List<String>> read(String key) async => _data[key] ?? const [];

  @override
  Future<void> write(String key, List<String> values) async {
    if (values.isEmpty) {
      _data.remove(key);
    } else {
      _data[key] = List.of(values);
    }
  }
}

/// Connectivity probe with a controllable online flag, so tests can simulate
/// being offline without the platform plugin.
class FakeConnectivityProbe implements ConnectivityProbe {
  FakeConnectivityProbe({this.online = true});

  bool online;
  final _controller = StreamController<bool>.broadcast();

  void goOnline() {
    online = true;
    _controller.add(true);
  }

  @override
  Future<bool> hasConnection() async => online;

  @override
  Stream<bool> get onOnline => _controller.stream;
}

/// Builds a view model wired with in-memory offline infrastructure so no test
/// depends on platform channels.
AttendanceViewModel buildViewModel({
  required FakeAttendanceService attendanceService,
  required FakeLocationService locationService,
  String uid = 'hr_employee:store-1:emp-1',
  bool online = true,
  OfflineAttendanceQueue? queue,
  FakeConnectivityProbe? connectivity,
}) {
  return AttendanceViewModel(
    firebaseAuth: FakeFirebaseAuth(user: FakeUser(uid: uid)),
    attendanceService: attendanceService,
    locationService: locationService,
    storeService: FakeStoreService(),
    settingsService: FakeSettingsService(),
    employeeService: FakeEmployeeService(),
    offlineQueue: queue ?? OfflineAttendanceQueue(store: InMemoryPendingStore()),
    connectivity: connectivity ?? FakeConnectivityProbe(online: online),
  );
}

void main() {
  group('AttendanceViewModel.checkIn', () {
    test('passes identity and coordinates to attendance service', () async {
      final attendanceService = FakeAttendanceService();
      final locationService = FakeLocationService(
        coords: const LocationCoords(latitude: 11.5564, longitude: 104.9282),
      );
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: locationService,
      );

      final result = await viewModel.checkIn();

      expect(result, isNotNull);
      expect(result!.attendanceId, 'att-1');
      expect(locationService.calls, 1);
      expect(attendanceService.checkInCalls, 1);
      expect(attendanceService.lastStoreId, 'store-1');
      expect(attendanceService.lastEmployeeId, 'emp-1');
      expect(attendanceService.lastLatitude, 11.5564);
      expect(attendanceService.lastLongitude, 104.9282);
      expect(viewModel.isCheckedIn, isTrue);
      expect(viewModel.isActionLoading, isFalse);

      viewModel.dispose();
    });

    test('toggles loading state and resets it when check-in fails', () async {
      final attendanceService = FakeAttendanceService()
        ..checkInError = StateError('boom');
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: FakeLocationService(),
      );
      final loadingStates = <bool>[];

      viewModel.addListener(() {
        loadingStates.add(viewModel.isActionLoading);
      });

      await expectLater(viewModel.checkIn(), throwsA(isA<StateError>()));

      expect(loadingStates, containsAllInOrder([true, false]));
      expect(viewModel.isActionLoading, isFalse);

      viewModel.dispose();
    });

    test(
      'returns null without calling dependencies when identity is invalid',
      () async {
        final attendanceService = FakeAttendanceService();
        final locationService = FakeLocationService();
        final viewModel = buildViewModel(
          attendanceService: attendanceService,
          locationService: locationService,
          uid: 'invalid-user-id',
        );

        final result = await viewModel.checkIn();

        expect(result, isNull);
        expect(locationService.calls, 0);
        expect(attendanceService.checkInCalls, 0);
        expect(viewModel.isActionLoading, isFalse);

        viewModel.dispose();
      },
    );
  });

  group('AttendanceViewModel.todayRecord', () {
    test(
      'ignores a future-dated leave record when resolving today\'s attendance',
      () async {
        final now = DateTime.now();
        final futureLeave = AttendanceRecord(
          id: 'future-leave',
          storeId: 'store-1',
          employeeId: 'emp-1',
          employeeName: 'Employee',
          date: Timestamp.fromDate(now.add(const Duration(days: 3))),
          status: AttendanceStatus.leave,
        );
        final todayCheckIn = AttendanceRecord(
          id: 'today-checkin',
          storeId: 'store-1',
          employeeId: 'emp-1',
          employeeName: 'Employee',
          date: Timestamp.fromDate(now),
          checkIn: now,
          status: AttendanceStatus.present,
        );

        final attendanceService = FakeAttendanceService()
          ..history = [futureLeave, todayCheckIn];

        final viewModel = buildViewModel(
          attendanceService: attendanceService,
          locationService: FakeLocationService(),
        );

        // Let the fake history stream and store-timezone future resolve.
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.isCheckedIn, isTrue);
        expect(viewModel.todayRecord?.id, 'today-checkin');

        viewModel.dispose();
      },
    );
  });

  group('AttendanceViewModel offline check-in/out', () {
    test('queues check-in when offline instead of calling the backend',
        () async {
      final attendanceService = FakeAttendanceService();
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: FakeLocationService(
          coords: const LocationCoords(latitude: 1, longitude: 2),
        ),
        online: false,
      );

      final result = await viewModel.checkIn();

      expect(result, isNotNull);
      expect(result!.queuedOffline, isTrue);
      expect(attendanceService.checkInCalls, 0, reason: 'no network call');
      expect(viewModel.isCheckedIn, isTrue, reason: 'optimistic checked-in');
      expect(viewModel.hasPendingSync, isTrue);
      expect(viewModel.checkInTime, isNotNull);

      viewModel.dispose();
    });

    test('replays queued check-in with the original tap time on reconnect',
        () async {
      final attendanceService = FakeAttendanceService();
      final connectivity = FakeConnectivityProbe(online: false);
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: FakeLocationService(
          coords: const LocationCoords(latitude: 1, longitude: 2),
        ),
        connectivity: connectivity,
      );
      await Future<void>.delayed(Duration.zero); // let the syncer start

      final before = DateTime.now().millisecondsSinceEpoch;
      await viewModel.checkIn();
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(attendanceService.checkInCalls, 0);
      expect(viewModel.hasPendingSync, isTrue);

      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(attendanceService.checkInCalls, 1);
      expect(viewModel.hasPendingSync, isFalse, reason: 'queue drained');
      expect(attendanceService.lastLatitude, 1);
      expect(attendanceService.lastClientCheckInAt, isNotNull);
      expect(
        attendanceService.lastClientCheckInAt,
        inInclusiveRange(before, after),
        reason: 'sends the captured tap time, not the sync time',
      );

      viewModel.dispose();
    });

    test('replays an offline check-in then check-out in order', () async {
      final attendanceService = FakeAttendanceService();
      final connectivity = FakeConnectivityProbe(online: false);
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: FakeLocationService(),
        connectivity: connectivity,
      );
      await Future<void>.delayed(Duration.zero);

      await viewModel.checkIn();
      expect(viewModel.isCheckedIn, isTrue);
      await viewModel.checkOut();
      expect(viewModel.isCheckedIn, isFalse, reason: 'optimistic checked-out');
      expect(viewModel.checkOutTime, isNotNull);

      connectivity.goOnline();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(attendanceService.checkInCalls, 1);
      expect(attendanceService.checkOutCalls, 1);
      expect(attendanceService.lastAttendanceId, '',
          reason: 'empty id lets the backend resolve the open record');
      expect(viewModel.hasPendingSync, isFalse);

      viewModel.dispose();
    });

    test('falls back to the queue on a transient network error', () async {
      final attendanceService = FakeAttendanceService()
        ..checkInError = TimeoutException('offline blip');
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: FakeLocationService(),
        online: true,
      );

      final result = await viewModel.checkIn();

      expect(result!.queuedOffline, isTrue);
      expect(viewModel.hasPendingSync, isTrue);

      viewModel.dispose();
    });

    test('propagates a permanent error without queuing', () async {
      final attendanceService = FakeAttendanceService()
        ..checkInError = StateError('scheduled off');
      final viewModel = buildViewModel(
        attendanceService: attendanceService,
        locationService: FakeLocationService(),
        online: true,
      );

      await expectLater(viewModel.checkIn(), throwsA(isA<StateError>()));
      expect(viewModel.hasPendingSync, isFalse, reason: 'not queued');

      viewModel.dispose();
    });
  });
}
