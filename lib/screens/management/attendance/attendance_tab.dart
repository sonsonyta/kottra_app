import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class ManagementAttendanceTab extends StatelessWidget {
  const ManagementAttendanceTab({super.key, required this.viewModel});

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
                            DateFormat(
                              'EEE, d MMM yyyy',
                            ).format(viewModel.selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          if (isToday)
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textSecondary,
                              ),
                            ),
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
                ? EmptyState(
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
    final inTime = record.checkIn != null
        ? timeFmt.format(record.checkIn!)
        : '—';
    final outTime = record.checkOut != null
        ? timeFmt.format(record.checkOut!)
        : '—';
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
                    Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: c.textSecondary,
                    ),
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
                  Text(
                    'Late excused',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          StatusChip(label: record.status.value, color: c),
        ],
      ),
    );
  }
}
