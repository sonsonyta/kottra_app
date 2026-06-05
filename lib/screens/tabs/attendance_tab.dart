import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/viewmodels/attendance_view_model.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key, required this.attendanceViewModel});

  final AttendanceViewModel attendanceViewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final records = attendanceViewModel.attendanceRecords;
    final presentCount =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final lateCount =
        records.where((r) => r.status == AttendanceStatus.late).length;
    final absentCount =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final leaveCount =
        records.where((r) => r.status == AttendanceStatus.leave).length;

    return CustomScrollView(
      slivers: [
        _buildHeader(context),
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
                      color: c.success,
                      background: c.successLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$lateCount',
                      label: 'Late',
                      color: c.warning,
                      background: c.warningLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$absentCount',
                      label: 'Absent',
                      color: c.error,
                      background: c.errorLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$leaveCount',
                      label: 'Leave',
                      color: c.primary,
                      background: c.infoLight,
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

  Widget _buildHeader(BuildContext context) {
    final c = appColors(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.primary,
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
    final c = appColors(context);
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
