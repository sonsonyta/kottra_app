import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/late_excuse_request.dart';
import 'package:kottra_app/models/store.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/late_excuse_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/view_models/late_excuse_view_model.dart';

class FakeLateExcuseService implements LateExcuseService {
  final requests = StreamController<List<LateExcuseRequest>>();
  final submitted = <LateExcuseRequest>[];

  @override
  Stream<List<LateExcuseRequest>> streamEmployeeRequests(
          String storeId, String employeeId) =>
      requests.stream;

  @override
  Future<void> submitRequest(LateExcuseRequest request) async =>
      submitted.add(request);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAttendanceService implements AttendanceService {
  final history = StreamController<List<AttendanceRecord>>();

  @override
  Stream<List<AttendanceRecord>> streamHistory(String storeId,
          String employeeId, {int limit = 30}) =>
      history.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStoreService implements StoreService {
  @override
  Future<Store?> getStore(String storeId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

LateExcuseRequest _request(DateTime date, LateExcuseStatus status) =>
    LateExcuseRequest(
      id: 'r-${date.day}-${status.name}',
      storeId: 's1',
      employeeId: 'e1',
      employeeName: 'Dara',
      date: date,
      reason: 'Traffic',
      status: status,
    );

AttendanceRecord _checkIn(DateTime day, {int lateMinutes = 0}) =>
    AttendanceRecord(
      id: 'a-${day.day}',
      storeId: 's1',
      employeeId: 'e1',
      employeeName: 'Dara',
      date: Timestamp.fromDate(day.add(const Duration(hours: 8))),
      status: lateMinutes > 0 ? AttendanceStatus.late : AttendanceStatus.present,
      lateMinutes: lateMinutes,
    );

void main() {
  late FakeLateExcuseService excuseService;
  late FakeAttendanceService attendanceService;
  late LateExcuseViewModel viewModel;

  setUp(() {
    excuseService = FakeLateExcuseService();
    attendanceService = FakeAttendanceService();
    viewModel = LateExcuseViewModel(
      storeId: 's1',
      employeeId: 'e1',
      employeeName: 'Dara',
      lateExcuseService: excuseService,
      attendanceService: attendanceService,
      storeService: FakeStoreService(),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> emit({
    List<LateExcuseRequest> requests = const [],
    List<AttendanceRecord> history = const [],
  }) async {
    excuseService.requests.add(requests);
    attendanceService.history.add(history);
    await Future<void>.delayed(Duration.zero);
  }

  group('isUpcomingDaySelectable', () {
    test('allows today and future days within the window', () async {
      await emit();
      final today = _today();
      expect(viewModel.isUpcomingDaySelectable(today), isTrue);
      expect(viewModel.isUpcomingDaySelectable(today.add(const Duration(days: 1))),
          isTrue);
      expect(
          viewModel.isUpcomingDaySelectable(today.add(
              const Duration(days: LateExcuseViewModel.upcomingWindowDays))),
          isTrue);
    });

    test('rejects past days and days beyond the window', () async {
      await emit();
      final today = _today();
      expect(
          viewModel.isUpcomingDaySelectable(
              today.subtract(const Duration(days: 1))),
          isFalse);
      expect(
          viewModel.isUpcomingDaySelectable(today.add(
              const Duration(days: LateExcuseViewModel.upcomingWindowDays + 1))),
          isFalse);
    });

    test('rejects days with a pending or approved request, not rejected ones',
        () async {
      final tomorrow = _today().add(const Duration(days: 1));
      final dayAfter = _today().add(const Duration(days: 2));
      final third = _today().add(const Duration(days: 3));
      await emit(requests: [
        _request(tomorrow, LateExcuseStatus.pending),
        _request(dayAfter, LateExcuseStatus.approved),
        _request(third, LateExcuseStatus.rejected),
      ]);
      expect(viewModel.isUpcomingDaySelectable(tomorrow), isFalse);
      expect(viewModel.isUpcomingDaySelectable(dayAfter), isFalse);
      expect(viewModel.isUpcomingDaySelectable(third), isTrue);
    });

    test('rejects today once the employee has checked in', () async {
      await emit(history: [_checkIn(_today())]);
      expect(viewModel.isUpcomingDaySelectable(_today()), isFalse);
    });
  });

  test('submitUpcomingRequest saves a pending request with no attendance',
      () async {
    await emit();
    final tomorrow = _today().add(const Duration(days: 1));

    await viewModel.submitUpcomingRequest(day: tomorrow, reason: ' Doctor ');

    final saved = excuseService.submitted.single;
    expect(saved.status, LateExcuseStatus.pending);
    expect(saved.attendanceId, isNull);
    expect(saved.lateMinutes, isNull);
    expect(saved.reason, 'Doctor');
    expect(saved.date.toUtc(),
        DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day));
  });

  test('submitUpcomingRequest refuses a past day', () async {
    await emit();
    expect(
      () => viewModel.submitUpcomingRequest(
          day: _today().subtract(const Duration(days: 1)), reason: 'x'),
      throwsException,
    );
    expect(excuseService.submitted, isEmpty);
  });

  test('submitRequest still excuses a past late check-in', () async {
    final yesterday = _today().subtract(const Duration(days: 1));
    await emit(history: [_checkIn(yesterday, lateMinutes: 12)]);

    final record = viewModel.excusableLateDays.single;
    await viewModel.submitRequest(record: record, reason: 'Flat tyre');

    final saved = excuseService.submitted.single;
    expect(saved.attendanceId, record.id);
    expect(saved.lateMinutes, 12);
  });
}
