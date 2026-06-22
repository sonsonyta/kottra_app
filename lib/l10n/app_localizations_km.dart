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
}
