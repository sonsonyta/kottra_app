import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/attendance_view_model.dart';
import '../../l10n/app_localizations.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key, required this.attendanceViewModel});

  final AttendanceViewModel attendanceViewModel;

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final records = widget.attendanceViewModel.attendanceRecords;
    
    final presentCount = records.where((r) => r.status == AttendanceStatus.present).length;
    final lateCount = records.where((r) => r.status == AttendanceStatus.late).length;
    final absentCount = records.where((r) => r.status == AttendanceStatus.absent).length;
    final leaveCount = records.where((r) => r.status == AttendanceStatus.leave).length;

    final selectedRecords = _selectedDay != null 
        ? widget.attendanceViewModel.getRecordsForDay(_selectedDay!)
        : <AttendanceRecord>[];

    return CustomScrollView(
      slivers: [
        _buildHeader(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      value: '$presentCount',
                      label: AppLocalizations.of(context)!.present,
                      color: c.success,
                      background: c.successLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$lateCount',
                      label: AppLocalizations.of(context)!.late,
                      color: c.warning,
                      background: c.warningLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$absentCount',
                      label: AppLocalizations.of(context)!.absent,
                      color: c.error,
                      background: c.errorLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      value: '$leaveCount',
                      label: AppLocalizations.of(context)!.leave,
                      color: c.primary,
                      background: c.infoLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCalendar(context),
              const SizedBox(height: 24),
              SectionHeader(title: AppLocalizations.of(context)!.attendanceHistory),
              const SizedBox(height: 12),
              if (selectedRecords.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No attendance records found for this day.',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ...selectedRecords.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AttendanceListItem(record: r),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final c = appColors(context);
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: TableCalendar<AttendanceRecord>(
        locale: Localizations.localeOf(context).toString(),
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) => widget.attendanceViewModel.getRecordsForDay(day),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: c.textPrimary),
          rightChevronIcon: Icon(Icons.chevron_right, color: c.textPrimary),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: c.infoLight,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(color: c.primary, fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(
            color: c.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          defaultTextStyle: TextStyle(color: c.textPrimary),
          weekendTextStyle: TextStyle(color: c.textSecondary),
          outsideTextStyle: TextStyle(color: c.textSecondary.withValues(alpha: 0.5)),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox();

            final status = events.first.status;
            Color markerColor;
            switch (status) {
              case AttendanceStatus.present:
                markerColor = c.success;
                break;
              case AttendanceStatus.late:
                markerColor = c.warning;
                break;
              case AttendanceStatus.absent:
                markerColor = c.error;
                break;
              case AttendanceStatus.leave:
              case AttendanceStatus.holiday:
              case AttendanceStatus.dayOff:
                markerColor = c.primary;
                break;
            }

            return Positioned(
              bottom: 8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: markerColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = appColors(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.primary,
      elevation: 0,
      title: Text(
        AppLocalizations.of(context)!.attendance,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primaryDark, c.primary],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
