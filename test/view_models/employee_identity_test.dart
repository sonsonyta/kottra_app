import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/view_models/employee_identity.dart';

void main() {
  group('parseEmployeeUid', () {
    test('parses a well-formed employee UID', () {
      final id = parseEmployeeUid('hr_employee:store1:emp7');
      expect(id, isNotNull);
      expect(id!.storeId, 'store1');
      expect(id.employeeId, 'emp7');
    });

    test('returns null for a non-employee UID', () {
      expect(parseEmployeeUid('someFirebaseUid123'), isNull);
      expect(parseEmployeeUid('hr_employee:onlytwo'), isNull);
      expect(parseEmployeeUid('other:store1:emp7'), isNull);
    });
  });

  group('isEmployeeUid', () {
    test('true only for employee-token UIDs', () {
      // Employee-token login → employee UI.
      expect(isEmployeeUid('hr_employee:store1:emp7'), isTrue);
      // Email/password login (normal Firebase UID) → store-user UI.
      expect(isEmployeeUid('someFirebaseUid123'), isFalse);
      expect(isEmployeeUid(''), isFalse);
    });
  });
}
