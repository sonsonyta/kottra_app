import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Map<String, dynamic> _employeeMap({Object? weeklySchedule}) => {
      'storeId': 's1',
      'firstName': 'A',
      'lastName': 'B',
      'employeeCode': 'E1',
      'gender': 'Male',
      'phoneNumber': '012',
      'position': 'Staff',
      'employmentType': 'Full-time',
      'startWorkingTime': '08:00',
      'endWorkingTime': '17:00',
      'status': 'Active',
      'joinDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'basicSalary': 300,
      'currency': 'USD',
      'paymentMethod': 'Cash',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'weeklySchedule': ?weeklySchedule,
    };

void main() {
  // 2026-10-02 is a Friday, 2026-10-03 a Saturday, 2026-10-04 a Sunday.
  final friday = DateTime(2026, 10, 2);
  final saturday = DateTime(2026, 10, 3);
  final sunday = DateTime(2026, 10, 4);

  group('HREmployee.workingHoursOn', () {
    test('uses the Saturday override from the POS map', () {
      final emp = HREmployee.fromMap(
        'e1',
        _employeeMap(weeklySchedule: {
          '0': null,
          '6': {'start': '08:00', 'end': '12:00'},
        }),
      );
      expect(emp.workingHoursOn(saturday).end, '12:00');
      expect(emp.workingHoursOn(friday).end, '17:00');
      // A null entry (cleared override) means default hours.
      expect(emp.workingHoursOn(sunday).end, '17:00');
    });

    test('falls back field-by-field for a partial override', () {
      final emp = HREmployee.fromMap(
        'e1',
        _employeeMap(weeklySchedule: {
          '6': {'end': '12:00'},
        }),
      );
      final hours = emp.workingHoursOn(saturday);
      expect(hours.start, '08:00');
      expect(hours.end, '12:00');
    });

    test('old employees without weeklySchedule keep their default hours', () {
      final emp = HREmployee.fromMap('e1', _employeeMap());
      expect(emp.weeklySchedule, isEmpty);
      expect(emp.workingHoursOn(saturday).start, '08:00');
      expect(emp.workingHoursOn(saturday).end, '17:00');
      expect(emp.toMap().containsKey('weeklySchedule'), isFalse);
    });

    test('toMap round-trips the schedule so a full set keeps it', () {
      final emp = HREmployee.fromMap(
        'e1',
        _employeeMap(weeklySchedule: {
          '6': {'start': '08:00', 'end': '12:00'},
        }),
      );
      final again = HREmployee.fromMap('e1', emp.toMap());
      expect(again.workingHoursOn(saturday).end, '12:00');
    });
  });

  group('HREmployee.reminderHours', () {
    test('covers weekdays plus days the POS gave hours', () {
      final emp = HREmployee.fromMap(
        'e1',
        _employeeMap(weeklySchedule: {
          '6': {'start': '08:00', 'end': '12:00'},
        }),
      );
      final hours = emp.reminderHours;
      expect(hours.keys, [1, 2, 3, 4, 5, 6]);
      expect(hours[DateTime.saturday]!.end, '12:00');
      expect(hours[DateTime.monday]!.end, '17:00');
    });

    test('weekdays only without overrides', () {
      final emp = HREmployee.fromMap('e1', _employeeMap());
      expect(emp.reminderHours.keys, [1, 2, 3, 4, 5]);
    });
  });

  group('HREmployee.shiftWindowAt', () {
    late tz.Location pp;
    setUpAll(() {
      tzdata.initializeTimeZones();
      pp = tz.getLocation('Asia/Phnom_Penh');
    });

    tz.TZDateTime local(int month, int day, int hour, [int minute = 0]) =>
        tz.TZDateTime(pp, 2026, month, day, hour, minute);

    HREmployee withHours(String start, String end, {Object? weekly}) =>
        HREmployee.fromMap('e1', {
          ..._employeeMap(weeklySchedule: weekly),
          'startWorkingTime': start,
          'endWorkingTime': end,
        });

    test('a day shift stays on its own day', () {
      final w = withHours('08:00', '17:00').shiftWindowAt(local(11, 3, 9));
      expect(w.shiftDay, local(11, 3, 0));
      expect(w.scheduledStart, local(11, 3, 8));
      expect(w.scheduledEnd, local(11, 3, 17));
    });

    test('an overnight shift ends the next day', () {
      final w = withHours('18:00', '04:00').shiftWindowAt(local(11, 2, 17, 50));
      expect(w.shiftDay, local(11, 2, 0));
      expect(w.scheduledEnd, local(11, 3, 4));
    });

    test('the overnight tail belongs to the previous day\'s shift', () {
      final w = withHours('18:00', '04:00').shiftWindowAt(local(11, 3, 3));
      expect(w.shiftDay, local(11, 2, 0));
      expect(w.scheduledStart, local(11, 2, 18));
      expect(w.scheduledEnd, local(11, 3, 4));
    });

    test('after the overnight shift ends, the new day\'s shift applies', () {
      final w = withHours('18:00', '04:00').shiftWindowAt(local(11, 3, 4));
      expect(w.shiftDay, local(11, 3, 0));
    });

    test('uses the weekday the shift started on', () {
      // 2026-11-01 is a Sunday: overnight only on Sundays.
      final emp = withHours('08:00', '17:00', weekly: {
        '0': {'start': '20:00', 'end': '02:00'},
      });
      final mondayTail = emp.shiftWindowAt(local(11, 2, 1));
      expect(mondayTail.shiftDay, local(11, 1, 0));
      expect(mondayTail.start, '20:00');
      expect(emp.shiftWindowAt(local(11, 3, 1)).start, '08:00');
    });

    test('handles month boundaries', () {
      final w = withHours('18:00', '04:00').shiftWindowAt(local(12, 1, 2));
      expect(w.shiftDay, local(11, 30, 0));
    });
  });

  group('ShiftWindow.checkInAvailability', () {
    late tz.Location pp;
    setUpAll(() {
      tzdata.initializeTimeZones();
      pp = tz.getLocation('Asia/Phnom_Penh');
    });

    tz.TZDateTime local(int day, int hour, [int minute = 0]) =>
        tz.TZDateTime(pp, 2026, 11, day, hour, minute);

    CheckInAvailability at(String start, String end, tz.TZDateTime when,
        [int early = 60]) {
      final emp = HREmployee.fromMap('e1', {
        ..._employeeMap(),
        'startWorkingTime': start,
        'endWorkingTime': end,
      });
      return emp.shiftWindowAt(when).checkInAvailability(when, early);
    }

    test('opens earlyMinutes before the start and closes at the end', () {
      expect(at('08:00', '17:00', local(3, 6, 59)),
          CheckInAvailability.notYetOpen);
      expect(at('08:00', '17:00', local(3, 7)), CheckInAvailability.open);
      expect(at('08:00', '17:00', local(3, 16, 59)), CheckInAvailability.open);
      expect(at('08:00', '17:00', local(3, 17)),
          CheckInAvailability.shiftEnded);
    });

    test('allows the overnight tail and blocks after it ends', () {
      expect(at('18:00', '04:00', local(3, 3)), CheckInAvailability.open);
      expect(at('18:00', '04:00', local(3, 4, 30)),
          CheckInAvailability.notYetOpen);
    });
  });
}
