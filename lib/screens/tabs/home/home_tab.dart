
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/models/hr_settings.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/view_models/attendance_view_model.dart';
import 'package:kottra_app/view_models/main_view_model.dart';
import 'package:kottra_app/view_models/profile_view_model.dart';

import '../../../l10n/app_localizations.dart';
import 'check_in_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.viewModel,
    required this.attendanceViewModel,
    required this.profileViewModel,
    required this.now,
  });

  final MainViewModel viewModel;
  final AttendanceViewModel attendanceViewModel;
  final ProfileViewModel profileViewModel;
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
              if (FeatureFlags.enablePayroll) ...[
                _MonthDeductionCard(
                  viewModel: viewModel,
                  attendanceViewModel: attendanceViewModel,
                ),
                const SizedBox(height: 20),
              ],
              if (FeatureFlags.enableLeaveRequest ||
                  FeatureFlags.enablePayroll ||
                  FeatureFlags.enableSchedule) ...[
                _QuickActionsRow(
                  viewModel: viewModel,
                  profileViewModel: profileViewModel,
                ),
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
    final now = DateTime.now();
    final records = attendanceViewModel.attendanceRecords.where((r) {
      final d = r.date.toDate();
      return d.year == now.year && d.month == now.month;
    });
    // A late arrival still counts as showing up, so Present includes Late.
    final presentCount = records
        .where((r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.late)
        .length;
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

/// Compact "deductions this period" card on Home. Sourced from the live,
/// attendance-based preview ([AttendanceViewModel.periodDeductions]) — the same
/// estimate the Attendance tab shows — never from a payroll run. Tapping opens
/// the Attendance tab for the full breakdown.
class _MonthDeductionCard extends StatelessWidget {
  const _MonthDeductionCard({
    required this.viewModel,
    required this.attendanceViewModel,
  });

  final MainViewModel viewModel;
  final AttendanceViewModel attendanceViewModel;

  String _periodLabel(AppLocalizations l, PayPeriod p) {
    if (p.frequency == PayrollFrequency.monthly) return l.periodFullMonth;
    return p.isFirstHalf ? l.periodFirstHalf : l.periodSecondHalf;
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l = AppLocalizations.of(context)!;
    final b = attendanceViewModel.periodDeductions;
    if (b == null) return const SizedBox.shrink();

    final currency = b.currency.value;
    final has = b.hasDeductions;

    return InkWell(
      onTap: () => viewModel.setTabIndex(1), // Attendance tab (full breakdown)
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: c.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_circle_outline_rounded,
                color: c.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _periodLabel(l, b.period),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l.deductions,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.warningLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: c.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  has ? '-${fmtMoney(b.total, currency)}' : fmtMoney(0, currency),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: has ? c.error : c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap for details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
  const _QuickActionsRow({
    required this.viewModel,
    required this.profileViewModel,
  });

  final MainViewModel viewModel;
  final ProfileViewModel profileViewModel;

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
                  onTap: () =>
                      context.push('/leaves', extra: profileViewModel),
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
            if (FeatureFlags.enableSchedule) ...[
              if (FeatureFlags.enableLeaveRequest || FeatureFlags.enablePayroll)
                const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      context.push('/schedule', extra: profileViewModel),
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
                            color: c.holidayLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.event_available_outlined, color: c.holiday, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.scheduleTitle,
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

