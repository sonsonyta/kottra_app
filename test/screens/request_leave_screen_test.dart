import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/attendance_record.dart' as att;
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_settings.dart';
import 'package:kottra_app/screens/leave/request_leave_screen.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/settings_service.dart';
import 'package:kottra_app/view_models/leave_view_model.dart';

import '../view_models/leave_view_model_test.dart'
    show FakeLeaveService, FakeStoreService;

class _Settings implements SettingsService {
  @override
  Stream<HrSettings> streamHrSettings(String storeId) => Stream.value(
        HrSettings(
          payrollFrequency: PayrollFrequency.monthly,
          lateDeduction: LateDeductionSettings.disabled,
          absenceDeduction: AbsenceDeductionSettings.legacyDefault,
          leaveLimits: const {'Sick Leave': 7},
          allowDisplayPreviewDeduction: true,
          deductionPeriodBasis: DeductionPeriodBasis.payrollFrequency,
          attendanceMethod: AttendanceMethod.button,
          requirePhotoOnAttendance: false,
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Employees implements EmployeeService {
  @override
  Stream<HREmployee?> streamEmployee(String storeId, String employeeId) =>
      Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Attendance implements AttendanceService {
  @override
  Stream<List<att.AttendanceRecord>> streamLeaveRecords(
    String storeId,
    String employeeId,
  ) {
    final year = DateTime.now().year;
    // Two Sick Leave days already taken this year.
    return Stream.value([
      for (final d in [3, 4])
        att.AttendanceRecord(
          id: 'l$d',
          storeId: 's1',
          employeeId: 'e1',
          employeeName: 'Dara',
          date: Timestamp.fromDate(DateTime(year, 1, d)),
          status: att.AttendanceStatus.leave,
          leaveType: att.LeaveType.sickLeave,
        ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<LeaveViewModel> _pump(WidgetTester tester, Locale locale) async {
  final vm = LeaveViewModel(
    storeId: 's1',
    employeeId: 'e1',
    employeeName: 'Dara',
    leaveService: FakeLeaveService(),
    storeService: FakeStoreService(),
  )..watchLeaveLimits(
      settingsService: _Settings(),
      employeeService: _Employees(),
      attendanceService: _Attendance(),
    );
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: RequestLeaveScreen(viewModel: vm),
  ));
  await tester.pumpAndSettle();
  return vm;
}

void main() {
  testWidgets('no Other option; days left show once a type is chosen',
      (tester) async {
    final vm = await _pump(tester, const Locale('en'));
    expect(find.text('Other'), findsNothing);
    expect(find.text('Selected days'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('Days left this year'), findsNothing);

    await tester.tap(find.text('Sick Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Days left this year'), findsOneWidget);
    expect(find.text('5 of 7 days'), findsOneWidget);
    vm.dispose();
  });

  testWidgets('Khmer labels', (tester) async {
    final vm = await _pump(tester, const Locale('km'));
    expect(find.text('ចំនួនថ្ងៃដែលបានជ្រើស'), findsOneWidget);
    await tester.tap(find.byType(ChoiceChip).first); // Sick Leave
    await tester.pumpAndSettle();
    expect(find.text('ថ្ងៃឈប់ដែលនៅសល់ក្នុងឆ្នាំនេះ'), findsOneWidget);
    expect(find.text('5 ក្នុងចំណោម 7 ថ្ងៃ'), findsOneWidget);
    vm.dispose();
  });
}
