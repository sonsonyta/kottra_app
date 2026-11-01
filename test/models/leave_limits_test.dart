import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/leave_limits.dart';

AttendanceRecord _leave(int month, int day, [LeaveType? type]) =>
    AttendanceRecord(
      id: 'l$month-$day',
      storeId: 's',
      employeeId: 'e',
      employeeName: 'Emp',
      date: Timestamp.fromDate(DateTime(2026, month, day)),
      status: AttendanceStatus.leave,
      leaveType: type,
    );

void main() {
  test('parses limits, ignoring null and negative entries', () {
    expect(
      parseLeaveLimits({'Sick Leave': 7, 'Annual Leave': null, 'Other': -1}),
      {'Sick Leave': 7},
    );
  });

  test('an employee override wins over the store limit', () {
    expect(
      effectiveLeaveLimits({'Annual Leave': 18, 'Sick Leave': 7},
          {'Annual Leave': 24}),
      {'Annual Leave': 24, 'Sick Leave': 7},
    );
  });

  test('charges only the period days past the yearly limit', () {
    final over = countOverLimitLeaveDays(
      records: [
        _leave(2, 10, LeaveType.sickLeave),
        _leave(5, 11, LeaveType.sickLeave),
        _leave(10, 3, LeaveType.sickLeave),
        _leave(10, 4, LeaveType.sickLeave),
        _leave(10, 5, LeaveType.annualLeave),
      ],
      periodStart: DateTime(2026, 10, 1),
      periodEnd: DateTime(2026, 10, 31),
      limits: {'Sick Leave': 2},
    );
    expect(over, 2);
  });

  test('missing type counts as Other; already-unpaid types are skipped', () {
    final records = [_leave(10, 1), _leave(10, 2), _leave(10, 3)];
    expect(
      countOverLimitLeaveDays(
        records: records,
        periodStart: DateTime(2026, 10, 1),
        periodEnd: DateTime(2026, 10, 31),
        limits: {'Other': 1},
      ),
      2,
    );
    expect(
      countOverLimitLeaveDays(
        records: records,
        periodStart: DateTime(2026, 10, 1),
        periodEnd: DateTime(2026, 10, 31),
        limits: {'Other': 1},
        alreadyUnpaid: {'Other'},
      ),
      0,
    );
  });
}
