import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/late_excuse_request.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class LateExcuseRequestsView extends StatelessWidget {
  const LateExcuseRequestsView({super.key, required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = dateLocale(context);
    if (viewModel.lateExcusesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.lateExcuses.isEmpty) {
      return EmptyState(
        icon: Icons.timer_off_rounded,
        message: l10n.noLateExcusesYet,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.lateExcuses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = viewModel.lateExcuses[i];
        final late = req.lateMinutes != null
            ? ' · ${l10n.minutesLate(req.lateMinutes!)}'
            : '';
        return RequestCard(
          title: req.employeeName.isNotEmpty
              ? req.employeeName
              : req.employeeId,
          subtitle: '${l10n.lateExcuseLabel}$late',
          dateLine: DateFormat('EEE, d MMM yyyy', locale).format(req.date),
          reason: req.reason,
          status: req.status.value,
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
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final reason = await promptDecision(
      context,
      status == LateExcuseStatus.approved
          ? l10n.approveLateExcuseTitle
          : l10n.rejectLateExcuseTitle,
    );
    if (reason == null) return;
    try {
      await viewModel.actionLateExcuse(req, status, reason: reason);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == LateExcuseStatus.approved
                ? l10n.lateExcuseApproved
                : l10n.lateExcuseRejected,
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
