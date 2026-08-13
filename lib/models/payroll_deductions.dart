import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_settings.dart';

/// Pure payroll-deduction logic, ported from the POS `HrPayrollComponent`
/// (`computeLateDeduction` / `computeAbsenceDeduction`). Kept framework-free so
/// it can be unit-tested and reused, and so the live figure the employee sees
/// matches the amount the POS will actually post on the payslip.
///
/// Parity notes with the POS generator:
/// - The proportional daily rate divides by a **fixed** standard-work-days
///   count (28 for a full month, 14 for a semi-monthly half), never by the days
///   actually attended, so a period spent mostly on leave can't inflate the
///   daily rate.
/// - Per-period base salary is the monthly salary scaled by the period factor
///   (×0.5 for a semi-monthly half), giving a stable daily rate of
///   ≈ monthly salary ÷ 28 in every period type.
/// - The monthly free-absence-day allowance is scaled by the same factor so it
///   isn't forgiven in full on each of the two semi-monthly runs.

double _round2(double v) => (v * 100).roundToDouble() / 100;

/// The pay period that [date] falls in, given the store's payroll frequency.
class PayPeriod {
  const PayPeriod._({
    required this.year,
    required this.month,
    required this.startDay,
    required this.endDay,
    required this.standardWorkDays,
    required this.factor,
    required this.frequency,
    required this.isFirstHalf,
  });

  /// 1-based calendar month the period sits in.
  final int year;
  final int month;
  final int startDay;
  final int endDay;

  /// Fixed divisor for proportional daily-rate deductions.
  final int standardWorkDays;

  /// Salary scaling for the period (1 for a month, 0.5 for a half).
  final double factor;

  final PayrollFrequency frequency;
  final bool isFirstHalf;

  factory PayPeriod.forDate(PayrollFrequency frequency, DateTime date) {
    final year = date.year;
    final month = date.month;
    final lastDay = DateTime(year, month + 1, 0).day;

    if (frequency == PayrollFrequency.monthly) {
      return PayPeriod._(
        year: year,
        month: month,
        startDay: 1,
        endDay: lastDay,
        standardWorkDays: 28,
        factor: 1.0,
        frequency: frequency,
        isFirstHalf: false,
      );
    }

    final firstHalf = date.day <= 15;
    return PayPeriod._(
      year: year,
      month: month,
      startDay: firstHalf ? 1 : 16,
      endDay: firstHalf ? 15 : lastDay,
      standardWorkDays: 14,
      factor: 0.5,
      frequency: frequency,
      isFirstHalf: firstHalf,
    );
  }

  /// Whether an attendance record dated [date] belongs to this period.
  bool contains(DateTime date) =>
      date.year == year &&
      date.month == month &&
      date.day >= startDay &&
      date.day <= endDay;
}

/// A breakdown of an employee's accrued deductions for a pay period.
class DeductionBreakdown {
  const DeductionBreakdown({
    required this.late,
    required this.absence,
    required this.lateMinutes,
    required this.lateDays,
    required this.unpaidDays,
    required this.currency,
    required this.period,
  });

  final double late;
  final double absence;
  final int lateMinutes;
  final int lateDays;
  final int unpaidDays;
  final SalaryCurrency currency;
  final PayPeriod period;

  double get total => _round2(late + absence);
  bool get hasDeductions => total > 0;

  static DeductionBreakdown empty(SalaryCurrency currency, PayPeriod period) =>
      DeductionBreakdown(
        late: 0,
        absence: 0,
        lateMinutes: 0,
        lateDays: 0,
        unpaidDays: 0,
        currency: currency,
        period: period,
      );
}

/// Computes the employee's accrued late + absence deductions for the pay period
/// containing [today], from their attendance [records] and the store settings.
///
/// [records] may span more than the period (e.g. the streamed 90-day history);
/// only records inside the period are considered.
///
/// [today] must already be expressed in the store's timezone. [toStoreZone]
/// converts a record's stored date into that same zone so day-of-month
/// comparisons line up regardless of the device timezone; it defaults to the
/// identity function (fine for tests that use plain local dates).
DeductionBreakdown computePeriodDeductions({
  required List<AttendanceRecord> records,
  required double monthlyBasicSalary,
  required SalaryCurrency currency,
  required HrSettings settings,
  required DateTime today,
  DateTime Function(DateTime date)? toStoreZone,
}) {
  final zone = toStoreZone ?? (d) => d;
  // 'endOfMonth' basis accumulates the whole month regardless of payroll
  // frequency, so the preview shows the running full-month total (28-day
  // divisor, full free-day allowance) that will be deducted at month end.
  final effectiveFrequency =
      settings.deductionPeriodBasis == DeductionPeriodBasis.endOfMonth
          ? PayrollFrequency.monthly
          : settings.payrollFrequency;
  final period = PayPeriod.forDate(effectiveFrequency, today);
  final periodBasic = monthlyBasicSalary * period.factor;

  final inPeriod =
      records.where((r) => period.contains(zone(r.date.toDate()))).toList();

  var unpaidDays = 0;
  var totalLateMinutes = 0;
  var lateDays = 0;
  for (final r in inPeriod) {
    if (r.status == AttendanceStatus.holiday ||
        r.status == AttendanceStatus.dayOff) {
      continue;
    }

    final isAbsent = r.status == AttendanceStatus.absent;
    final isUnpaidLeave = r.status == AttendanceStatus.leave &&
        r.leaveType == LeaveType.unpaidLeave;
    if (isAbsent || isUnpaidLeave) unpaidDays++;

    if (r.lateMinutes > 0) {
      totalLateMinutes += r.lateMinutes;
      lateDays++;
    }
  }

  final late = _computeLate(
    currency: currency,
    periodBasic: periodBasic,
    standardWorkDays: period.standardWorkDays,
    totalLateMinutes: totalLateMinutes,
    lateDays: lateDays,
    settings: settings.lateDeduction,
  );
  final absence = _computeAbsence(
    currency: currency,
    periodBasic: periodBasic,
    standardWorkDays: period.standardWorkDays,
    periodFactor: period.factor,
    unpaidDays: unpaidDays,
    settings: settings.absenceDeduction,
  );

  return DeductionBreakdown(
    late: late,
    absence: absence,
    lateMinutes: totalLateMinutes,
    lateDays: lateDays,
    unpaidDays: unpaidDays,
    currency: currency,
    period: period,
  );
}

double _computeLate({
  required SalaryCurrency currency,
  required double periodBasic,
  required int standardWorkDays,
  required int totalLateMinutes,
  required int lateDays,
  required LateDeductionSettings settings,
}) {
  if (!settings.enabled || totalLateMinutes <= 0) return 0;
  final isUsd = currency == SalaryCurrency.usd;

  double amount;
  switch (settings.mode) {
    case LateDeductionMode.perMinute:
      final rate =
          ((isUsd ? settings.perMinuteUsd : settings.perMinuteKhr) ?? 0).toDouble();
      amount = totalLateMinutes * rate;
      break;
    case LateDeductionMode.perDay:
      final rate =
          ((isUsd ? settings.perDayUsd : settings.perDayKhr) ?? 0).toDouble();
      amount = lateDays * rate;
      break;
    case LateDeductionMode.proportional:
      final workdayMinutes = settings.workdayMinutes ?? 480;
      final dailyRate =
          standardWorkDays > 0 ? periodBasic / standardWorkDays : 0.0;
      final perMinutePay =
          workdayMinutes > 0 ? dailyRate / workdayMinutes : 0.0;
      amount = totalLateMinutes * perMinutePay;
      break;
  }
  return _round2(amount);
}

double _computeAbsence({
  required SalaryCurrency currency,
  required double periodBasic,
  required int standardWorkDays,
  required double periodFactor,
  required int unpaidDays,
  required AbsenceDeductionSettings settings,
}) {
  if (!settings.enabled || unpaidDays <= 0) return 0;

  final freeDays = (settings.freeDaysPerMonth ?? 0) * periodFactor;
  final chargeableDays = unpaidDays - freeDays;
  if (chargeableDays <= 0) return 0;

  double amount;
  if (settings.mode == AbsenceDeductionMode.fixed) {
    final isUsd = currency == SalaryCurrency.usd;
    final rate =
        ((isUsd ? settings.perDayUsd : settings.perDayKhr) ?? 0).toDouble();
    amount = chargeableDays * rate;
  } else {
    final dailyRate =
        standardWorkDays > 0 ? periodBasic / standardWorkDays : 0.0;
    amount = chargeableDays * dailyRate;
  }
  return _round2(amount);
}
