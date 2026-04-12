import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/viewmodels/home_view_model.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final records = viewModel.attendanceRecords;
    final presentCount =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final lateCount =
        records.where((r) => r.status == AttendanceStatus.late).length;
    final absentCount =
        records.where((r) => r.status == AttendanceStatus.absent).length;

    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      value: '$presentCount',
                      label: 'Present',
                      color: kSuccess,
                      background: kSuccessLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$lateCount',
                      label: 'Late',
                      color: kWarning,
                      background: kWarningLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$absentCount',
                      label: 'Absent',
                      color: kError,
                      background: kErrorLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Attendance History'),
              const SizedBox(height: 12),
              ...records.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AttendanceListItem(record: r),
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
        'Attendance',
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
