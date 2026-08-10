/// Store-level HR configuration, read from Firestore `settings/{storeId}` under
/// the `hrSettings` key. Mirrors the shapes the POS admin app writes there
/// (`HRSettings`, `HRLateDeductionSettings`, `HRAbsenceDeductionSettings`) so
/// the employee app can compute the same payroll deductions the POS does.
library;

/// How often payroll runs. `monthly` = one run/month paying the full salary;
/// `semiMonthly` = two runs/month (1st–15th and 16th–end), each paying half.
enum PayrollFrequency {
  monthly('monthly'),
  semiMonthly('semiMonthly');

  const PayrollFrequency(this.value);
  final String value;

  static PayrollFrequency fromString(String? value) => PayrollFrequency.values
      .firstWhere((f) => f.value == value, orElse: () => PayrollFrequency.monthly);
}

/// Late-arrival deduction mode.
enum LateDeductionMode {
  perMinute('perMinute'),
  perDay('perDay'),
  proportional('proportional');

  const LateDeductionMode(this.value);
  final String value;

  static LateDeductionMode fromString(String? value) => LateDeductionMode.values
      .firstWhere((m) => m.value == value,
          orElse: () => LateDeductionMode.perMinute);
}

/// Absence deduction mode.
enum AbsenceDeductionMode {
  proportional('proportional'),
  fixed('fixed');

  const AbsenceDeductionMode(this.value);
  final String value;

  static AbsenceDeductionMode fromString(String? value) =>
      AbsenceDeductionMode.values.firstWhere((m) => m.value == value,
          orElse: () => AbsenceDeductionMode.proportional);
}

class LateDeductionSettings {
  const LateDeductionSettings({
    required this.enabled,
    required this.mode,
    this.perMinuteUsd,
    this.perMinuteKhr,
    this.perDayUsd,
    this.perDayKhr,
    this.workdayMinutes,
  });

  final bool enabled;
  final LateDeductionMode mode;
  final double? perMinuteUsd;
  final double? perMinuteKhr;
  final double? perDayUsd;
  final double? perDayKhr;
  final int? workdayMinutes;

  factory LateDeductionSettings.fromMap(Map<String, dynamic> map) {
    return LateDeductionSettings(
      enabled: map['enabled'] == true,
      mode: LateDeductionMode.fromString(map['mode'] as String?),
      perMinuteUsd: (map['perMinuteUSD'] as num?)?.toDouble(),
      perMinuteKhr: (map['perMinuteKHR'] as num?)?.toDouble(),
      perDayUsd: (map['perDayUSD'] as num?)?.toDouble(),
      perDayKhr: (map['perDayKHR'] as num?)?.toDouble(),
      workdayMinutes: (map['workdayMinutes'] as num?)?.toInt(),
    );
  }

  /// Feature-off default: matches the POS `defaultLateDeduction`.
  static const disabled = LateDeductionSettings(
    enabled: false,
    mode: LateDeductionMode.perMinute,
    workdayMinutes: 480,
  );
}

class AbsenceDeductionSettings {
  const AbsenceDeductionSettings({
    required this.enabled,
    required this.mode,
    this.perDayUsd,
    this.perDayKhr,
    this.freeDaysPerMonth,
  });

  final bool enabled;
  final AbsenceDeductionMode mode;
  final double? perDayUsd;
  final double? perDayKhr;
  final int? freeDaysPerMonth;

  factory AbsenceDeductionSettings.fromMap(Map<String, dynamic> map) {
    return AbsenceDeductionSettings(
      enabled: map['enabled'] == true,
      mode: AbsenceDeductionMode.fromString(map['mode'] as String?),
      perDayUsd: (map['perDayUSD'] as num?)?.toDouble(),
      perDayKhr: (map['perDayKHR'] as num?)?.toDouble(),
      freeDaysPerMonth: (map['freeDaysPerMonth'] as num?)?.toInt(),
    );
  }

  /// Unconfigured default mirrors the POS legacy behaviour: enabled,
  /// proportional to the daily salary, with no free days.
  static const legacyDefault = AbsenceDeductionSettings(
    enabled: true,
    mode: AbsenceDeductionMode.proportional,
    freeDaysPerMonth: 0,
  );
}

class HrSettings {
  const HrSettings({
    required this.payrollFrequency,
    required this.lateDeduction,
    required this.absenceDeduction,
  });

  final PayrollFrequency payrollFrequency;
  final LateDeductionSettings lateDeduction;
  final AbsenceDeductionSettings absenceDeduction;

  /// Parses the whole `settings/{storeId}` document. The HR config lives under
  /// the `hrSettings` key; a missing key falls back to sensible defaults.
  factory HrSettings.fromSettingsDoc(Map<String, dynamic> data) {
    final hr = data['hrSettings'];
    if (hr is! Map) return HrSettings.defaults;
    final hrMap = hr.cast<String, dynamic>();

    final late = hrMap['lateDeduction'];
    final absence = hrMap['absenceDeduction'];

    return HrSettings(
      payrollFrequency:
          PayrollFrequency.fromString(hrMap['payrollFrequency'] as String?),
      lateDeduction: late is Map
          ? LateDeductionSettings.fromMap(late.cast<String, dynamic>())
          : LateDeductionSettings.disabled,
      absenceDeduction: absence is Map
          ? AbsenceDeductionSettings.fromMap(absence.cast<String, dynamic>())
          : AbsenceDeductionSettings.legacyDefault,
    );
  }

  static const defaults = HrSettings(
    payrollFrequency: PayrollFrequency.monthly,
    lateDeduction: LateDeductionSettings.disabled,
    absenceDeduction: AbsenceDeductionSettings.legacyDefault,
  );
}
