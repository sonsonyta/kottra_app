import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/viewmodels/home_view_model.dart';

class PayrollTab extends StatelessWidget {
  const PayrollTab({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final records = viewModel.payrollRecords;
    final latest = records.isNotEmpty ? records.first : null;

    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (latest != null) ...[
                _LatestPayrollCard(record: latest),
                const SizedBox(height: 24),
              ],
              const SectionHeader(title: 'Payroll History'),
              const SizedBox(height: 12),
              ...records.skip(latest != null ? 1 : 0).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PayrollListItem(record: r),
                    ),
                  ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: kPrimary,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryDark, kPrimary],
          ),
        ),
      ),
    );
  }
}

class _LatestPayrollCard extends StatelessWidget {
  const _LatestPayrollCard({required this.record});

  final PayrollRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E86DE),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Latest Payroll',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.status == 'paid' ? 'Paid' : 'Pending',
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
            record.month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PayrollFigure(
                  label: 'Base Salary',
                  value: '\$${record.baseSalary.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _PayrollFigure(
                  label: 'Deductions',
                  value: '\$${record.deductions.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _PayrollFigure(
                  label: 'Net Pay',
                  value: '\$${record.netPay.toStringAsFixed(0)}',
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayrollFigure extends StatelessWidget {
  const _PayrollFigure({
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
            color: highlight ? Colors.white : Colors.white.withValues(alpha: 0.9),
            fontSize: highlight ? 20 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PayrollListItem extends StatelessWidget {
  const _PayrollListItem({required this.record});

  final PayrollRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2E86DE),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kInfoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.payments_rounded, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.month,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Base: \$${record.baseSalary.toStringAsFixed(0)}  •  Deduct: \$${record.deductions.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextSecondary,
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
                '\$${record.netPay.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: record.status == 'paid' ? kSuccessLight : kWarningLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.status == 'paid' ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: record.status == 'paid' ? kSuccess : kWarning,
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
