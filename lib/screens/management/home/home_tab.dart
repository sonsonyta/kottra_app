import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/screens/tabs/home/check_in_card.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class ManagementHomeTab extends StatelessWidget {
  const ManagementHomeTab({
    super.key,
    required this.viewModel,
    this.onSwitchStore,
  });

  final StoreManagementViewModel viewModel;
  final VoidCallback? onSwitchStore;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final selfAttendance = viewModel.selfAttendance;
    return CustomScrollView(
      slivers: [
        _buildHeader(context, c),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // The manager's own check-in/out, when their account is linked
              // to an employee record in this store.
              if (selfAttendance != null) ...[
                ListenableBuilder(
                  listenable: selfAttendance,
                  builder: (context, _) =>
                      CheckInCard(attendanceViewModel: selfAttendance),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                DateFormat('EEE, d MMM yyyy').format(viewModel.selectedDate),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _SummaryStatRow(viewModel: viewModel),
              const SizedBox(height: 24),
              SectionHeaderText(text: 'Manage', color: c),
              const SizedBox(height: 12),
              _ManageActionCard(
                icon: Icons.beach_access_rounded,
                iconColor: c.primary,
                iconBackground: c.infoLight,
                title: 'Leave requests',
                subtitle: 'Review and approve time off',
                badge: viewModel.pendingLeaveCount,
                color: c,
                onTap: () => viewModel.setNavIndex(2),
              ),
              const SizedBox(height: 12),
              _ManageActionCard(
                icon: Icons.schedule_rounded,
                iconColor: c.warning,
                iconBackground: c.warningLight,
                title: 'Late excuses',
                subtitle: 'Review late-arrival excuses',
                badge: viewModel.pendingLateExcuseCount,
                color: c,
                onTap: () => viewModel.setNavIndex(2),
              ),
              if (FeatureFlags.enableSalaryAdvance) ...[
                const SizedBox(height: 12),
                _ManageActionCard(
                  icon: Icons.payments_rounded,
                  iconColor: c.success,
                  iconBackground: c.successLight,
                  title: 'Salary advances',
                  subtitle: 'Review advance requests',
                  badge: viewModel.pendingAdvanceCount,
                  color: c,
                  onTap: () => viewModel.setNavIndex(2),
                ),
              ],
              const SizedBox(height: 12),
              _ManageActionCard(
                icon: Icons.calendar_month_rounded,
                iconColor: c.success,
                iconBackground: c.successLight,
                title: 'Attendance',
                subtitle: 'See who\'s in today',
                color: c,
                onTap: () => viewModel.setNavIndex(1),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  /// Gradient header mirroring the employee Home tab: store name, greeting,
  /// user name, date and avatar, with a switch-store action.
  Widget _buildHeader(BuildContext context, AppColors c) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: c.primary,
      actions: [
        if (onSwitchStore != null)
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            tooltip: 'Switch store',
            onPressed: onSwitchStore,
          ),
      ],
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                viewModel.storeName ?? viewModel.storeId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.managerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                          ).format(DateTime.now()),
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
                    initials: initialsFor(viewModel.managerName),
                    imageUrl: viewModel.photoUrl,
                    imageBytes: viewModel.photoBytes,
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

class _SummaryStatRow extends StatelessWidget {
  const _SummaryStatRow({required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    if (viewModel.attendanceLoading) {
      return const SizedBox(
        height: 74,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: '${viewModel.presentCount}',
            label: 'Present',
            color: c.success,
            background: c.successLight,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '${viewModel.lateCount}',
            label: 'Late',
            color: c.warning,
            background: c.warningLight,
            icon: Icons.access_time_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '${viewModel.absentCount}',
            label: 'Absent',
            color: c.error,
            background: c.errorLight,
            icon: Icons.cancel_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: '${viewModel.leaveCount}',
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _ManageActionCard extends StatelessWidget {
  const _ManageActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final AppColors color;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: color.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge > 0) CountBadge(count: badge, color: color),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: color.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
