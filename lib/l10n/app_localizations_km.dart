// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get home => 'ទំព័រដើម';

  @override
  String get attendance => 'វត្តមាន';

  @override
  String get payroll => 'ប្រាក់ខែ';

  @override
  String get profile => 'គណនី';

  @override
  String get appearance => 'រូបរាង';

  @override
  String get language => 'ភាសា';

  @override
  String get themeAuto => 'ស្វ័យប្រវត្តិ';

  @override
  String get themeLight => 'ភ្លឺ';

  @override
  String get themeDark => 'ងងឹត';

  @override
  String get employeeId => 'លេខសម្គាល់បុគ្គលិក';

  @override
  String get position => 'តួនាទី';

  @override
  String get department => 'ផ្នែក';

  @override
  String get logout => 'ចាកចេញ';

  @override
  String get recentAttendance => 'វត្តមានថ្មីៗ';

  @override
  String get viewAllAttendance => 'មើលវត្តមានទាំងអស់';

  @override
  String get checkIn => 'កត់វត្តមានចូល';

  @override
  String get checkOut => 'កត់វត្តមានចេញ';

  @override
  String get checkedIn => 'បានកត់វត្តមានចូល';

  @override
  String get notCheckedIn => 'មិនទាន់កត់វត្តមានចូល';

  @override
  String get checkedOut => 'បានកត់វត្តមានចេញ';

  @override
  String get onLeave => 'ឈប់សម្រាក';

  @override
  String get present => 'មកធ្វើការ';

  @override
  String get late => 'យឺត';

  @override
  String get absent => 'អវត្តមាន';

  @override
  String get leave => 'ឈប់សម្រាក';

  @override
  String get dayOff => 'ថ្ងៃឈប់';

  @override
  String get onDayOffToday => 'ថ្ងៃនេះជាថ្ងៃឈប់សម្រាករបស់អ្នក។';

  @override
  String get quickActions => 'សកម្មភាពរហ័ស';

  @override
  String get requestLeave => 'ស្នើសុំឈប់សម្រាក';

  @override
  String get myPayslips => 'របាយការណ៍ប្រាក់ខែ';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get confirm => 'បញ្ជាក់';

  @override
  String get noteRequired => 'ចំណាំ (ទាមទារ)';

  @override
  String get addNoteCheckInLate => 'បន្ថែមចំណាំប្រសិនបើអ្នកកត់វត្តមានចូលយឺត។';

  @override
  String get addNoteCheckOutEarly => 'បន្ថែមចំណាំប្រសិនបើអ្នកកត់វត្តមានចេញមុន។';

  @override
  String get confirmLogoutTitle => 'បញ្ជាក់ការចាកចេញ';

  @override
  String get confirmLogoutMessage => 'តើអ្នកពិតជាចង់ចាកចេញមែនទេ?';

  @override
  String get yesLogout => 'បាទ/ចាស, ចាកចេញ';

  @override
  String get attendanceHistory => 'ប្រវត្តិវត្តមាន';

  @override
  String get noteOptional => 'ចំណាំ (ជាជម្រើស)';

  @override
  String get alreadyCheckedIn => 'អ្នកបានកត់វត្តមានចូលរួចហើយសម្រាប់ថ្ងៃនេះ។';

  @override
  String checkInSuccess(String status) {
    return 'បានកត់វត្តមានចូល — $status';
  }

  @override
  String get checkInFailed => 'ការកត់វត្តមានចូលបានបរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get alreadyCheckedOut => 'អ្នកបានកត់វត្តមានចេញរួចហើយសម្រាប់ថ្ងៃនេះ។';

  @override
  String get checkOutSuccess => 'បានកត់វត្តមានចេញដោយជោគជ័យ';

  @override
  String get checkOutFailed => 'ការកត់វត្តមានចេញបានបរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get onLeaveToday => 'អ្នកឈប់សម្រាកនៅថ្ងៃនេះ';

  @override
  String get editProfile => 'កែប្រែគណនី';

  @override
  String get firstName => 'នាមខ្លួន';

  @override
  String get lastName => 'នាមត្រកូល';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get goodMorning => 'អរុណសួស្តី';

  @override
  String get goodAfternoon => 'ទិវាសួស្តី';

  @override
  String get goodEvening => 'សាយ័ន្តសួស្តី';

  @override
  String get myLeaves => 'ការសុំច្បាប់របស់ខ្ញុំ';

  @override
  String get noLeavesRequestedYet => 'មិនទាន់មានការស្នើសុំឈប់សម្រាកនៅឡើយទេ។';

  @override
  String requestedOnDate(String date) {
    return 'បានស្នើសុំនៅ $date';
  }

  @override
  String get leaveRequestSubmittedSuccess =>
      'ការស្នើសុំឈប់សម្រាកត្រូវបានបញ្ជូនដោយជោគជ័យ។';

  @override
  String get leaveType => 'ប្រភេទនៃការឈប់សម្រាក';

  @override
  String get dateRange => 'រយៈពេល';

  @override
  String get startDate => 'ថ្ងៃចាប់ផ្តើម';

  @override
  String get endDate => 'ថ្ងៃបញ្ចប់';

  @override
  String get reason => 'មូលហេតុ';

  @override
  String get enterLeaveReason => 'បញ្ចូលមូលហេតុនៃការឈប់សម្រាករបស់អ្នក...';

  @override
  String get pleaseEnterReason => 'សូមបញ្ចូលមូលហេតុ';

  @override
  String get attachmentOptional => 'ឯកសារភ្ជាប់ (ជាជម្រើស)';

  @override
  String get tapToSelectDocument => 'ប៉ះដើម្បីជ្រើសរើសឯកសារ';

  @override
  String get submitRequest => 'បញ្ជូនការស្នើសុំ';

  @override
  String errorPrefix(String message) {
    return 'កំហុស: $message';
  }

  @override
  String get sickLeave => 'ច្បាប់ឈឺ';

  @override
  String get paidLeave => 'ច្បាប់សម្រាកមានប្រាក់ឈ្នួល';

  @override
  String get otherLeave => 'ផ្សេងៗ';

  @override
  String get unpaidLeave => 'ច្បាប់សម្រាកគ្មានប្រាក់ឈ្នួល';

  @override
  String get annualLeave => 'ច្បាប់សម្រាកប្រចាំឆ្នាំ';

  @override
  String get statusPending => 'រង់ចាំការអនុម័ត';

  @override
  String get statusApproved => 'បានអនុម័ត';

  @override
  String get statusRejected => 'បានបដិសេធ';

  @override
  String get statusDeducted => 'បានកាត់';

  @override
  String get myAdvances => 'បុរេប្រទានរបស់ខ្ញុំ';

  @override
  String get requestAdvance => 'ស្នើសុំបុរេប្រទាន';

  @override
  String get noAdvancesRequestedYet => 'មិនទាន់មានការស្នើសុំបុរេប្រទានទេ។';

  @override
  String get outstandingAdvanceBalance => 'សមតុល្យបុរេប្រទាននៅសល់';

  @override
  String get advanceAmount => 'ចំនួនបុរេប្រទាន';

  @override
  String get enterAdvanceAmount => 'បញ្ចូលចំនួនទឹកប្រាក់';

  @override
  String get pleaseEnterValidAmount => 'សូមបញ្ចូលចំនួនទឹកប្រាក់ត្រឹមត្រូវ';

  @override
  String get enterAdvanceReason => 'បញ្ចូលមូលហេតុនៃការស្នើសុំបុរេប្រទាន...';

  @override
  String get advanceDeductionNote =>
      'បុរេប្រទាននេះនឹងត្រូវកាត់ទាំងស្រុងពីប្រាក់ខែបន្ទាប់របស់អ្នក បន្ទាប់ពីត្រូវបានអនុម័ត។';

  @override
  String get advanceRequestSubmittedSuccess =>
      'ការស្នើសុំបុរេប្រទានត្រូវបានដាក់ស្នើដោយជោគជ័យ។';

  @override
  String get attendanceReminders => 'ការរំលឹកវត្តមាន';

  @override
  String get dailyCheckInOutAlerts => 'ការជូនដំណឹងកត់វត្តមានចូល/ចេញប្រចាំថ្ងៃ';

  @override
  String get dailyCheckInOutAlertsSubtitle =>
      'ទទួលបានការរំលឹក ១៥ នាទីមុនពេលចាប់ផ្តើមវេន និងបន្ទាប់ពីវេនបញ្ចប់។';

  @override
  String get testNotificationSent =>
      'ការជូនដំណឹងសាកល្បងបានផ្ញើ! ពិនិត្យមើលការជូនដំណឹងរបស់អ្នក ឬអនុញ្ញាតការអនុញ្ញាតប្រសិនបើត្រូវបានសុំ។';

  @override
  String get testNotificationNow => 'សាកល្បងការជូនដំណឹងឥឡូវ';

  @override
  String get notifications => 'ការជូនដំណឹង';

  @override
  String get leaveNotifications => 'ការជូនដំណឹងច្បាប់ឈប់សម្រាក';

  @override
  String get leaveNotificationsSubtitle =>
      'ទទួលបានការជូនដំណឹងនៅពេលការស្នើសុំឈប់សម្រាករបស់អ្នកត្រូវបានអនុម័ត ឬបដិសេធ។';

  @override
  String get scheduleTitle => 'កាលវិភាគ';

  @override
  String get today => 'ថ្ងៃនេះ';

  @override
  String get holiday => 'ថ្ងៃឈប់បុណ្យ';

  @override
  String get yourDaysOff => 'ថ្ងៃឈប់សម្រាករបស់អ្នក';

  @override
  String get holidaysThisMonth => 'ថ្ងៃឈប់បុណ្យ';

  @override
  String get noDaysOffThisMonth => 'មិនមានថ្ងៃឈប់សម្រាកសម្រាប់ខែនេះទេ។';

  @override
  String get noHolidaysThisMonth => 'មិនមានថ្ងៃឈប់បុណ្យសម្រាប់ខែនេះទេ។';

  @override
  String get deductions => 'ការកាត់ប្រាក់';

  @override
  String get deductionsThisPeriod => 'ការកាត់ប្រាក់ក្នុងអំឡុងពេលនេះ';

  @override
  String get total => 'សរុប';

  @override
  String get periodFirstHalf => 'ថ្ងៃ១–១៥';

  @override
  String get periodSecondHalf => 'ថ្ងៃ១៦–ចុងខែ';

  @override
  String get periodFullMonth => 'ខែនេះ';

  @override
  String get estimatedFromAttendance =>
      'បា៉ន់ស្មានតាមវត្តមានរបស់អ្នករហូតមកដល់ពេលនេះ។ ចំនួនចុងក្រោយត្រូវបានកំណត់នៅពេលដំណើរការប្រាក់ខែ។';

  @override
  String get scanToCheckIn => 'ស្កេនដើម្បីចូល';

  @override
  String get scanToCheckOut => 'ស្កេនដើម្បីចេញ';

  @override
  String get scanQrTitle => 'ស្កេន QR ហាង';

  @override
  String get scanQrInstruction =>
      'តម្រង់កាមេរ៉ារបស់អ្នកទៅកាន់កូដ QR សម្រាប់ចុះវត្តមានរបស់ហាង។';

  @override
  String get qrWrongStore => 'កូដ QR នេះជាកម្មសិទ្ធិរបស់ហាងផ្សេង។';

  @override
  String get qrInvalidCode =>
      'នេះមិនមែនជាកូដ QR សម្រាប់ចុះវត្តមានត្រឹមត្រូវទេ។';

  @override
  String get cameraPermissionRequired =>
      'ត្រូវការការអនុញ្ញាតកាមេរ៉ាដើម្បីស្កេន។ សូមបើកវានៅក្នុងការកំណត់។';

  @override
  String get openSettings => 'បើកការកំណត់';

  @override
  String get payslipHistory => 'ប្រវត្តិប័ណ្ណប្រាក់ខែ';

  @override
  String get latestPayslip => 'ប័ណ្ណប្រាក់ខែចុងក្រោយ';

  @override
  String get currentDeductions => 'ការកាត់ប្រាក់បច្ចុប្បន្ន';

  @override
  String get payslipPaid => 'បានបង់ប្រាក់';

  @override
  String get payslipPending => 'រង់ចាំបង់ប្រាក់';

  @override
  String payrollRunNumber(String id) {
    return 'លេខ #$id';
  }

  @override
  String paidOnDate(String date) {
    return 'បង់ប្រាក់នៅ $date';
  }

  @override
  String get previewFinalizedNote => 'មើលជាមុន · បញ្ចប់នៅពេលដំណើរការប្រាក់ខែ';

  @override
  String get awaitingPayment => 'កំពុងរង់ចាំការបង់ប្រាក់';

  @override
  String get pendingPayment => 'រង់ចាំការបង់ប្រាក់';

  @override
  String get earnings => 'ប្រាក់ចំណូល';

  @override
  String get netPay => 'ប្រាក់សុទ្ធ';

  @override
  String get basicSalary => 'ប្រាក់ខែមូលដ្ឋាន';

  @override
  String get overtime => 'ម៉ោងបន្ថែម';

  @override
  String get bonuses => 'ប្រាក់រង្វាន់';

  @override
  String get allowances => 'ប្រាក់ឧបត្ថម្ភ';

  @override
  String get tax => 'ពន្ធ';

  @override
  String get leaveDeductionLabel => 'កាត់ប្រាក់ច្បាប់ឈប់សម្រាក';

  @override
  String get otherDeduction => 'ផ្សេងៗ';

  @override
  String get payslipProvisionalNote =>
      'តួលេខទាំងនេះជាបណ្តោះអាសន្ន ហើយអាចផ្លាស់ប្តូរ រហូតដល់ការគណនាប្រាក់ខែត្រូវបានបញ្ចប់។';

  @override
  String get noPayslipsYet => 'មិនទាន់មានប័ណ្ណប្រាក់ខែ';

  @override
  String get payslipsWillAppearHere =>
      'ប័ណ្ណប្រាក់ខែរបស់អ្នកនឹងបង្ហាញនៅទីនេះ បន្ទាប់ពីដំណើរការប្រាក់ខែ។';
}
