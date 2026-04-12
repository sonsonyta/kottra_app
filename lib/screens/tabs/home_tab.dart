import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/viewmodels/home_view_model.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.viewModel, required this.now});

  final HomeViewModel viewModel;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _CheckInCard(viewModel: viewModel),
              const SizedBox(height: 20),
              _TodayStatsRow(viewModel: viewModel),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Recent Attendance'),
              const SizedBox(height: 12),
              ...viewModel.attendanceRecords.take(4).map(
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryDark, kPrimary],
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
                  TabAvatar(initials: viewModel.userInitials, size: 52),
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
  const _CheckInCard({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = viewModel.isCheckedIn;
    final checkInTime = viewModel.checkInTime;
    final checkOutTime = viewModel.checkOutTime;

    Duration? elapsed;
    if (isCheckedIn && checkInTime != null) {
      elapsed = DateTime.now().difference(checkInTime);
    } else if (!isCheckedIn && checkInTime != null && checkOutTime != null) {
      elapsed = checkOutTime.difference(checkInTime);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2E86DE),
            blurRadius: 24,
            offset: Offset(0, 8),
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
                  color: isCheckedIn ? kSuccessLight : kInfoLight,
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
                        color: isCheckedIn ? kSuccess : kTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCheckedIn ? 'Checked In' : 'Not Checked In',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCheckedIn ? kSuccess : kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (elapsed != null)
                Text(
                  fmtDuration(elapsed),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
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
                  iconColor: kSuccess,
                  icon: Icons.login_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE8EFF8),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _TimeDisplay(
                  label: 'Check Out',
                  time: fmtTime(checkOutTime),
                  iconColor: kError,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: isCheckedIn
                      ? [const Color(0xFFE74C3C), const Color(0xFFC0392B)]
                      : [kPrimary, kPrimaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCheckedIn ? kError : kPrimary).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: viewModel.isActionLoading
                    ? null
                    : isCheckedIn
                        ? viewModel.checkOut
                        : viewModel.checkIn,
                icon: viewModel.isActionLoading
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
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kTextPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: kTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({required this.viewModel});

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

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: '$presentCount',
            label: 'Present',
            color: kSuccess,
            background: kSuccessLight,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$lateCount',
            label: 'Late',
            color: kWarning,
            background: kWarningLight,
            icon: Icons.access_time_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '$absentCount',
            label: 'Absent',
            color: kError,
            background: kErrorLight,
            icon: Icons.cancel_outlined,
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
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
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: kPrimary),
        ],
      ),
    );
  }
}
