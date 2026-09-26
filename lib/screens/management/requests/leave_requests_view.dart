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
          detail: req.requestedType != null && req.requestedType != req.type
              ? 'Requested as ${req.requestedType!.value}'
              : null,
          dateLine:
              '${DateFormat('d MMM').format(req.startDate)} – ${DateFormat('d MMM yyyy').format(req.endDate)}',
          reason: req.reason,
          statusLabel: req.status.value,
          isPending: req.status == LeaveStatus.pending,
          onApprove: () => _action(context, req, LeaveStatus.approved),
          onReject: () => _action(context, req, LeaveStatus.rejected),
          actionedBy: viewModel.actorName(req.actionedBy),
          actionedAt: req.actionedAt,
          actionNote: req.actionReason,
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
    String? reason;
    LeaveType? leaveType;
    if (status == LeaveStatus.approved) {
      final decision = await _promptLeaveApproval(context, req.type);
      if (decision == null) return;
      reason = decision.note;
      leaveType = decision.type;
    } else {
      reason = await promptDecision(context, 'Reject leave?');
      if (reason == null) return;
    }
    try {
      await viewModel.actionLeave(
        req,
        status,
        reason: reason,
        leaveType: leaveType,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Leave ${status.value.toLowerCase()}.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }

  /// Approve dialog with a leave-type picker (pre-set to the requested type)
  /// and an optional note. Returns null when dismissed.
  Future<({LeaveType type, String note})?> _promptLeaveApproval(
    BuildContext context,
    LeaveType current,
  ) {
    final controller = TextEditingController();
    var selected = current;
    return showDialog<({LeaveType type, String note})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve leave?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<LeaveType>(
              initialValue: current,
              decoration: const InputDecoration(labelText: 'Leave type'),
              items: [
                for (final t in LeaveType.values)
                  DropdownMenuItem(value: t, child: Text(t.value)),
              ],
              onChanged: (t) {
                if (t != null) selected = t;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Reason shown to the employee',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              type: selected,
              note: controller.text.trim(),
            )),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
