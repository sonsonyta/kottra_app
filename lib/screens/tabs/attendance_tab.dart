import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/models/hr_settings.dart';
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
    final records = widget.attendanceViewModel.attendanceRecords.where((r) {
      final d = r.date.toDate();
      return d.year == _focusedDay.year && d.month == _focusedDay.month;
    });

    // A late arrival still counts as showing up, so Present includes Late.
    final presentCount = records
        .where((r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.late)
        .length;
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
              if (widget.attendanceViewModel.periodDeductions?.hasDeductions ??
                  false) ...[
                const SizedBox(height: 16),
                _DeductionCard(
                  breakdown: widget.attendanceViewModel.periodDeductions,
                ),
              ],
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
        onPageChanged: (focusedDay) {
          setState(() {
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

/// Live "deductions so far this period" card. Recomputes from the streamed
/// attendance so it updates in realtime as records change. Hidden until the
/// employee salary and store settings have loaded ([breakdown] null).
class _DeductionCard extends StatelessWidget {
  const _DeductionCard({required this.breakdown});

  final DeductionBreakdown? breakdown;

  String _money(double v, SalaryCurrency currency) => currency ==
          SalaryCurrency.usd
      ? '\$${v.toStringAsFixed(2)}'
      : '${v.toStringAsFixed(0)} ៛';

  String _periodLabel(AppLocalizations l, PayPeriod p) {
    if (p.frequency == PayrollFrequency.monthly) return l.periodFullMonth;
    return p.isFirstHalf ? l.periodFirstHalf : l.periodSecondHalf;
  }

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    if (b == null) return const SizedBox.shrink();

    final c = appColors(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l.deductionsThisPeriod,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.infoLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _periodLabel(l, b.period),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DeductionRow(
            label: l.late,
            detail: b.lateMinutes > 0 ? '${b.lateMinutes} min' : null,
            amount: _money(b.late, b.currency),
            color: c.warning,
          ),
          const SizedBox(height: 10),
          _DeductionRow(
            label: l.absent,
            detail: b.unpaidDays > 0 ? '${b.unpaidDays}d' : null,
            amount: _money(b.absence, b.currency),
            color: c.error,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: c.textSecondary.withValues(alpha: 0.15)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.total,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              Text(
                _money(b.total, b.currency),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: c.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.estimatedFromAttendance,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: c.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeductionRow extends StatelessWidget {
  const _DeductionRow({
    required this.label,
    required this.amount,
    required this.color,
    this.detail,
  });

  final String label;
  final String amount;
  final Color color;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(width: 6),
          Text(
            '· $detail',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ],
        const Spacer(),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
      ],
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
