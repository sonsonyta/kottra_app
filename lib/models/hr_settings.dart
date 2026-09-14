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

/// How the late/absence deduction period is derived.
///  - `payrollFrequency` (default): deduct per pay period.
///  - `endOfMonth`: accumulate the whole month; the preview shows the running
///    full-month total (28-day divisor, full free-day allowance).
enum DeductionPeriodBasis {
  payrollFrequency('payrollFrequency'),
  endOfMonth('endOfMonth');

  const DeductionPeriodBasis(this.value);
  final String value;

  static DeductionPeriodBasis fromString(String? value) =>
      DeductionPeriodBasis.values.firstWhere((b) => b.value == value,
          orElse: () => DeductionPeriodBasis.payrollFrequency);
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

/// How employees record attendance.
///  - `button` (default): tap the check-in/out button directly.
///  - `qr`: scan the store's posted QR code to check in/out. The scanned store
///    id must match the employee's own store before the check-in proceeds.
enum AttendanceMethod {
  button('button'),
  qr('qr');

  const AttendanceMethod(this.value);
  final String value;

  static AttendanceMethod fromString(String? value) => AttendanceMethod.values
      .firstWhere((m) => m.value == value, orElse: () => AttendanceMethod.button);
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
    required this.allowDisplayPreviewDeduction,
    required this.deductionPeriodBasis,
    required this.attendanceMethod,
    required this.requirePhotoOnAttendance,
  });

  final PayrollFrequency payrollFrequency;
  final LateDeductionSettings lateDeduction;
  final AbsenceDeductionSettings absenceDeduction;

  /// How employees check in/out for this store (button vs QR scan).
  final AttendanceMethod attendanceMethod;

  /// Whether the employee must attach a photo (taken with the camera) when
  /// checking in and out. Defaults to false when the store hasn't set it.
  final bool requirePhotoOnAttendance;

  /// Whether employees may see their live deduction preview. Defaults to true
  /// (visible) when the store hasn't set it.
  final bool allowDisplayPreviewDeduction;

  /// How the deduction period is derived (see [DeductionPeriodBasis]).
  final DeductionPeriodBasis deductionPeriodBasis;

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
      allowDisplayPreviewDeduction:
          hrMap['allowDisplayPreviewDeduction'] as bool? ?? true,
      deductionPeriodBasis: DeductionPeriodBasis.fromString(
          hrMap['deductionPeriodBasis'] as String?),
      attendanceMethod:
          AttendanceMethod.fromString(hrMap['attendanceMethod'] as String?),
      requirePhotoOnAttendance:
          hrMap['requirePhotoOnAttendance'] as bool? ?? false,
    );
  }

  static const defaults = HrSettings(
    payrollFrequency: PayrollFrequency.monthly,
    lateDeduction: LateDeductionSettings.disabled,
    absenceDeduction: AbsenceDeductionSettings.legacyDefault,
    allowDisplayPreviewDeduction: true,
    deductionPeriodBasis: DeductionPeriodBasis.payrollFrequency,
    attendanceMethod: AttendanceMethod.button,
    requirePhotoOnAttendance: false,
  );
}
