import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/early_leave_request.dart';
import 'package:kottra_app/screens/tabs/approval_info.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/early_leave_view_model.dart';
import 'package:kottra_app/view_models/profile_view_model.dart';

class EarlyLeaveListScreen extends StatefulWidget {
  const EarlyLeaveListScreen({super.key, required this.profileViewModel});

  final ProfileViewModel profileViewModel;

  @override
  State<EarlyLeaveListScreen> createState() => _EarlyLeaveListScreenState();
}

class _EarlyLeaveListScreenState extends State<EarlyLeaveListScreen> {
  late final EarlyLeaveViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EarlyLeaveViewModel(
      storeId: widget.profileViewModel.storeId,
      employeeId: widget.profileViewModel.employeeId,
      employeeName: widget.profileViewModel.userName,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: Text(
          l10n.earlyLeaveTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return _viewModel.requests.isEmpty
              ? Center(child: Text(l10n.noEarlyLeaveYet))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _viewModel.requests.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _RequestCard(request: _viewModel.requests[index]);
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.primary,
        onPressed: () {
          context.push('/early-leave/request', extra: _viewModel);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n.requestEarlyLeave,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final EarlyLeaveRequest request;

  Color _statusColor(BuildContext context, EarlyLeaveStatus status) {
    final c = appColors(context);
    switch (status) {
      case EarlyLeaveStatus.pending:
        return c.warning;
      case EarlyLeaveStatus.approved:
        return c.success;
      case EarlyLeaveStatus.rejected:
        return c.error;
    }
  }

  Color _statusBg(BuildContext context, EarlyLeaveStatus status) {
    final c = appColors(context);
    switch (status) {
      case EarlyLeaveStatus.pending:
        return c.warningLight;
      case EarlyLeaveStatus.approved:
        return c.successLight;
      case EarlyLeaveStatus.rejected:
        return c.errorLight;
    }
  }

  String _statusLabel(BuildContext context, EarlyLeaveStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case EarlyLeaveStatus.pending:
        return l10n.statusPending;
      case EarlyLeaveStatus.approved:
        return l10n.statusApproved;
      case EarlyLeaveStatus.rejected:
        return l10n.statusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final statusColor = _statusColor(context, request.status);
    final statusBg = _statusBg(context, request.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.shadowSubtle,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('E, d MMM', locale).format(request.date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(context, request.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.leaveAtTime(request.leaveTime),
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              request.reason,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.requestedOnDate(
              DateFormat('E, d MMM', locale).format(request.requestedAt),
            ),
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
          if (request.status != EarlyLeaveStatus.pending)
            ApprovalInfo(
              rejected: request.status == EarlyLeaveStatus.rejected,
              actionedBy: request.actionedBy,
              actionedAt: request.actionedAt,
              note: request.actionReason,
            ),
        ],
      ),
    );
  }
}
