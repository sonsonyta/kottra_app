import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/early_leave_request.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class EarlyLeaveRequestsView extends StatelessWidget {
  const EarlyLeaveRequestsView({super.key, required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = dateLocale(context);
    if (viewModel.earlyLeaveLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.earlyLeave.isEmpty) {
      return EmptyState(
        icon: Icons.logout,
        message: l10n.noEarlyLeaveYet,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.earlyLeave.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = viewModel.earlyLeave[i];
        return RequestCard(
          title: req.employeeName.isNotEmpty
              ? req.employeeName
              : req.employeeId,
          subtitle: '${l10n.earlyLeaveLabel} · ${l10n.leaveAtTime(req.leaveTime)}',
          dateLine: DateFormat('EEE, d MMM yyyy', locale).format(req.date),
          reason: req.reason,
          status: req.status.value,
          isPending: req.status == EarlyLeaveStatus.pending,
          onApprove: () => _action(context, req, EarlyLeaveStatus.approved),
          onReject: () => _action(context, req, EarlyLeaveStatus.rejected),
          actionedBy: viewModel.actorName(req.actionedBy),
          actionedAt: req.actionedAt,
          actionNote: req.actionReason,
        );
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    EarlyLeaveRequest req,
    EarlyLeaveStatus status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final reason = await promptDecision(
      context,
      status == EarlyLeaveStatus.approved
          ? l10n.approveEarlyLeaveTitle
          : l10n.rejectEarlyLeaveTitle,
    );
    if (reason == null) return;
    try {
      await viewModel.actionEarlyLeave(req, status, reason: reason);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == EarlyLeaveStatus.approved
                ? l10n.earlyLeaveApproved
                : l10n.earlyLeaveRejected,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdate('$e'))),
      );
    }
  }
}
