import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/hr_payslip.dart';

void main() {
  test('totalDeductions includes advance, NSSF and the custom deduction', () {
    final p = HRPayslip.fromMap('p1', {
      'basicSalary': 750,
      'tax': 31.25,
      'leaveDeduction': 10,
      'otherDeductions': 2,
      'missedCheckOutDeduction': 1,
      'advanceDeduction': 50,
      'nssfContribution': 6,
      'customDeduction': 5,
      'customDeductionNote': ' Uniform ',
      'netSalary': 644.75,
      'currency': 'USD',
      'status': 'Pending',
    });
    expect(p.totalDeductions, 105.25);
    expect(p.grossEarnings - p.totalDeductions, p.netSalary);
    expect(p.customDeductionNote, 'Uniform');
  });

  test('older payslips without the new fields read as 0', () {
    final p = HRPayslip.fromMap('p1', {'basicSalary': 100, 'netSalary': 100});
    expect(p.advanceDeduction, 0);
    expect(p.nssfContribution, 0);
    expect(p.customDeduction, 0);
  });
}
