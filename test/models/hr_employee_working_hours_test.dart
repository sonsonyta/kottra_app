import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/hr_employee.dart';

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
}
