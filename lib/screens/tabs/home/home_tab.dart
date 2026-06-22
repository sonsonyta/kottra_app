
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/attendance_view_model.dart';
import 'package:kottra_app/view_models/main_view_model.dart';

import '../../../l10n/app_localizations.dart';
import 'check_in_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.viewModel,
    required this.attendanceViewModel,
    required this.now,
  });

  final MainViewModel viewModel;
  final AttendanceViewModel attendanceViewModel;
  final DateTime now;

  String _getGreeting(BuildContext context) {
    final h = DateTime.now().hour;
    if (h < 12) return AppLocalizations.of(context)!.goodMorning;
    if (h < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              CheckInCard(
                viewModel: viewModel,
                attendanceViewModel: attendanceViewModel,
              ),
              const SizedBox(height: 20),
              _TodayStatsRow(attendanceViewModel: attendanceViewModel),
              const SizedBox(height: 20),
              if (FeatureFlags.enableLeaveRequest || FeatureFlags.enablePayroll) ...[
                _QuickActionsRow(viewModel: viewModel),
                const SizedBox(height: 24),
              ],
              SectionHeader(title: AppLocalizations.of(context)!.recentAttendance),
              const SizedBox(height: 12),
              ...attendanceViewModel.attendanceRecords.take(4).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AttendanceListItem(record: r),
                    ),
                  ),
              const SizedBox(height: 8),
              _ViewAllButton(
                label: AppLocalizations.of(context)!.viewAllAttendance,
                onTap: () => viewModel.setTabIndex(1),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final c = appColors(context);
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: c.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primaryDark, c.primary],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getGreeting(context),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat.yMMMMEEEEd(AppLocalizations.of(context)!.localeName).format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TabAvatar(
                    initials: viewModel.userInitials,
                    imageUrl: viewModel.profileImageUrl,
                    size: 52,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}





class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({required this.attendanceViewModel});

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

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: '$presentCount',
            label: AppLocalizations.of(context)!.present,
            color: c.success,
            background: c.successLight,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$lateCount',
            label: AppLocalizations.of(context)!.late,
            color: c.warning,
            background: c.warningLight,
            icon: Icons.access_time_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$absentCount',
            label: AppLocalizations.of(context)!.absent,
            color: c.error,
            background: c.errorLight,
            icon: Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$leaveCount',
            label: AppLocalizations.of(context)!.leave,
            color: c.primary,
            background: c.infoLight,
            icon: Icons.calendar_today_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 16, color: c.primary),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.viewModel});

  final MainViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: AppLocalizations.of(context)!.quickActions),
        const SizedBox(height: 12),
        Row(
          children: [
            if (FeatureFlags.enableLeaveRequest)
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/leaves', extra: viewModel),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.divider),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.infoLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_month_outlined, color: c.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.requestLeave,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (FeatureFlags.enablePayroll) ...[
              if (FeatureFlags.enableLeaveRequest) const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => viewModel.setTabIndex(2), // Payroll tab
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.divider),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.successLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long_outlined, color: c.success, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.myPayslips,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

