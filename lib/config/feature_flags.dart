class FeatureFlags {
  /// Toggle this to enable or disable the Payroll feature across the app.
  static const bool enablePayroll = true;

  /// Toggle this to enable or disable the Leave Request feature across the app.
  static const bool enableLeaveRequest = true;

  /// Toggle this to enable or disable the Salary Advance request feature.
  static const bool enableSalaryAdvance = true;

  /// Toggle this to enable or disable the Schedule (days off & holidays) screen.
  static const bool enableSchedule = true;

  /// Master switch for QR-code attendance. When false, check-in/out is always
  /// the plain tap button regardless of the store's `attendanceMethod` setting.
  /// When true, the store's setting decides between the button and QR scanning.
  static const bool enableQrAttendance = true;
}
