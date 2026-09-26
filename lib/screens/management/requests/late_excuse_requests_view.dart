import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/models/late_excuse_request.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class LateExcuseRequestsView extends StatelessWidget {
  const LateExcuseRequestsView({super.key, required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.lateExcusesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.lateExcuses.isEmpty) {
      return EmptyState(
        icon: Icons.timer_off_rounded,
        message: 'No late-excuse requests yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.lateExcuses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = viewModel.lateExcuses[i];
        final late = req.lateMinutes != null
            ? ' · ${req.lateMinutes} min late'
            : '';
        return RequestCard(
          title: req.employeeName.isNotEmpty
              ? req.employeeName
              : req.employeeId,
          subtitle: 'Late excuse$late',
          dateLine: DateFormat('EEE, d MMM yyyy').format(req.date),
          reason: req.reason,
          statusLabel: req.status.value,
          isPending: req.status == LateExcuseStatus.pending,
          onApprove: () => _action(context, req, LateExcuseStatus.approved),
          onReject: () => _action(context, req, LateExcuseStatus.rejected),
          actionedBy: viewModel.actorName(req.actionedBy),
          actionedAt: req.actionedAt,
          actionNote: req.actionReason,
        );
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    LateExcuseRequest req,
    LateExcuseStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await promptDecision(
      context,
      status == LateExcuseStatus.approved
          ? 'Approve late excuse?'
          : 'Reject late excuse?',
    );
    if (reason == null) return;
    try {
      await viewModel.actionLateExcuse(req, status, reason: reason);
      messenger.showSnackBar(
        SnackBar(content: Text('Late excuse ${status.value.toLowerCase()}.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}
