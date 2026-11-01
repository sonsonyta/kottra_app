import 'package:kottra_app/models/attendance_record.dart';

/// Yearly leave allowance per leave type, keyed by the stored type string
/// ('Sick Leave', 'Annual Leave', 'Other', …). A type without an entry has no
/// limit. Mirrors the POS `leave-limits.ts`: set store-wide in
/// `hrSettings.leaveLimits`, overridden per employee in
/// `hr_employees/{id}.leaveLimits` (null there = use the store limit).
/// Leave past the allowance is still allowed; payroll docks the extra days as
/// unpaid leave. Years are calendar years.
typedef LeaveLimits = Map<String, int>;

/// Parses a stored limits map, dropping null / negative / non-numeric entries.
LeaveLimits parseLeaveLimits(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, int>{};
  raw.forEach((key, value) {
    if (value is num && value >= 0) out[key.toString()] = value.floor();
  });
  return out;
}

/// The employee's limits: their override wins for each type it sets.
LeaveLimits effectiveLeaveLimits(LeaveLimits store, LeaveLimits employee) =>
    {...store, ...employee};

/// Leave days inside [periodStart]..[periodEnd] (store-local days) past the
/// yearly limit for their type, counting the year's earlier leave first.
/// Types in [alreadyUnpaid] are skipped — the leave policy docks them anyway.
/// [records] is the employee's leave for the whole year, de-duplicated.
int countOverLimitLeaveDays({
  required List<AttendanceRecord> records,
  required DateTime periodStart,
  required DateTime periodEnd,
  required LeaveLimits limits,
  Set<String> alreadyUnpaid = const {},
  DateTime Function(DateTime date)? toStoreZone,
}) {
  if (limits.isEmpty) return 0;
  final zone = toStoreZone ?? (d) => d;
  final start = DateTime(periodStart.year, periodStart.month, periodStart.day);
  final end = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
  var over = 0;
  for (final year in {periodStart.year, periodEnd.year}) {
    final days = records
        .where((r) => r.status == AttendanceStatus.leave)
        .map((r) => (record: r, day: zone(r.date.toDate())))
        .where((e) => e.day.year == year)
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final used = <String, int>{};
    for (final e in days) {
      final type = e.record.leaveType?.value ?? LeaveType.other.value;
      used[type] = (used[type] ?? 0) + 1;
      final limit = limits[type];
      final day = DateTime(e.day.year, e.day.month, e.day.day);
      if (limit != null &&
          used[type]! > limit &&
          !day.isBefore(start) &&
          !day.isAfter(end) &&
          !alreadyUnpaid.contains(type)) {
        over++;
      }
    }
  }
  return over;
}
