import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/salary_advance.dart';
import 'package:kottra_app/screens/tabs/approval_info.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/view_models/profile_view_model.dart';
import 'package:kottra_app/view_models/salary_advance_view_model.dart';

class AdvanceListScreen extends StatefulWidget {
  const AdvanceListScreen({super.key, required this.profileViewModel});

  final ProfileViewModel profileViewModel;

  @override
  State<AdvanceListScreen> createState() => _AdvanceListScreenState();
}

class _AdvanceListScreenState extends State<AdvanceListScreen> {
  late final SalaryAdvanceViewModel _advanceViewModel;

  @override
  void initState() {
    super.initState();
    _advanceViewModel = SalaryAdvanceViewModel(
      storeId: widget.profileViewModel.storeId,
      employeeId: widget.profileViewModel.employeeId,
      employeeName: widget.profileViewModel.userName,
      currency: widget.profileViewModel.currency,
    );
  }

  @override
  void dispose() {
    _advanceViewModel.dispose();
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
          l10n.myAdvances,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _advanceViewModel,
        builder: (context, _) {
          final currency = _advanceViewModel.currency.value;
          return Column(
            children: [
              _BalanceCard(
                balance: _advanceViewModel.outstandingBalance,
                currency: currency,
              ),
              Expanded(
                child: _advanceViewModel.advances.isEmpty
                    ? Center(child: Text(l10n.noAdvancesRequestedYet))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _advanceViewModel.advances.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _AdvanceCard(
                            advance: _advanceViewModel.advances[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.primary,
        onPressed: () {
          context.push('/advances/request', extra: _advanceViewModel);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n.requestAdvance,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.currency});

  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.primary,
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
          Text(
            l10n.outstandingAdvanceBalance,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fmtMoney(balance, currency),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvanceCard extends StatelessWidget {
  const _AdvanceCard({required this.advance});

  final SalaryAdvance advance;

  Color _statusColor(BuildContext context, AdvanceStatus status) {
    final c = appColors(context);
    switch (status) {
      case AdvanceStatus.pending:
        return c.warning;
      case AdvanceStatus.approved:
        return c.success;
      case AdvanceStatus.rejected:
        return c.error;
      case AdvanceStatus.deducted:
        return c.primary;
    }
  }

  Color _statusBg(BuildContext context, AdvanceStatus status) {
    final c = appColors(context);
    switch (status) {
      case AdvanceStatus.pending:
        return c.warningLight;
      case AdvanceStatus.approved:
        return c.successLight;
      case AdvanceStatus.rejected:
        return c.errorLight;
      case AdvanceStatus.deducted:
        return c.infoLight;
    }
  }

  String _statusLabel(BuildContext context, AdvanceStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case AdvanceStatus.pending:
        return l10n.statusPending;
      case AdvanceStatus.approved:
        return l10n.statusApproved;
      case AdvanceStatus.rejected:
        return l10n.statusRejected;
      case AdvanceStatus.deducted:
        return l10n.statusDeducted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final statusColor = _statusColor(context, advance.status);
    final statusBg = _statusBg(context, advance.status);

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
                fmtMoney(advance.amount, advance.currency.value),
                style: TextStyle(
                  fontSize: 18,
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
                  _statusLabel(context, advance.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (advance.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              advance.reason,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.requestedOnDate(
              DateFormat('E, d MMM', locale).format(advance.requestedAt),
            ),
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
          if (advance.status != AdvanceStatus.pending)
            ApprovalInfo(
              rejected: advance.status == AdvanceStatus.rejected,
              actionedBy: advance.actionedBy,
              actionedAt: advance.actionedAt,
              note: advance.actionReason,
            ),
        ],
      ),
    );
  }
}
