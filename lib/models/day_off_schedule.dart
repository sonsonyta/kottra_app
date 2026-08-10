import 'package:cloud_firestore/cloud_firestore.dart';

/// An employee's scheduled days off for a single month.
///
/// Mirrors the POS `HRDayOffSchedule` model. Stored one document per employee
/// per month at `stores/{storeId}/hr_day_off_schedules/{employeeId}_{yyyy-MM}`.
/// `days` holds the day-of-month numbers scheduled off, e.g. `[1, 8, 15, 22]`.
///
/// Read-only in the mobile app — the schedule is owned and edited by the POS.
class DayOffSchedule {
  const DayOffSchedule({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.days,
  });

  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;

  /// First day of the month this schedule covers, 00:00.
  final DateTime month;

  /// Day-of-month values scheduled off (1-based), sorted ascending.
  final List<int> days;

  bool isDayOff(int day) => days.contains(day);

  factory DayOffSchedule.fromMap(String id, Map<String, dynamic> map) {
    final rawDays = (map['days'] as List<dynamic>?) ?? const [];
    final days = rawDays.map((d) => (d as num).toInt()).toList()..sort();

    return DayOffSchedule(
      id: id,
      storeId: map['storeId'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      month: (map['month'] as Timestamp?)?.toDate() ?? DateTime.now(),
      days: days,
    );
  }
}
