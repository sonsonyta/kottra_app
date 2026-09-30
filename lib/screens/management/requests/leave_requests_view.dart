import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class LeaveRequestsView extends StatelessWidget {
  const LeaveRequestsView({super.key, required this.viewModel});

  final StoreManagementViewModel viewModel;

  static String _typeLabel(AppLocalizations l10n, LeaveType type) {
    return switch (type) {
      LeaveType.sick => l10n.sickLeave,
      LeaveType.paid => l10n.paidLeave,
      LeaveType.other => l10n.otherLeave,
      LeaveType.unpaid => l10n.unpaidLeave,
      LeaveType.annual => l10n.annualLeave,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = dateLocale(context);
    if (viewModel.leavesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.leaves.isEmpty) {
      return EmptyState(
        icon: Icons.beach_access_rounded,
        message: l10n.noLeaveRequestsYet,
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
          subtitle: _typeLabel(l10n, req.type),
          detail: req.requestedType != null && req.requestedType != req.type
              ? l10n.requestedAs(_typeLabel(l10n, req.requestedType!))
              : null,
          dateLine:
              '${DateFormat('d MMM', locale).format(req.startDate)} – ${DateFormat('d MMM yyyy', locale).format(req.endDate)}',
          reason: req.reason,
          status: req.status.value,
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
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    String? reason;
    LeaveType? leaveType;
    if (status == LeaveStatus.approved) {
      final decision = await _promptLeaveApproval(context, req.type);
      if (decision == null) return;
      reason = decision.note;
      leaveType = decision.type;
    } else {
      reason = await promptDecision(context, l10n.rejectLeaveTitle);
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
        SnackBar(
          content: Text(
            status == LeaveStatus.approved
                ? l10n.leaveApproved
                : l10n.leaveRejected,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdate('$e'))),
      );
    }
  }

  /// Approve dialog with a leave-type picker (pre-set to the requested type)
  /// and an optional note. Returns null when dismissed.
  Future<({LeaveType type, String note})?> _promptLeaveApproval(
    BuildContext context,
    LeaveType current,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var selected = current;
    return showDialog<({LeaveType type, String note})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.approveLeaveTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<LeaveType>(
              initialValue: current,
              decoration: InputDecoration(labelText: l10n.leaveType),
              items: [
                for (final t in LeaveType.values)
                  DropdownMenuItem(value: t, child: Text(_typeLabel(l10n, t))),
              ],
              onChanged: (t) {
                if (t != null) selected = t;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                hintText: l10n.decisionNoteHint,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              type: selected,
              note: controller.text.trim(),
            )),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );
  }
}
