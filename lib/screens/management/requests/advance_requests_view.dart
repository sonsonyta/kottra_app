import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/models/salary_advance.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class AdvanceRequestsView extends StatelessWidget {
  const AdvanceRequestsView({super.key, required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.advancesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.advances.isEmpty) {
      return EmptyState(
        icon: Icons.payments_rounded,
        message: 'No salary advance requests yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.advances.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final advance = viewModel.advances[i];
        return RequestCard(
          title: advance.employeeName.isNotEmpty
              ? advance.employeeName
              : advance.employeeId,
          subtitle:
              'Advance · ${fmtMoney(advance.amount, advance.currency.value)}',
          dateLine:
              'Requested ${DateFormat('EEE, d MMM yyyy').format(advance.requestedAt)}',
          reason: advance.reason,
          statusLabel: advance.status.value,
          isPending: advance.status == AdvanceStatus.pending,
          onApprove: () => _action(context, advance, AdvanceStatus.approved),
          onReject: () => _action(context, advance, AdvanceStatus.rejected),
          actionedBy: viewModel.actorName(advance.actionedBy),
          actionedAt: advance.actionedAt,
          actionNote: advance.actionReason,
        );
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    SalaryAdvance advance,
    AdvanceStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = fmtMoney(advance.amount, advance.currency.value);
    final reason = await promptDecision(
      context,
      status == AdvanceStatus.approved
          ? 'Approve $amount advance?'
          : 'Reject $amount advance?',
    );
    if (reason == null) return;
    try {
      await viewModel.actionAdvance(advance, status, reason: reason);
      messenger.showSnackBar(
        SnackBar(content: Text('Advance ${status.value.toLowerCase()}.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}
