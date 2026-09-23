import 'package:flutter/material.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/screens/management/requests/late_excuse_requests_view.dart';
import 'package:kottra_app/screens/management/requests/leave_requests_view.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class ManagementRequestsTab extends StatelessWidget {
  const ManagementRequestsTab({super.key, required this.viewModel});

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
                TabWithBadge(
                  label: 'Leave',
                  count: viewModel.pendingLeaveCount,
                  color: c,
                ),
                TabWithBadge(
                  label: 'Late',
                  count: viewModel.pendingLateExcuseCount,
                  color: c,
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  LeaveRequestsView(viewModel: viewModel),
                  LateExcuseRequestsView(viewModel: viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
