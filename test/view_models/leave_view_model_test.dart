import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/models/store.dart';
import 'package:kottra_app/services/leave_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/view_models/leave_view_model.dart';

class FakeLeaveService implements LeaveService {
  final List<StreamController<List<LeaveRequest>>> controllers = [];

  @override
  Stream<List<LeaveRequest>> streamEmployeeLeaves(
      String storeId, String employeeId) {
    final controller = StreamController<List<LeaveRequest>>();
    controllers.add(controller);
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStoreService implements StoreService {
  @override
  Future<Store?> getStore(String storeId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LeaveRequest _leave(LeaveStatus status) => LeaveRequest(
      id: 'l1',
      storeId: 's1',
      employeeId: 'e1',
      employeeName: 'Dara',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 2),
      type: LeaveType.sick,
      status: status,
      reason: 'Flu',
    );

void main() {
  late FakeLeaveService leaveService;
  late LeaveViewModel viewModel;

  setUp(() {
    leaveService = FakeLeaveService();
    viewModel = LeaveViewModel(
      storeId: 's1',
      employeeId: 'e1',
      employeeName: 'Dara',
      leaveService: leaveService,
      storeService: FakeStoreService(),
    );
  });

  tearDown(() => viewModel.dispose());

  test('shows status changes pushed by the live stream', () async {
    leaveService.controllers.single.add([_leave(LeaveStatus.pending)]);
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.leaves.single.status, LeaveStatus.pending);

    leaveService.controllers.single.add([_leave(LeaveStatus.approved)]);
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.leaves.single.status, LeaveStatus.approved);
  });
}
