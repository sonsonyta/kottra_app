import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @recentAttendance.
  ///
  /// In en, this message translates to:
  /// **'Recent Attendance'**
  String get recentAttendance;

  /// No description provided for @viewAllAttendance.
  ///
  /// In en, this message translates to:
  /// **'View all attendance'**
  String get viewAllAttendance;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @checkOutAvailableAfterMinShift.
  ///
  /// In en, this message translates to:
  /// **'You can check out 1 minute after checking in.'**
  String get checkOutAvailableAfterMinShift;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get checkedIn;

  /// No description provided for @notCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Checked In'**
  String get notCheckedIn;

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked Out'**
  String get checkedOut;

  /// No description provided for @onLeave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get onLeave;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'Day Off'**
  String get dayOff;

  /// No description provided for @onDayOffToday.
  ///
  /// In en, this message translates to:
  /// **'You are scheduled off today.'**
  String get onDayOffToday;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @requestLeave.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get requestLeave;

  /// No description provided for @myPayslips.
  ///
  /// In en, this message translates to:
  /// **'My Payslips'**
  String get myPayslips;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noteRequired.
  ///
  /// In en, this message translates to:
  /// **'Note (Required)'**
  String get noteRequired;

  /// No description provided for @addNoteCheckInLate.
  ///
  /// In en, this message translates to:
  /// **'Add a note if you are checking in late.'**
  String get addNoteCheckInLate;

  /// No description provided for @addNoteCheckOutEarly.
  ///
  /// In en, this message translates to:
  /// **'Add a note if you are checking out early.'**
  String get addNoteCheckOutEarly;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogoutTitle;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogoutMessage;

  /// No description provided for @yesLogout.
  ///
  /// In en, this message translates to:
  /// **'Yes, Logout'**
  String get yesLogout;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistory;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get noteOptional;

  /// No description provided for @alreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You\'re already checked in today.'**
  String get alreadyCheckedIn;

  /// No description provided for @checkInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked in — {status}'**
  String checkInSuccess(String status);

  /// No description provided for @locationRequiredRemote.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to check in or out remotely.'**
  String get locationRequiredRemote;

  /// No description provided for @checkInFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in failed. Please try again.'**
  String get checkInFailed;

  /// No description provided for @alreadyCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'You\'re already checked out today.'**
  String get alreadyCheckedOut;

  /// No description provided for @checkOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked out successful'**
  String get checkOutSuccess;

  /// No description provided for @checkOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-out failed. Please try again.'**
  String get checkOutFailed;

  /// No description provided for @checkInQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — check-in saved and will sync automatically.'**
  String get checkInQueuedOffline;

  /// No description provided for @checkOutQueuedOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — check-out saved and will sync automatically.'**
  String get checkOutQueuedOffline;

  /// No description provided for @photoCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t take the photo. Please try again.'**
  String get photoCaptureFailed;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSync;

  /// No description provided for @onLeaveToday.
  ///
  /// In en, this message translates to:
  /// **'You are on leave today'**
  String get onLeaveToday;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @myLeaves.
  ///
  /// In en, this message translates to:
  /// **'My Leaves'**
  String get myLeaves;

  /// No description provided for @noLeavesRequestedYet.
  ///
  /// In en, this message translates to:
  /// **'No leaves requested yet.'**
  String get noLeavesRequestedYet;

  /// No description provided for @requestedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Requested on {date}'**
  String requestedOnDate(String date);

  /// No description provided for @leaveRequestSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Leave request submitted successfully.'**
  String get leaveRequestSubmittedSuccess;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveType;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @enterLeaveReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for your leave...'**
  String get enterLeaveReason;

  /// No description provided for @pleaseEnterReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason'**
  String get pleaseEnterReason;

  /// No description provided for @attachmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Attachment (Optional)'**
  String get attachmentOptional;

  /// No description provided for @tapToSelectDocument.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a document'**
  String get tapToSelectDocument;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get sickLeave;

  /// No description provided for @paidLeave.
  ///
  /// In en, this message translates to:
  /// **'Paid Leave'**
  String get paidLeave;

  /// No description provided for @otherLeave.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLeave;

  /// No description provided for @unpaidLeave.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Leave'**
  String get unpaidLeave;

  /// No description provided for @annualLeave.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave'**
  String get annualLeave;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusDeducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted'**
  String get statusDeducted;

  /// No description provided for @myAdvances.
  ///
  /// In en, this message translates to:
  /// **'My Advances'**
  String get myAdvances;

  /// No description provided for @requestAdvance.
  ///
  /// In en, this message translates to:
  /// **'Request Advance'**
  String get requestAdvance;

  /// No description provided for @noAdvancesRequestedYet.
  ///
  /// In en, this message translates to:
  /// **'No advances requested yet.'**
  String get noAdvancesRequestedYet;

  /// No description provided for @outstandingAdvanceBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding advance balance'**
  String get outstandingAdvanceBalance;

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Advance Amount'**
  String get advanceAmount;

  /// No description provided for @enterAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAdvanceAmount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @enterAdvanceReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for your advance...'**
  String get enterAdvanceReason;

  /// No description provided for @advanceDeductionNote.
  ///
  /// In en, this message translates to:
  /// **'This advance will be deducted in full from your next payroll once approved.'**
  String get advanceDeductionNote;

  /// No description provided for @advanceRequestSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Advance request submitted successfully.'**
  String get advanceRequestSubmittedSuccess;

  /// No description provided for @attendanceReminders.
  ///
  /// In en, this message translates to:
  /// **'Attendance Reminders'**
  String get attendanceReminders;

  /// No description provided for @dailyCheckInOutAlerts.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in/out Alerts'**
  String get dailyCheckInOutAlerts;

  /// No description provided for @dailyCheckInOutAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded 15 mins before shift starts and after shift ends.'**
  String get dailyCheckInOutAlertsSubtitle;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent! Check your notification tray or allow permissions if prompted.'**
  String get testNotificationSent;

  /// No description provided for @testNotificationNow.
  ///
  /// In en, this message translates to:
  /// **'Test Notification Now'**
  String get testNotificationNow;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @leaveNotifications.
  ///
  /// In en, this message translates to:
  /// **'Leave Notifications'**
  String get leaveNotifications;

  /// No description provided for @leaveNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when your leave request is approved or rejected.'**
  String get leaveNotificationsSubtitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @holiday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get holiday;

  /// No description provided for @yourDaysOff.
  ///
  /// In en, this message translates to:
  /// **'Your Days Off'**
  String get yourDaysOff;

  /// No description provided for @holidaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysThisMonth;

  /// No description provided for @noDaysOffThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No days off scheduled this month.'**
  String get noDaysOffThisMonth;

  /// No description provided for @noHolidaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No holidays this month.'**
  String get noHolidaysThisMonth;

  /// No description provided for @deductions.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductions;

  /// No description provided for @deductionsThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'Deductions This Period'**
  String get deductionsThisPeriod;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @periodFirstHalf.
  ///
  /// In en, this message translates to:
  /// **'1st–15th'**
  String get periodFirstHalf;

  /// No description provided for @periodSecondHalf.
  ///
  /// In en, this message translates to:
  /// **'16th–end of month'**
  String get periodSecondHalf;

  /// No description provided for @periodFullMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodFullMonth;

  /// No description provided for @estimatedFromAttendance.
  ///
  /// In en, this message translates to:
  /// **'Estimated from your attendance so far. Final amounts are set when payroll is run.'**
  String get estimatedFromAttendance;

  /// No description provided for @scanToCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Scan to Check In'**
  String get scanToCheckIn;

  /// No description provided for @scanToCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Scan to Check Out'**
  String get scanToCheckOut;

  /// No description provided for @scanQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Store QR'**
  String get scanQrTitle;

  /// No description provided for @scanQrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the store\'s check-in QR code.'**
  String get scanQrInstruction;

  /// No description provided for @qrWrongStore.
  ///
  /// In en, this message translates to:
  /// **'This QR code belongs to a different store.'**
  String get qrWrongStore;

  /// No description provided for @qrInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That\'s not a valid check-in QR code.'**
  String get qrInvalidCode;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan. Enable it in Settings.'**
  String get cameraPermissionRequired;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @payslipHistory.
  ///
  /// In en, this message translates to:
  /// **'Payslip History'**
  String get payslipHistory;

  /// No description provided for @latestPayslip.
  ///
  /// In en, this message translates to:
  /// **'Latest Payslip'**
  String get latestPayslip;

  /// No description provided for @currentDeductions.
  ///
  /// In en, this message translates to:
  /// **'Current Deductions'**
  String get currentDeductions;

  /// No description provided for @payslipPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payslipPaid;

  /// No description provided for @payslipPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payslipPending;

  /// No description provided for @payrollRunNumber.
  ///
  /// In en, this message translates to:
  /// **'Run #{id}'**
  String payrollRunNumber(String id);

  /// No description provided for @paidOnDate.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String paidOnDate(String date);

  /// No description provided for @previewFinalizedNote.
  ///
  /// In en, this message translates to:
  /// **'Preview · finalized when payroll runs'**
  String get previewFinalizedNote;

  /// No description provided for @awaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get awaitingPayment;

  /// No description provided for @pendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Pending payment'**
  String get pendingPayment;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @netPay.
  ///
  /// In en, this message translates to:
  /// **'Net Pay'**
  String get netPay;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic salary'**
  String get basicSalary;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get bonuses;

  /// No description provided for @allowances.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get allowances;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @leaveDeductionLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave deduction'**
  String get leaveDeductionLabel;

  /// No description provided for @otherDeduction.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherDeduction;

  /// No description provided for @payslipProvisionalNote.
  ///
  /// In en, this message translates to:
  /// **'These figures are provisional and may change until payroll is finalized.'**
  String get payslipProvisionalNote;

  /// No description provided for @noPayslipsYet.
  ///
  /// In en, this message translates to:
  /// **'No payslips yet'**
  String get noPayslipsYet;

  /// No description provided for @payslipsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your payslips will appear here once payroll runs.'**
  String get payslipsWillAppearHere;

  /// No description provided for @lateExcusesTitle.
  ///
  /// In en, this message translates to:
  /// **'Late Excuses'**
  String get lateExcusesTitle;

  /// No description provided for @requestLateExcuse.
  ///
  /// In en, this message translates to:
  /// **'Request Excuse'**
  String get requestLateExcuse;

  /// No description provided for @noLateExcusesYet.
  ///
  /// In en, this message translates to:
  /// **'No late excuse requests yet.'**
  String get noLateExcusesYet;

  /// No description provided for @selectLateDay.
  ///
  /// In en, this message translates to:
  /// **'Select a late day'**
  String get selectLateDay;

  /// No description provided for @noExcusableLateDays.
  ///
  /// In en, this message translates to:
  /// **'You have no late days to request an excuse for.'**
  String get noExcusableLateDays;

  /// No description provided for @lateExcuseReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why should this lateness be excused?'**
  String get lateExcuseReasonHint;

  /// No description provided for @lateExcuseSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Late excuse request submitted.'**
  String get lateExcuseSubmittedSuccess;

  /// No description provided for @lateExcuseDeductionNote.
  ///
  /// In en, this message translates to:
  /// **'If approved, this day\'s lateness won\'t be deducted from your pay.'**
  String get lateExcuseDeductionNote;

  /// No description provided for @minutesLate.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min late'**
  String minutesLate(int minutes);

  /// No description provided for @lateExcusePastDay.
  ///
  /// In en, this message translates to:
  /// **'Past late day'**
  String get lateExcusePastDay;

  /// No description provided for @lateExcuseUpcomingDay.
  ///
  /// In en, this message translates to:
  /// **'Upcoming day'**
  String get lateExcuseUpcomingDay;

  /// No description provided for @selectUpcomingLateDay.
  ///
  /// In en, this message translates to:
  /// **'Select the day you\'ll be late'**
  String get selectUpcomingLateDay;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by {name}'**
  String approvedBy(String name);

  /// No description provided for @rejectedBy.
  ///
  /// In en, this message translates to:
  /// **'Rejected by {name}'**
  String rejectedBy(String name);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @switchStore.
  ///
  /// In en, this message translates to:
  /// **'Switch store'**
  String get switchStore;

  /// No description provided for @leaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave requests'**
  String get leaveRequests;

  /// No description provided for @leaveRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and approve time off'**
  String get leaveRequestsSubtitle;

  /// No description provided for @lateExcuses.
  ///
  /// In en, this message translates to:
  /// **'Late excuses'**
  String get lateExcuses;

  /// No description provided for @lateExcusesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review late-arrival excuses'**
  String get lateExcusesSubtitle;

  /// No description provided for @salaryAdvances.
  ///
  /// In en, this message translates to:
  /// **'Salary advances'**
  String get salaryAdvances;

  /// No description provided for @salaryAdvancesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review advance requests'**
  String get salaryAdvancesSubtitle;

  /// No description provided for @attendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See who\'s in today'**
  String get attendanceSubtitle;

  /// No description provided for @noAttendanceForDay.
  ///
  /// In en, this message translates to:
  /// **'No attendance records for this day.'**
  String get noAttendanceForDay;

  /// No description provided for @lateExcused.
  ///
  /// In en, this message translates to:
  /// **'Late excused'**
  String get lateExcused;

  /// No description provided for @photoIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get photoIn;

  /// No description provided for @photoOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get photoOut;

  /// No description provided for @inLocation.
  ///
  /// In en, this message translates to:
  /// **'In location'**
  String get inLocation;

  /// No description provided for @outLocation.
  ///
  /// In en, this message translates to:
  /// **'Out location'**
  String get outLocation;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps.'**
  String get couldNotOpenMaps;

  /// No description provided for @noLeaveRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No leave requests yet.'**
  String get noLeaveRequestsYet;

  /// No description provided for @noAdvanceRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No salary advance requests yet.'**
  String get noAdvanceRequestsYet;

  /// No description provided for @requestedAs.
  ///
  /// In en, this message translates to:
  /// **'Requested as {type}'**
  String requestedAs(String type);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @decisionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Reason shown to the employee'**
  String get decisionNoteHint;

  /// No description provided for @couldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update: {error}'**
  String couldNotUpdate(String error);

  /// No description provided for @approveLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve leave?'**
  String get approveLeaveTitle;

  /// No description provided for @rejectLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject leave?'**
  String get rejectLeaveTitle;

  /// No description provided for @leaveApproved.
  ///
  /// In en, this message translates to:
  /// **'Leave approved.'**
  String get leaveApproved;

  /// No description provided for @leaveRejected.
  ///
  /// In en, this message translates to:
  /// **'Leave rejected.'**
  String get leaveRejected;

  /// No description provided for @advanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Advance · {amount}'**
  String advanceSubtitle(String amount);

  /// No description provided for @approveAdvanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve {amount} advance?'**
  String approveAdvanceTitle(String amount);

  /// No description provided for @rejectAdvanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject {amount} advance?'**
  String rejectAdvanceTitle(String amount);

  /// No description provided for @advanceApproved.
  ///
  /// In en, this message translates to:
  /// **'Advance approved.'**
  String get advanceApproved;

  /// No description provided for @advanceRejected.
  ///
  /// In en, this message translates to:
  /// **'Advance rejected.'**
  String get advanceRejected;

  /// No description provided for @lateExcuseLabel.
  ///
  /// In en, this message translates to:
  /// **'Late excuse'**
  String get lateExcuseLabel;

  /// No description provided for @approveLateExcuseTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve late excuse?'**
  String get approveLateExcuseTitle;

  /// No description provided for @rejectLateExcuseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject late excuse?'**
  String get rejectLateExcuseTitle;

  /// No description provided for @lateExcuseApproved.
  ///
  /// In en, this message translates to:
  /// **'Late excuse approved.'**
  String get lateExcuseApproved;

  /// No description provided for @lateExcuseRejected.
  ///
  /// In en, this message translates to:
  /// **'Late excuse rejected.'**
  String get lateExcuseRejected;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @couldNotUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo: {error}'**
  String couldNotUploadPhoto(String error);

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @employeeRequests.
  ///
  /// In en, this message translates to:
  /// **'Employee requests'**
  String get employeeRequests;

  /// No description provided for @employeeRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when employees submit leave or late-excuse requests'**
  String get employeeRequestsSubtitle;

  /// No description provided for @selectStore.
  ///
  /// In en, this message translates to:
  /// **'Select a store'**
  String get selectStore;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noStoreRole.
  ///
  /// In en, this message translates to:
  /// **'No store role assigned'**
  String get noStoreRole;

  /// No description provided for @noStoreRoleMessage.
  ///
  /// In en, this message translates to:
  /// **'This account isn\'t a member of any store. Ask a store owner to add you, then sign in again.'**
  String get noStoreRoleMessage;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// No description provided for @couldNotLoadStores.
  ///
  /// In en, this message translates to:
  /// **'Could not load your stores. Please try again.'**
  String get couldNotLoadStores;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
