import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/day_off_schedule.dart';
import 'package:kottra_app/models/holiday.dart';
import 'package:kottra_app/services/day_off_service.dart';
import 'package:kottra_app/services/holiday_service.dart';

/// Backs the read-only Schedule screen: the employee's scheduled days off plus
/// store-wide holidays, for one month at a time with month navigation.
class ScheduleViewModel extends ChangeNotifier {
  ScheduleViewModel({
    required this.storeId,
    required this.employeeId,
    DayOffService? dayOffService,
    HolidayService? holidayService,
  })  : _dayOffService = dayOffService ?? DayOffService(),
        _holidayService = holidayService ?? HolidayService() {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    load();
  }

  final String storeId;
  final String employeeId;
  final DayOffService _dayOffService;
  final HolidayService _holidayService;

  late DateTime _selectedMonth;
  DayOffSchedule? _schedule;
  List<Holiday> _holidays = const [];
  bool _isLoading = false;
  bool _disposed = false;

  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;

  List<int> get dayOffDays => _schedule?.days ?? const [];
  List<Holiday> get holidays => _holidays;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == _selectedMonth.year && now.month == _selectedMonth.month;
  }

  int get daysInMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

  /// Weekday (1=Mon … 7=Sun) of the month's first day, matching DateTime.weekday.
  int get firstWeekday =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;

  bool isDayOff(int day) => _schedule?.isDayOff(day) ?? false;

  bool isToday(int day) {
    if (!isCurrentMonth) return false;
    return DateTime.now().day == day;
  }

  /// The holiday on [day], if any.
  Holiday? holidayForDay(int day) {
    for (final h in _holidays) {
      if (h.date.year == _selectedMonth.year &&
          h.date.month == _selectedMonth.month &&
          h.date.day == day) {
        return h;
      }
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    _safeNotify();
    try {
      final results = await Future.wait([
        _dayOffService.fetchMonth(storeId, employeeId, _selectedMonth),
        _holidayService.fetchMonth(storeId, _selectedMonth),
      ]);
      _schedule = results[0] as DayOffSchedule?;
      _holidays = results[1] as List<Holiday>;
    } catch (e) {
      debugPrint('ScheduleViewModel.load error: $e');
      _schedule = null;
      _holidays = const [];
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void previousMonth() {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    load();
  }

  void nextMonth() {
    _selectedMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    load();
  }

  void goToCurrentMonth() {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    load();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
