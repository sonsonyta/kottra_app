import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/viewmodels/attendance_view_model.dart';
import 'package:kottra_app/viewmodels/main_view_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _CheckInCard(
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
              const SectionHeader(title: 'Recent Attendance'),
              const SizedBox(height: 12),
              ...attendanceViewModel.attendanceRecords.take(4).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AttendanceListItem(record: r),
                    ),
                  ),
              const SizedBox(height: 8),
              _ViewAllButton(
                label: 'View all attendance',
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
                          greeting(),
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
                          fmtDateFull(DateTime.now()),
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

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.viewModel, required this.attendanceViewModel});

  final MainViewModel viewModel;
  final AttendanceViewModel attendanceViewModel;

  String _formatCheckInError(Object error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? 'Check-in failed.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<String?> _promptForNote(BuildContext context, String action) async {
    final c = appColors(context);
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(action, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add a note if you are ${action == "Check In" ? "checking in late" : "checking out early"}.', style: TextStyle(color: c.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Note (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: c.surface,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // returns null, meaning cancel
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(textController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    final note = await _promptForNote(context, 'Check In');
    if (note == null) return; // User cancelled

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await attendanceViewModel.checkIn(lateCheckInNote: note.isEmpty ? null : note);
      if (result == null) return;
      final String message;
      if (result.alreadyCheckedIn) {
        message = 'You\'re already checked in today.';
      } else if (result.success) {
        message = 'Checked in — ${result.status.value}';
      } else {
        message = 'Check-in failed. Please try again.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_formatCheckInError(error))),
      );
    }
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    final note = await _promptForNote(context, 'Check Out');
    if (note == null) return; // User cancelled

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await attendanceViewModel.checkOut(earlyCheckOutNote: note.isEmpty ? null : note);
      if (result == null) return;
      final String message;
      if (result.alreadyCheckedOut) {
        message = 'You\'re already checked out today.';
      } else if (result.success) {
        message = 'Checked out successful';
      } else {
        message = 'Check-out failed. Please try again.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_formatCheckInError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final isCheckedIn = attendanceViewModel.isCheckedIn;
    final checkInTime = attendanceViewModel.checkInTime;
    final checkOutTime = attendanceViewModel.checkOutTime;

    Duration? elapsed;
    if (isCheckedIn && checkInTime != null) {
      elapsed = DateTime.now().difference(checkInTime);
    } else if (!isCheckedIn && checkInTime != null && checkOutTime != null) {
      elapsed = checkOutTime.difference(checkInTime);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: attendanceViewModel.isOnLeave
                      ? c.warningLight
                      : (isCheckedIn ? c.successLight : c.infoLight),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: attendanceViewModel.isOnLeave
                            ? c.warning
                            : (isCheckedIn ? c.success : c.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      attendanceViewModel.isOnLeave
                          ? 'On Leave'
                          : (isCheckedIn ? 'Checked In' : 'Not Checked In'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: attendanceViewModel.isOnLeave
                            ? c.warning
                            : (isCheckedIn ? c.success : c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (elapsed != null)
                Text(
                  fmtDuration(elapsed),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeDisplay(
                  label: 'Check In',
                  time: fmtTime(checkInTime),
                  iconColor: c.success,
                  icon: Icons.login_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: c.divider,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _TimeDisplay(
                  label: 'Check Out',
                  time: fmtTime(checkOutTime),
                  iconColor: c.error,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (attendanceViewModel.isOnLeave)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.infoLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'You are on leave today${attendanceViewModel.todayRecord?.leaveType != null ? ' (${attendanceViewModel.todayRecord!.leaveType!.value})' : ''}.',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: isCheckedIn
                        ? [c.error, const Color(0xFFC0392B)]
                        : [c.primary, c.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isCheckedIn ? c.error : c.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                  child: ElevatedButton.icon(
                  onPressed: attendanceViewModel.isActionLoading
                      ? null
                      : isCheckedIn
                          ? () => _handleCheckOut(context)
                          : () => _handleCheckIn(context),
                  icon: attendanceViewModel.isActionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
                          size: 20,
                        ),
                  label: Text(isCheckedIn ? 'Check Out' : 'Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({
    required this.label,
    required this.time,
    required this.iconColor,
    required this.icon,
  });

  final String label;
  final String time;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
            label: 'Present',
            color: c.success,
            background: c.successLight,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$lateCount',
            label: 'Late',
            color: c.warning,
            background: c.warningLight,
            icon: Icons.access_time_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$absentCount',
            label: 'Absent',
            color: c.error,
            background: c.errorLight,
            icon: Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$leaveCount',
            label: 'Leave',
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
        const SectionHeader(title: 'Quick Actions'),
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
                        'Request Leave',
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
                          'My Payslips',
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
