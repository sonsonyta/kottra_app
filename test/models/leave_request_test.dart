import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/leave_request.dart';

void main() {
  group('LeaveRequest.fromMap leave type', () {
    test('prefers the POS `leaveType` over `type`', () {
      final req = LeaveRequest.fromMap('1', {
        'leaveType': 'Sick Leave',
        'type': 'Other',
      });
      expect(req.type, LeaveType.sick);
    });

    test('falls back to `type` when `leaveType` is missing or blank', () {
      expect(
        LeaveRequest.fromMap('1', {'type': 'Paid Leave'}).type,
        LeaveType.paid,
      );
      expect(
        LeaveRequest.fromMap('1', {'leaveType': '', 'type': 'Paid Leave'}).type,
        LeaveType.paid,
      );
    });

    test('reads the original requested type after an approver override', () {
      final req = LeaveRequest.fromMap('1', {
        'leaveType': 'Unpaid Leave',
        'requestedLeaveType': 'Annual Leave',
      });
      expect(req.type, LeaveType.unpaid);
      expect(req.requestedType, LeaveType.annual);
      expect(
        LeaveRequest.fromMap('1', {'type': 'Other'}).requestedType,
        isNull,
      );
    });
  });
}
