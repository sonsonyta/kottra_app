import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/viewmodels/leave_view_model.dart';
import 'package:kottra_app/viewmodels/main_view_model.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key, required this.mainViewModel});

  final MainViewModel mainViewModel;

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  late final LeaveViewModel _leaveViewModel;

  @override
  void initState() {
    super.initState();
    _leaveViewModel = LeaveViewModel(
      storeId: widget.mainViewModel.storeId,
      employeeId: widget.mainViewModel.employeeId,
      employeeName: widget.mainViewModel.userName,
    );
  }

  @override
  void dispose() {
    _leaveViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: const Text(
          'My Leaves',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _leaveViewModel,
        builder: (context, _) {
          if (_leaveViewModel.leaves.isEmpty) {
            return const Center(child: Text('No leaves requested yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _leaveViewModel.leaves.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final leave = _leaveViewModel.leaves[index];
              return _LeaveCard(leave: leave);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.primary,
        onPressed: () {
          context.push('/leaves/request', extra: _leaveViewModel);
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Request Leave',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave});

  final LeaveRequest leave;

  Color _getStatusColor(BuildContext context, LeaveStatus status) {
    final c = appColors(context);
    switch (status) {
      case LeaveStatus.pending:
        return c.warning;
      case LeaveStatus.approved:
        return c.success;
      case LeaveStatus.rejected:
        return c.error;
    }
  }

  Color _getStatusBgColor(BuildContext context, LeaveStatus status) {
    final c = appColors(context);
    switch (status) {
      case LeaveStatus.pending:
        return c.warningLight;
      case LeaveStatus.approved:
        return c.successLight;
      case LeaveStatus.rejected:
        return c.errorLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final statusColor = _getStatusColor(context, leave.status);
    final statusBg = _getStatusBgColor(context, leave.status);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leave.type.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  leave.status.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${fmtDateShort(leave.startDate)}  -  ${fmtDateShort(leave.endDate)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (leave.reason.isNotEmpty) ...[
            Text(
              leave.reason,
              style: TextStyle(
                fontSize: 14,
                color: c.textPrimary,
              ),
            ),
          ],
          if (leave.createdAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Requested on ${fmtDateShort(leave.createdAt!)}',
              style: TextStyle(
                fontSize: 11,
                color: c.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
