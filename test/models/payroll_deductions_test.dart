import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_settings.dart';
import 'package:kottra_app/models/payroll_deductions.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

AttendanceRecord _rec({
  required int day,
  required AttendanceStatus status,
  int lateMinutes = 0,
  LeaveType? leaveType,
  int year = 2026,
  int month = 8,
}) {
  return AttendanceRecord(
    id: 'r$day',
    storeId: 's',
    employeeId: 'e',
    employeeName: 'Emp',
    date: Timestamp.fromDate(DateTime(year, month, day)),
    status: status,
    lateMinutes: lateMinutes,
    leaveType: leaveType,
  );
}

HrSettings _settings({
  PayrollFrequency frequency = PayrollFrequency.semiMonthly,
  LateDeductionSettings? late,
  AbsenceDeductionSettings? absence,
  DeductionPeriodBasis basis = DeductionPeriodBasis.payrollFrequency,
}) {
  return HrSettings(
    payrollFrequency: frequency,
    lateDeduction: late ?? LateDeductionSettings.disabled,
    absenceDeduction: absence ?? AbsenceDeductionSettings.legacyDefault,
    allowDisplayPreviewDeduction: true,
    deductionPeriodBasis: basis,
    attendanceMethod: AttendanceMethod.button,
  );
}

const _semiFirstHalfDay = 10; // ≤ 15 → first half
final _augFirstHalf = DateTime(2026, 8, _semiFirstHalfDay);

void main() {
  group('PayPeriod.forDate', () {
    test('monthly → full month, 28-day divisor, factor 1', () {
      final p = PayPeriod.forDate(PayrollFrequency.monthly, _augFirstHalf);
      expect(p.startDay, 1);
      expect(p.endDay, 31);
      expect(p.standardWorkDays, 28);
      expect(p.factor, 1.0);
    });

    test('semi-monthly first half → days 1–15, 14-day divisor, factor 0.5', () {
      final p = PayPeriod.forDate(PayrollFrequency.semiMonthly, _augFirstHalf);
      expect(p.isFirstHalf, isTrue);
      expect(p.startDay, 1);
      expect(p.endDay, 15);
      expect(p.standardWorkDays, 14);
      expect(p.factor, 0.5);
    });

    test('semi-monthly second half → day 16 to month end', () {
      final p = PayPeriod.forDate(
          PayrollFrequency.semiMonthly, DateTime(2026, 8, 20));
      expect(p.isFirstHalf, isFalse);
      expect(p.startDay, 16);
      expect(p.endDay, 31);
    });
  });

  group('late deduction (proportional)', () {
    test('divides by the fixed 14-day half, not attended days', () {
      // The Seav Ling case: 36 late min, $400/mo, semi-monthly. Fixed divisor
      // gives 36 × (200 ÷ 14 ÷ 480) ≈ $1.07 — not the $15 that dividing by a
      // single attended day produced before the fix.
      final b = computePeriodDeductions(
        records: [
          _rec(day: 10, status: AttendanceStatus.late, lateMinutes: 36),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          late: const LateDeductionSettings(
            enabled: true,
            mode: LateDeductionMode.proportional,
            workdayMinutes: 480,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.late, closeTo(1.07, 0.001));
      expect(b.lateMinutes, 36);
    });

    test('is 0 when the feature is disabled', () {
      final b = computePeriodDeductions(
        records: [
          _rec(day: 10, status: AttendanceStatus.late, lateMinutes: 36),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(late: LateDeductionSettings.disabled),
        today: _augFirstHalf,
      );
      expect(b.late, 0);
    });
  });

  group('late deduction (per-day / per-minute)', () {
    test('per-day charges a flat rate per late day', () {
      final b = computePeriodDeductions(
        records: [
          _rec(day: 3, status: AttendanceStatus.late, lateMinutes: 36),
          _rec(day: 8, status: AttendanceStatus.late, lateMinutes: 12),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          late: const LateDeductionSettings(
            enabled: true,
            mode: LateDeductionMode.perDay,
            perDayUsd: 5,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.lateDays, 2);
      expect(b.late, 10);
    });

    test('per-minute charges a flat rate per late minute', () {
      final b = computePeriodDeductions(
        records: [
          _rec(day: 5, status: AttendanceStatus.late, lateMinutes: 30),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          late: const LateDeductionSettings(
            enabled: true,
            mode: LateDeductionMode.perMinute,
            perMinuteUsd: 0.1,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.late, closeTo(3.0, 0.001));
    });
  });

  group('absence deduction (free-day scaling)', () {
    test('scales the monthly free-day allowance to a semi-monthly half', () {
      // 2 free days/month → 1 per half. Two unpaid days in the half → only 1
      // chargeable: 200 ÷ 14 ≈ $14.29.
      final b = computePeriodDeductions(
        records: [
          _rec(day: 4, status: AttendanceStatus.absent),
          _rec(day: 9, status: AttendanceStatus.absent),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          absence: const AbsenceDeductionSettings(
            enabled: true,
            mode: AbsenceDeductionMode.proportional,
            freeDaysPerMonth: 2,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.unpaidDays, 2);
      expect(b.absence, closeTo(14.29, 0.01));
    });

    test('full-month run forgives the whole monthly allowance', () {
      final b = computePeriodDeductions(
        records: [
          _rec(day: 4, status: AttendanceStatus.absent),
          _rec(day: 20, status: AttendanceStatus.absent),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          frequency: PayrollFrequency.monthly,
          absence: const AbsenceDeductionSettings(
            enabled: true,
            mode: AbsenceDeductionMode.proportional,
            freeDaysPerMonth: 2,
          ),
        ),
        today: DateTime(2026, 8, 25),
      );
      expect(b.unpaidDays, 2);
      expect(b.absence, 0);
    });

    test('unpaid leave counts as an unpaid day; paid leave does not', () {
      final b = computePeriodDeductions(
        records: [
          _rec(
            day: 4,
            status: AttendanceStatus.leave,
            leaveType: LeaveType.unpaidLeave,
          ),
          _rec(
            day: 9,
            status: AttendanceStatus.leave,
            leaveType: LeaveType.paidLeave,
          ),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          absence: const AbsenceDeductionSettings(
            enabled: true,
            mode: AbsenceDeductionMode.proportional,
            freeDaysPerMonth: 0,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.unpaidDays, 1);
      expect(b.absence, closeTo(14.29, 0.01));
    });
  });

  group('period filtering', () {
    test('ignores records outside the current half', () {
      final b = computePeriodDeductions(
        records: [
          _rec(day: 10, status: AttendanceStatus.late, lateMinutes: 30),
          // Second-half record must be excluded from a first-half period.
          _rec(day: 20, status: AttendanceStatus.late, lateMinutes: 60),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          late: const LateDeductionSettings(
            enabled: true,
            mode: LateDeductionMode.perMinute,
            perMinuteUsd: 0.1,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.lateMinutes, 30);
      expect(b.late, closeTo(3.0, 0.001));
    });

    test('holidays and days off never count as unpaid', () {
      final b = computePeriodDeductions(
        records: [
          _rec(day: 4, status: AttendanceStatus.holiday),
          _rec(day: 5, status: AttendanceStatus.dayOff),
        ],
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          absence: const AbsenceDeductionSettings(
            enabled: true,
            mode: AbsenceDeductionMode.proportional,
            freeDaysPerMonth: 0,
          ),
        ),
        today: _augFirstHalf,
      );
      expect(b.unpaidDays, 0);
      expect(b.absence, 0);
    });
  });

  group('end-of-month basis', () {
    const absenceProportional = AbsenceDeductionSettings(
      enabled: true,
      mode: AbsenceDeductionMode.proportional,
      freeDaysPerMonth: 0,
    );

    test('accumulates the whole month even in the first half', () {
      // Semi-monthly, today in the first half, one absent day in each half.
      // Payroll-frequency basis would only see the first-half day; end-of-month
      // sees both, over the full-month 28-day divisor.
      final records = [
        _rec(day: 5, status: AttendanceStatus.absent),
        _rec(day: 20, status: AttendanceStatus.absent),
      ];

      final perPeriod = computePeriodDeductions(
        records: records,
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(absence: absenceProportional),
        today: _augFirstHalf,
      );
      expect(perPeriod.unpaidDays, 1); // only day 5
      expect(perPeriod.absence, closeTo(14.29, 0.01)); // 200 ÷ 14

      final endOfMonth = computePeriodDeductions(
        records: records,
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          absence: absenceProportional,
          basis: DeductionPeriodBasis.endOfMonth,
        ),
        today: _augFirstHalf,
      );
      expect(endOfMonth.unpaidDays, 2); // both days
      expect(endOfMonth.absence, closeTo(28.57, 0.01)); // 2 × (400 ÷ 28)
      expect(endOfMonth.period.frequency, PayrollFrequency.monthly);
    });

    test('late minutes accumulate across both halves', () {
      final records = [
        _rec(day: 10, status: AttendanceStatus.late, lateMinutes: 36),
        _rec(day: 20, status: AttendanceStatus.late, lateMinutes: 24),
      ];
      final b = computePeriodDeductions(
        records: records,
        monthlyBasicSalary: 400,
        currency: SalaryCurrency.usd,
        settings: _settings(
          late: const LateDeductionSettings(
            enabled: true,
            mode: LateDeductionMode.proportional,
            workdayMinutes: 480,
          ),
          basis: DeductionPeriodBasis.endOfMonth,
        ),
        today: _augFirstHalf,
      );
      expect(b.lateMinutes, 60); // 36 + 24
      expect(b.late, closeTo(1.79, 0.01)); // 60 × (400 ÷ 28 ÷ 480)
    });
  });
}
