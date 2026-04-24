import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/viewmodels/main_view_model.dart';

class PayrollTab extends StatelessWidget {
  const PayrollTab({super.key, required this.viewModel});

  final MainViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final payslips = viewModel.payslips;
    final latest = payslips.isNotEmpty ? payslips.first : null;
    final history = payslips.skip(latest != null ? 1 : 0).toList();

    return CustomScrollView(
      slivers: [
        _buildHeader(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (latest != null) ...[
                _LatestPayslipCard(payslip: latest),
                const SizedBox(height: 24),
              ] else
                const _EmptyPayslipState(),
              if (history.isNotEmpty) ...[
                const SectionHeader(title: 'Payslip History'),
                const SizedBox(height: 12),
                ...history.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PayslipListItem(payslip: p),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = appColors(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.primary,
      elevation: 0,
      title: const Text(
        'Payroll',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primaryDark, c.primary],
          ),
        ),
      ),
    );
  }
}

class _LatestPayslipCard extends StatelessWidget {
  const _LatestPayslipCard({required this.payslip});

  final HRPayslip payslip;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final currency = payslip.currency.value;
    final isPaid = payslip.status == PayslipStatus.paid;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primaryDark, c.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadowStrong,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Latest Payslip',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  payslip.status.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Run #${payslip.payrollRunId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPaid && payslip.paidDate != null
                ? 'Paid on ${fmtDateFull(payslip.paidDate!)}'
                : 'Awaiting payment',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PayslipFigure(
                  label: 'Earnings',
                  value: fmtMoney(payslip.grossEarnings, currency),
                ),
              ),
              Expanded(
                child: _PayslipFigure(
                  label: 'Deductions',
                  value: fmtMoney(payslip.totalDeductions, currency),
                ),
              ),
              Expanded(
                child: _PayslipFigure(
                  label: 'Net Pay',
                  value: fmtMoney(payslip.netSalary, currency),
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          _BreakdownGroup(
            title: 'Earnings',
            rows: [
              _BreakdownRow(label: 'Basic salary', value: payslip.basicSalary),
              _BreakdownRow(label: 'Overtime', value: payslip.overtimePay),
              _BreakdownRow(label: 'Bonuses', value: payslip.bonuses),
              _BreakdownRow(label: 'Allowances', value: payslip.allowances),
            ],
            currency: currency,
          ),
          const SizedBox(height: 12),
          _BreakdownGroup(
            title: 'Deductions',
            rows: [
              _BreakdownRow(label: 'Tax', value: payslip.tax),
              _BreakdownRow(
                label: 'Leave deduction',
                value: payslip.leaveDeduction,
              ),
              _BreakdownRow(
                label: 'Other',
                value: payslip.otherDeductions,
              ),
            ],
            currency: currency,
          ),
        ],
      ),
    );
  }
}

class _BreakdownGroup extends StatelessWidget {
  const _BreakdownGroup({
    required this.title,
    required this.rows,
    required this.currency,
  });

  final String title;
  final List<_BreakdownRow> rows;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    fmtMoney(r.value, currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _BreakdownRow {
  const _BreakdownRow({required this.label, required this.value});
  final String label;
  final double value;
}

class _PayslipFigure extends StatelessWidget {
  const _PayslipFigure({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? Colors.white
                : Colors.white.withValues(alpha: 0.9),
            fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PayslipListItem extends StatelessWidget {
  const _PayslipListItem({required this.payslip});

  final HRPayslip payslip;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final isPaid = payslip.status == PayslipStatus.paid;
    final currency = payslip.currency.value;

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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.payments_rounded, color: c.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Run #${payslip.payrollRunId}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPaid && payslip.paidDate != null
                      ? fmtDateShort(payslip.paidDate!)
                      : 'Pending payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtMoney(payslip.netSalary, currency),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid ? c.successLight : c.warningLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  payslip.status.value,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPaid ? c.success : c.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPayslipState extends StatelessWidget {
  const _EmptyPayslipState();

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.infoLight,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.receipt_long_rounded,
              color: c.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No payslips yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your payslips will appear here once payroll runs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
