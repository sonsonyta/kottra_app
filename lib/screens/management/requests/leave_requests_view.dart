import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class LeaveRequestsView extends StatelessWidget {
  const LeaveRequestsView({super.key, required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.leavesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.leaves.isEmpty) {
      return EmptyState(
        icon: Icons.beach_access_rounded,
        message: 'No leave requests yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.leaves.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = viewModel.leaves[i];
        return RequestCard(
          title: req.employeeName.isNotEmpty
              ? req.employeeName
              : req.employeeId,
          subtitle: req.type.value,
          dateLine:
              '${DateFormat('d MMM').format(req.startDate)} – ${DateFormat('d MMM yyyy').format(req.endDate)}',
          reason: req.reason,
          statusLabel: req.status.value,
          isPending: req.status == LeaveStatus.pending,
          onApprove: () => _action(context, req, LeaveStatus.approved),
          onReject: () => _action(context, req, LeaveStatus.rejected),
        );
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    LeaveRequest req,
    LeaveStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await promptDecision(
      context,
      status == LeaveStatus.approved ? 'Approve leave?' : 'Reject leave?',
    );
    if (reason == null) return;
    try {
      await viewModel.actionLeave(req, status, reason: reason);
      messenger.showSnackBar(
        SnackBar(content: Text('Leave ${status.value.toLowerCase()}.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}
