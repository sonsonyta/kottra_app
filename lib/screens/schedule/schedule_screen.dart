import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/holiday.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/profile_view_model.dart';
import 'package:kottra_app/view_models/schedule_view_model.dart';

/// Read-only view of the employee's scheduled days off and store-wide holidays,
/// laid out as a month calendar with navigation.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.profileViewModel});

  final ProfileViewModel profileViewModel;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ScheduleViewModel(
      storeId: widget.profileViewModel.storeId,
      employeeId: widget.profileViewModel.employeeId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: Text(
          l10n.scheduleTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _viewModel.load,
            color: c.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _MonthSwitcher(viewModel: _viewModel),
                const SizedBox(height: 16),
                _Legend(),
                const SizedBox(height: 12),
                _CalendarCard(viewModel: _viewModel),
                const SizedBox(height: 24),
                SectionHeader(title: l10n.yourDaysOff),
                const SizedBox(height: 12),
                _DayOffList(viewModel: _viewModel),
                const SizedBox(height: 24),
                SectionHeader(title: l10n.holidaysThisMonth),
                const SizedBox(height: 12),
                _HolidayList(viewModel: _viewModel),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Month switcher ──────────────────────────────────────────────────────────

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.viewModel});

  final ScheduleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMM(locale).format(viewModel.selectedMonth);
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: viewModel.previousMonth,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              if (!viewModel.isCurrentMonth)
                GestureDetector(
                  onTap: viewModel.goToCurrentMonth,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      AppLocalizations.of(context)!.today,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.chevron_right_rounded,
          onTap: viewModel.nextMonth,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Material(
      color: c.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: c.textPrimary, size: 24),
        ),
      ),
    );
  }
}

// ─── Legend ──────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: c.primary, label: l10n.dayOff),
        const SizedBox(width: 20),
        _LegendDot(color: c.holiday, label: l10n.holiday),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Calendar ────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.viewModel});

  final ScheduleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          _WeekdayHeader(),
          const SizedBox(height: 8),
          _CalendarGrid(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final locale = Localizations.localeOf(context).toString();
    // Sunday-start week. 2024-01-07 is a Sunday; walk 7 days for short labels.
    final base = DateTime(2024, 1, 7);
    final labels = List.generate(
      7,
      (i) => DateFormat.E(locale).format(base.add(Duration(days: i))),
    );
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: i == 0 ? c.error : c.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.viewModel});

  final ScheduleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = viewModel.daysInMonth;
    // Sunday-start: DateTime.weekday has Sun=7, so Sun maps to column 0.
    final leadingBlanks = viewModel.firstWeekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(row * 7 + col - leadingBlanks + 1),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(int day) {
    if (day < 1 || day > viewModel.daysInMonth) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }
    return _DayCell(viewModel: viewModel, day: day);
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.viewModel, required this.day});

  final ScheduleViewModel viewModel;
  final int day;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final holiday = viewModel.holidayForDay(day);
    final isDayOff = viewModel.isDayOff(day);
    final isToday = viewModel.isToday(day);

    Color? bg;
    Color fg = c.textPrimary;
    if (holiday != null) {
      bg = c.holidayLight;
      fg = c.holiday;
    } else if (isDayOff) {
      bg = c.infoLight;
      fg = c.primary;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: c.primary, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  (isDayOff || holiday != null || isToday)
                      ? FontWeight.w800
                      : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lists ───────────────────────────────────────────────────────────────────

class _DayOffList extends StatelessWidget {
  const _DayOffList({required this.viewModel});

  final ScheduleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final days = viewModel.dayOffDays;
    if (days.isEmpty) {
      return _EmptyRow(
        icon: Icons.event_available_outlined,
        text: l10n.noDaysOffThisMonth,
      );
    }
    return Column(
      children: [
        for (final day in days)
          _ScheduleRow(
            color: appColors(context).primary,
            icon: Icons.beach_access_outlined,
            title: DateFormat('EEEE, d MMMM', locale).format(
              DateTime(
                viewModel.selectedMonth.year,
                viewModel.selectedMonth.month,
                day,
              ),
            ),
            subtitle: l10n.dayOff,
          ),
      ],
    );
  }
}

class _HolidayList extends StatelessWidget {
  const _HolidayList({required this.viewModel});

  final ScheduleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final languageCode = Localizations.localeOf(context).languageCode;
    final holidays = viewModel.holidays;
    if (holidays.isEmpty) {
      return _EmptyRow(
        icon: Icons.celebration_outlined,
        text: l10n.noHolidaysThisMonth,
      );
    }
    return Column(
      children: [
        for (final Holiday h in holidays)
          _ScheduleRow(
            color: appColors(context).holiday,
            icon: Icons.celebration_outlined,
            title: h.localizedName(languageCode),
            subtitle: DateFormat('EEEE, d MMMM', locale).format(h.date),
          ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: c.shadowSubtle,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
