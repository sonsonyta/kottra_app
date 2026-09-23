import 'package:flutter/material.dart';
import 'package:kottra_app/screens/management/attendance/attendance_tab.dart';
import 'package:kottra_app/screens/management/home/home_tab.dart';
import 'package:kottra_app/screens/management/management_bottom_nav.dart';
import 'package:kottra_app/screens/management/profile/profile_tab.dart';
import 'package:kottra_app/screens/management/requests/requests_tab.dart';
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
              ManagementHomeTab(
                viewModel: _viewModel,
                onSwitchStore: widget.onSwitchStore,
              ),
              ManagementAttendanceTab(viewModel: _viewModel),
              ManagementRequestsTab(viewModel: _viewModel),
              ManagementProfileTab(
                viewModel: _viewModel,
                onSwitchStore: widget.onSwitchStore,
                onLogout: widget.onLogout,
              ),
            ],
          ),
          bottomNavigationBar: ManagementBottomNav(
            currentIndex: _viewModel.navIndex,
            onTap: _viewModel.setNavIndex,
            pendingRequests:
                _viewModel.pendingLeaveCount +
                _viewModel.pendingLateExcuseCount,
          ),
        );
      },
    );
  }
}
