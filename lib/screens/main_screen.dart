import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/screens/tabs/attendance_tab.dart';
import 'package:kottra_app/screens/tabs/home_tab.dart';
import 'package:kottra_app/screens/tabs/payroll_tab.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/screens/tabs/profile_tab.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/viewmodels/attendance_view_model.dart';
import 'package:kottra_app/viewmodels/main_view_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainViewModel _viewModel;
  late final AttendanceViewModel _attendanceViewModel;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _viewModel = MainViewModel();
    _attendanceViewModel = AttendanceViewModel();
    _startClock();

  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _viewModel.dispose();
    _attendanceViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _attendanceViewModel]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: c.background,
          body: IndexedStack(
            index: _viewModel.currentTabIndex,
            children: [
              HomeTab(
                viewModel: _viewModel,
                attendanceViewModel: _attendanceViewModel,
                now: _now,
              ),
              AttendanceTab(attendanceViewModel: _attendanceViewModel),
              if (FeatureFlags.enablePayroll) PayrollTab(viewModel: _viewModel),
              ProfileTab(viewModel: _viewModel, onLogout: _handleLogout),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: _viewModel.currentTabIndex,
            onTap: _viewModel.setTabIndex,
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await _viewModel.logout();
    if (!mounted) return;
    context.go('/login');
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Bottom Navigation
// ════════════════════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

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
              if (FeatureFlags.enablePayroll)
                _NavItem(
                  icon: Icons.payments_outlined,
                  activeIcon: Icons.payments_rounded,
                  label: 'Payroll',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: FeatureFlags.enablePayroll ? 3 : 2,
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
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
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
