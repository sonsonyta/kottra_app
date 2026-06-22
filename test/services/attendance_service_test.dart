import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/services/attendance_service.dart';

class _CallRecorder {
  String? lastName;
  Map<String, dynamic>? lastParams;
  int calls = 0;

  HttpsCallableInvoker capture(Object? response) {
    return (name, params) async {
      calls++;
      lastName = name;
      lastParams = params;
      return response;
    };
  }
}

void main() {
  group('CheckInResult.fromMap', () {
    test('parses all fields from a successful response', () {
      final result = CheckInResult.fromMap(<Object?, Object?>{
        'success': true,
        'alreadyCheckedIn': false,
        'attendanceId': 'att-123',
        'status': 'Late',
      });

      expect(result.success, isTrue);
      expect(result.alreadyCheckedIn, isFalse);
      expect(result.attendanceId, 'att-123');
      expect(result.status, AttendanceStatus.late);
    });

    test('falls back to safe defaults for missing fields', () {
      final result = CheckInResult.fromMap(const <Object?, Object?>{});

      expect(result.success, isFalse);
      expect(result.alreadyCheckedIn, isFalse);
      expect(result.attendanceId, '');
      expect(result.status, AttendanceStatus.absent);
    });

    test('parses an alreadyCheckedIn response', () {
      final result = CheckInResult.fromMap(<Object?, Object?>{
        'success': true,
        'alreadyCheckedIn': true,
        'attendanceId': 'att-existing',
        'status': 'Present',
      });

      expect(result.alreadyCheckedIn, isTrue);
      expect(result.status, AttendanceStatus.present);
    });
  });

  group('AttendanceService.checkIn', () {
    test('invokes employeeCheckIn with storeId and employeeId only when '
        'no coords are provided', () async {
      final recorder = _CallRecorder();
      final service = AttendanceService(
        callable: recorder.capture(<Object?, Object?>{
          'success': true,
          'alreadyCheckedIn': false,
          'attendanceId': 'att-1',
          'status': 'Present',
        }),
      );

      final result = await service.checkIn(
        storeId: 'store-1',
        employeeId: 'emp-1',
      );

      expect(recorder.calls, 1);
      expect(recorder.lastName, 'employeeCheckInV1');
      expect(recorder.lastParams, {
        'storeId': 'store-1',
        'employeeId': 'emp-1',
      });
      expect(result.success, isTrue);
      expect(result.attendanceId, 'att-1');
      expect(result.status, AttendanceStatus.present);
    });

    test('forwards coordinates when provided', () async {
      final recorder = _CallRecorder();
      final service = AttendanceService(
        callable: recorder.capture(<Object?, Object?>{
          'success': true,
          'alreadyCheckedIn': false,
          'attendanceId': 'att-2',
          'status': 'Late',
        }),
      );

      await service.checkIn(
        storeId: 'store-1',
        employeeId: 'emp-1',
        latitude: 11.5564,
        longitude: 104.9282,
      );

      expect(recorder.lastParams, {
        'storeId': 'store-1',
        'employeeId': 'emp-1',
        'latitude': 11.5564,
        'longitude': 104.9282,
      });
    });

    test('omits a coordinate that is null while keeping the other', () async {
      final recorder = _CallRecorder();
      final service = AttendanceService(
        callable: recorder.capture(<Object?, Object?>{
          'success': true,
          'alreadyCheckedIn': false,
          'attendanceId': 'att-3',
          'status': 'Present',
        }),
      );

      await service.checkIn(
        storeId: 'store-1',
        employeeId: 'emp-1',
        latitude: 11.5564,
      );

      expect(recorder.lastParams, {
        'storeId': 'store-1',
        'employeeId': 'emp-1',
        'latitude': 11.5564,
      });
      expect(recorder.lastParams!.containsKey('longitude'), isFalse);
    });

    test('returns alreadyCheckedIn result without throwing', () async {
      final service = AttendanceService(
        callable: (_, _) async => <Object?, Object?>{
          'success': true,
          'alreadyCheckedIn': true,
          'attendanceId': 'att-existing',
          'status': 'Present',
        },
      );

      final result = await service.checkIn(
        storeId: 'store-1',
        employeeId: 'emp-1',
      );

      expect(result.alreadyCheckedIn, isTrue);
      expect(result.attendanceId, 'att-existing');
    });

    test('throws FormatException when payload is not a map', () async {
      final service = AttendanceService(
        callable: (_, _) async => 'unexpected-string',
      );

      await expectLater(
        service.checkIn(storeId: 'store-1', employeeId: 'emp-1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('propagates errors from the callable', () async {
      final service = AttendanceService(
        callable: (_, _) async => throw StateError('boom'),
      );

      await expectLater(
        service.checkIn(storeId: 'store-1', employeeId: 'emp-1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AttendanceService.checkOut', () {
    test('invokes employeeCheckOut with the required fields only when no coords '
        'are provided', () async {
      final recorder = _CallRecorder();
      final service = AttendanceService(
        callable: recorder.capture(<Object?, Object?>{'success': true}),
      );

      await service.checkOut(
        storeId: 'store-1',
        attendanceId: 'att-1',
        employeeId: 'emp-1',
      );

      expect(recorder.calls, 1);
      expect(recorder.lastName, 'employeeCheckOutV1');
      expect(recorder.lastParams, {
        'storeId': 'store-1',
        'attendanceId': 'att-1',
        'employeeId': 'emp-1',
      });
    });

    test('forwards coordinates when provided', () async {
      final recorder = _CallRecorder();
      final service = AttendanceService(
        callable: recorder.capture(<Object?, Object?>{'success': true}),
      );

      await service.checkOut(
        storeId: 'store-1',
        attendanceId: 'att-2',
        employeeId: 'emp-1',
        latitude: 11.5564,
        longitude: 104.9282,
      );

      expect(recorder.lastParams, {
        'storeId': 'store-1',
        'attendanceId': 'att-2',
        'employeeId': 'emp-1',
        'latitude': 11.5564,
        'longitude': 104.9282,
      });
    });
  });
}
