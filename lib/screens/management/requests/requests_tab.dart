import 'package:flutter/material.dart';
import 'package:kottra_app/config/feature_flags.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/screens/management/requests/advance_requests_view.dart';
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
    final l10n = AppLocalizations.of(context)!;
    const showAdvances = FeatureFlags.enableSalaryAdvance;
    return DefaultTabController(
      length: showAdvances ? 3 : 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: managementAppBar(
          context,
          l10n.requests,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            dividerColor: Colors.transparent,
            tabs: [
              TabWithBadge(
                label: l10n.leave,
                count: viewModel.pendingLeaveCount,
                color: c,
              ),
              TabWithBadge(
                label: l10n.late,
                count: viewModel.pendingLateExcuseCount,
                color: c,
              ),
              if (showAdvances)
                TabWithBadge(
                  label: l10n.advance,
                  count: viewModel.pendingAdvanceCount,
                  color: c,
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LeaveRequestsView(viewModel: viewModel),
            LateExcuseRequestsView(viewModel: viewModel),
            if (showAdvances) AdvanceRequestsView(viewModel: viewModel),
          ],
        ),
      ),
    );
  }
}
