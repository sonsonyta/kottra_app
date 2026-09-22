import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/late_excuse_request.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/screens/tabs/settings_sections.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

/// Management "app" for one store, shown after the manager/owner picks a store.
/// It deliberately reuses the employee UI's look — a bottom-nav shell with the
/// same cards and colors — but there is no check-in/out and none of the
/// employee self-service actions (request leave/advance/late, payslips). The
/// tabs are Home, Attendance, Requests (leave + late approvals) and Profile.
class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({
    super.key,
    required this.membership,
    this.onSwitchStore,
    this.onLogout,
  });

  final StoreMembership membership;

  /// Shown as a "switch store" action when the user manages more than one store.
  final VoidCallback? onSwitchStore;

  /// Shown as a logout action. Provided when this dashboard is the home screen.
  final VoidCallback? onLogout;

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  late final StoreManagementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StoreManagementViewModel(membership: widget.membership);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: c.background,
          body: IndexedStack(
            index: _viewModel.navIndex,
            children: [
              _HomePage(
                viewModel: _viewModel,
                onSwitchStore: widget.onSwitchStore,
              ),
              _AttendanceTab(viewModel: _viewModel),
              _RequestsPage(viewModel: _viewModel),
              _ProfilePage(
                viewModel: _viewModel,
                onSwitchStore: widget.onSwitchStore,
                onLogout: widget.onLogout,
              ),
            ],
          ),
          bottomNavigationBar: _ManagerBottomNav(
            currentIndex: _viewModel.navIndex,
            onTap: _viewModel.setNavIndex,
            pendingRequests: _viewModel.pendingLeaveCount +
                _viewModel.pendingLateExcuseCount,
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Home
// ════════════════════════════════════════════════════════════════════════════

/// Two-letter initials from a name, for avatar fallbacks.
String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.viewModel, this.onSwitchStore});

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
    return CustomScrollView(
      slivers: [
        _buildHeader(context, c),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
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
                            const Icon(Icons.storefront_rounded,
                                color: Colors.white70, size: 14),
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
                          DateFormat('EEEE, d MMMM yyyy')
                              .format(DateTime.now()),
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
                    initials: _initialsFor(viewModel.managerName),
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
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 13, color: color.textSecondary)),
                  ],
                ),
              ),
              if (badge > 0) _Badge(count: badge, color: color),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: color.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Attendance
// ════════════════════════════════════════════════════════════════════════════

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.viewModel});

  final StoreManagementViewModel viewModel;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) viewModel.setSelectedDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final isToday = DateUtils.isSameDay(viewModel.selectedDate, DateTime.now());
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          Container(
            color: c.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => viewModel.setSelectedDate(
                    viewModel.selectedDate.subtract(const Duration(days: 1)),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEE, d MMM yyyy')
                                .format(viewModel.selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          if (isToday)
                            Text('Today',
                                style: TextStyle(
                                    fontSize: 11, color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isToday
                      ? null
                      : () => viewModel.setSelectedDate(
                            viewModel.selectedDate.add(const Duration(days: 1)),
                          ),
                ),
              ],
            ),
          ),
          Expanded(
            child: viewModel.attendanceLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.attendance.isEmpty
                    ? _EmptyState(
                        icon: Icons.event_busy_rounded,
                        message: 'No attendance records for this day.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: viewModel.attendance.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _AttendanceCard(record: viewModel.attendance[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final timeFmt = DateFormat('HH:mm');
    final inTime = record.checkIn != null ? timeFmt.format(record.checkIn!) : '—';
    final outTime =
        record.checkOut != null ? timeFmt.format(record.checkOut!) : '—';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.employeeName.isNotEmpty
                      ? record.employeeName
                      : record.employeeId,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.login_rounded, size: 14, color: c.textSecondary),
                    const SizedBox(width: 4),
                    Text(inTime, style: TextStyle(color: c.textSecondary)),
                    const SizedBox(width: 14),
                    Icon(Icons.logout_rounded,
                        size: 14, color: c.textSecondary),
                    const SizedBox(width: 4),
                    Text(outTime, style: TextStyle(color: c.textSecondary)),
                  ],
                ),
                if (record.lateMinutes > 0 && !record.lateExcused) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${record.lateMinutes} min late',
                    style: TextStyle(fontSize: 12, color: c.warning),
                  ),
                ],
                if (record.lateExcused) ...[
                  const SizedBox(height: 4),
                  Text('Late excused',
                      style: TextStyle(fontSize: 12, color: c.textSecondary)),
                ],
              ],
            ),
          ),
          _StatusChip(label: record.status.value, color: c),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Requests (Leave + Late)
// ════════════════════════════════════════════════════════════════════════════

class _RequestsPage extends StatelessWidget {
  const _RequestsPage({required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            TabBar(
              labelColor: c.primary,
              unselectedLabelColor: c.textSecondary,
              indicatorColor: c.primary,
              tabs: [
                _TabWithBadge(
                    label: 'Leave',
                    count: viewModel.pendingLeaveCount,
                    color: c),
                _TabWithBadge(
                    label: 'Late',
                    count: viewModel.pendingLateExcuseCount,
                    color: c),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LeaveTab(viewModel: viewModel),
                  _LateExcuseTab(viewModel: viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveTab extends StatelessWidget {
  const _LeaveTab({required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.leavesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.leaves.isEmpty) {
      return _EmptyState(
        icon: Icons.beach_access_rounded,
        message: 'No leave requests yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.leaves.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = viewModel.leaves[i];
        return _RequestCard(
          title: req.employeeName.isNotEmpty ? req.employeeName : req.employeeId,
          subtitle: req.type.value,
          dateLine:
              '${DateFormat('d MMM').format(req.startDate)} – ${DateFormat('d MMM yyyy').format(req.endDate)}',
          reason: req.reason,
          statusLabel: req.status.value,
          isPending: req.status == LeaveStatus.pending,
          onApprove: () => _action(context, req, LeaveStatus.approved),
          onReject: () => _action(context, req, LeaveStatus.rejected),
        );
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    LeaveRequest req,
    LeaveStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await _promptDecision(context,
        status == LeaveStatus.approved ? 'Approve leave?' : 'Reject leave?');
    if (reason == null) return;
    try {
      await viewModel.actionLeave(req, status, reason: reason);
      messenger.showSnackBar(
          SnackBar(content: Text('Leave ${status.value.toLowerCase()}.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}

class _LateExcuseTab extends StatelessWidget {
  const _LateExcuseTab({required this.viewModel});

  final StoreManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.lateExcusesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.lateExcuses.isEmpty) {
      return _EmptyState(
        icon: Icons.timer_off_rounded,
        message: 'No late-excuse requests yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.lateExcuses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = viewModel.lateExcuses[i];
        final late =
            req.lateMinutes != null ? ' · ${req.lateMinutes} min late' : '';
        return _RequestCard(
          title: req.employeeName.isNotEmpty ? req.employeeName : req.employeeId,
          subtitle: 'Late excuse$late',
          dateLine: DateFormat('EEE, d MMM yyyy').format(req.date),
          reason: req.reason,
          statusLabel: req.status.value,
          isPending: req.status == LateExcuseStatus.pending,
          onApprove: () => _action(context, req, LateExcuseStatus.approved),
          onReject: () => _action(context, req, LateExcuseStatus.rejected),
        );
      },
    );
  }

  Future<void> _action(
    BuildContext context,
    LateExcuseRequest req,
    LateExcuseStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await _promptDecision(
        context,
        status == LateExcuseStatus.approved
            ? 'Approve late excuse?'
            : 'Reject late excuse?');
    if (reason == null) return;
    try {
      await viewModel.actionLateExcuse(req, status, reason: reason);
      messenger.showSnackBar(SnackBar(
          content: Text('Late excuse ${status.value.toLowerCase()}.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Profile
// ════════════════════════════════════════════════════════════════════════════

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.viewModel,
    this.onSwitchStore,
    this.onLogout,
  });

  final StoreManagementViewModel viewModel;
  final VoidCallback? onSwitchStore;
  final VoidCallback? onLogout;

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: viewModel.managerName);
    final messenger = ScaffoldMessenger.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await viewModel.updateDisplayName(newName);
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }

  Future<void> _editPhoto(BuildContext context) async {
    if (viewModel.isUploadingPhoto) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    try {
      await viewModel.updateProfilePhoto(bytes);
      messenger
          .showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Could not upload photo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          // ── Profile update ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _EditableAvatar(
                      photoUrl: viewModel.photoUrl,
                      photoBytes: viewModel.photoBytes,
                      initials: _initialsFor(viewModel.managerName),
                      isUploading: viewModel.isUploadingPhoto,
                      color: c,
                      onTap: () => _editPhoto(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.managerName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          if (viewModel.managerEmail.isNotEmpty)
                            Text(
                              viewModel.managerEmail,
                              style: TextStyle(
                                  fontSize: 13, color: c.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: c.primary),
                      tooltip: 'Update profile',
                      onPressed: () => _editName(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                    label: 'Store',
                    value: viewModel.storeName ?? viewModel.storeId,
                    color: c),
                const SizedBox(height: 12),
                _InfoRow(label: 'Role', value: viewModel.roleLabel, color: c),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Notifications ──
          SettingsCard(
            title: 'Notifications',
            icon: Icons.notifications_active_outlined,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Employee requests',
                style: TextStyle(fontSize: 14, color: c.textPrimary),
              ),
              subtitle: Text(
                'Get notified when employees submit leave or late-excuse requests',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              activeThumbColor: c.primary,
              value: viewModel.requestNotificationsEnabled,
              onChanged: viewModel.toggleRequestNotifications,
            ),
          ),
          const SizedBox(height: 16),
          // ── Appearance ──
          const AppearanceSettingSection(),
          const SizedBox(height: 16),
          // ── Language ──
          const LanguageSettingSection(),
          const SizedBox(height: 20),
          if (onSwitchStore != null)
            _ProfileTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Switch store',
              color: c,
              onTap: onSwitchStore!,
            ),
          if (onLogout != null) ...[
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: c,
              destructive: true,
              onTap: onLogout!,
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.photoUrl,
    required this.photoBytes,
    required this.initials,
    required this.isUploading,
    required this.color,
    required this.onTap,
  });

  final String? photoUrl;
  final Uint8List? photoBytes;
  final String initials;
  final bool isUploading;
  final AppColors color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = (photoBytes != null && photoBytes!.isNotEmpty)
        ? MemoryImage(photoBytes!)
        : (photoUrl != null && photoUrl!.isNotEmpty)
            ? NetworkImage(photoUrl!)
            : null;
    final hasPhoto = image != null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.primary.withValues(alpha: 0.12),
              backgroundImage: image,
              child: hasPhoto
                  ? null
                  : Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color.primary,
                      ),
                    ),
            ),
            if (isUploading)
              const Positioned.fill(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black45,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: color.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final AppColors color;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? color.error : color.textPrimary;
    return Material(
      color: color.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════════════════════════════════

/// Confirmation dialog with an optional note. Returns the (possibly empty)
/// note when confirmed, or null when dismissed.
Future<String?> _promptDecision(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'Reason shown to the employee',
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

class SectionHeaderText extends StatelessWidget {
  const SectionHeaderText({super.key, required this.text, required this.color});

  final String text;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color.textPrimary,
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.title,
    required this.subtitle,
    required this.dateLine,
    required this.reason,
    required this.statusLabel,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
  });

  final String title;
  final String subtitle;
  final String dateLine;
  final String reason;
  final String statusLabel;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 13, color: c.textSecondary)),
                  ],
                ),
              ),
              _StatusChip(label: statusLabel, color: c),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: c.textSecondary),
              const SizedBox(width: 6),
              Text(dateLine, style: TextStyle(color: c.textSecondary)),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reason, style: TextStyle(fontSize: 14, color: c.textPrimary)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: c.error),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    Color fg;
    if (lower == 'approved' || lower == 'present') {
      fg = color.success;
    } else if (lower == 'rejected' || lower == 'absent') {
      fg = color.error;
    } else if (lower == 'pending' || lower == 'late') {
      fg = color.warning;
    } else {
      fg = color.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            _Badge(count: count, color: color),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.color});

  final int count;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: c.textSecondary),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Bottom navigation (mirrors the employee MainScreen nav)
// ════════════════════════════════════════════════════════════════════════════

class _ManagerBottomNav extends StatelessWidget {
  const _ManagerBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.pendingRequests,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: 'Attendance',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.inbox_outlined,
                activeIcon: Icons.inbox_rounded,
                label: 'Requests',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
                badge: pendingRequests,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final isActive = index == currentIndex;
    final activeColor = c.primary;
    final inactiveColor = c.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    color: isActive ? activeColor : inactiveColor,
                    size: 24,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: _Badge(count: badge, color: c),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
