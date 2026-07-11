// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get attendance => 'Attendance';

  @override
  String get payroll => 'Payroll';

  @override
  String get profile => 'Profile';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get position => 'Position';

  @override
  String get department => 'Department';

  @override
  String get logout => 'Logout';

  @override
  String get recentAttendance => 'Recent Attendance';

  @override
  String get viewAllAttendance => 'View all attendance';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String get checkedIn => 'Checked In';

  @override
  String get notCheckedIn => 'Not Checked In';

  @override
  String get checkedOut => 'Checked Out';

  @override
  String get onLeave => 'On Leave';

  @override
  String get present => 'Present';

  @override
  String get late => 'Late';

  @override
  String get absent => 'Absent';

  @override
  String get leave => 'Leave';

  @override
  String get dayOff => 'Day Off';

  @override
  String get onDayOffToday => 'You are scheduled off today.';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get requestLeave => 'Request Leave';

  @override
  String get myPayslips => 'My Payslips';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get noteRequired => 'Note (Required)';

  @override
  String get addNoteCheckInLate => 'Add a note if you are checking in late.';

  @override
  String get addNoteCheckOutEarly =>
      'Add a note if you are checking out early.';

  @override
  String get confirmLogoutTitle => 'Confirm Logout';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to logout?';

  @override
  String get yesLogout => 'Yes, Logout';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get noteOptional => 'Note (Optional)';

  @override
  String get alreadyCheckedIn => 'You\'re already checked in today.';

  @override
  String checkInSuccess(String status) {
    return 'Checked in — $status';
  }

  @override
  String get checkInFailed => 'Check-in failed. Please try again.';

  @override
  String get alreadyCheckedOut => 'You\'re already checked out today.';

  @override
  String get checkOutSuccess => 'Checked out successful';

  @override
  String get checkOutFailed => 'Check-out failed. Please try again.';

  @override
  String get onLeaveToday => 'You are on leave today';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get save => 'Save';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get myLeaves => 'My Leaves';

  @override
  String get noLeavesRequestedYet => 'No leaves requested yet.';

  @override
  String requestedOnDate(String date) {
    return 'Requested on $date';
  }

  @override
  String get leaveRequestSubmittedSuccess =>
      'Leave request submitted successfully.';

  @override
  String get leaveType => 'Leave Type';

  @override
  String get dateRange => 'Date Range';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get reason => 'Reason';

  @override
  String get enterLeaveReason => 'Enter reason for your leave...';

  @override
  String get pleaseEnterReason => 'Please enter a reason';

  @override
  String get attachmentOptional => 'Attachment (Optional)';

  @override
  String get tapToSelectDocument => 'Tap to select a document';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get sickLeave => 'Sick Leave';

  @override
  String get paidLeave => 'Paid Leave';

  @override
  String get otherLeave => 'Other';

  @override
  String get unpaidLeave => 'Unpaid Leave';

  @override
  String get annualLeave => 'Annual Leave';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get attendanceReminders => 'Attendance Reminders';

  @override
  String get dailyCheckInOutAlerts => 'Daily Check-in/out Alerts';

  @override
  String get dailyCheckInOutAlertsSubtitle =>
      'Get reminded 15 mins before shift starts and after shift ends.';

  @override
  String get testNotificationSent =>
      'Test notification sent! Check your notification tray or allow permissions if prompted.';

  @override
  String get testNotificationNow => 'Test Notification Now';

  @override
  String get notifications => 'Notifications';

  @override
  String get leaveNotifications => 'Leave Notifications';

  @override
  String get leaveNotificationsSubtitle =>
      'Get notified when your leave request is approved or rejected.';
}
