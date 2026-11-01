import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/early_leave_request.dart';
import 'package:kottra_app/services/early_leave_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:timezone/timezone.dart' as tz;

class EarlyLeaveViewModel extends ChangeNotifier {
  EarlyLeaveViewModel({
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    EarlyLeaveService? earlyLeaveService,
    StoreService? storeService,
  })  : _service = earlyLeaveService ?? EarlyLeaveService(),
        _storeService = storeService ?? StoreService() {
    _subscribe();
    _loadStoreTimezone();
  }

  /// How far ahead an employee can ask to leave early.
  static const upcomingWindowDays = 30;

  final String storeId;
  final String employeeId;
  final String employeeName;

  final EarlyLeaveService _service;
  final StoreService _storeService;

  /// The store's IANA timezone, so the day is recorded as a calendar day in
  /// the store's timezone. Falls back to the device timezone until loaded.
  String? _storeTimezone;

  StreamSubscription<List<EarlyLeaveRequest>>? _requestSub;
  List<EarlyLeaveRequest> _requests = [];
  bool _isLoading = false;
  bool _disposed = false;

  List<EarlyLeaveRequest> get requests => _requests;
  bool get isLoading => _isLoading;

  DateTime get firstDay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get lastDay =>
      firstDay.add(const Duration(days: upcomingWindowDays));

  /// Today or later within the window, without a pending/approved request.
  bool isDaySelectable(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    if (date.isBefore(firstDay) || date.isAfter(lastDay)) return false;
    return !_requests.any((r) =>
        r.status != EarlyLeaveStatus.rejected &&
        r.date.year == date.year &&
        r.date.month == date.month &&
        r.date.day == date.day);
  }

  void _subscribe() {
    if (employeeId.isEmpty) return;
    _requestSub?.cancel();
    _requestSub = _service.streamEmployeeRequests(storeId, employeeId).listen(
      (data) {
        _requests = data;
        if (!_disposed) notifyListeners();
      },
      onError: (Object e) => debugPrint('Early leave stream error: $e'),
    );
  }

  Future<void> _loadStoreTimezone() async {
    try {
      final store = await _storeService.getStore(storeId);
      _storeTimezone = store?.timezone;
    } catch (e) {
      debugPrint('Error loading store timezone: $e');
    }
  }

  tz.Location get _storeLocation {
    final name = _storeTimezone;
    if (name != null && name.isNotEmpty) {
      try {
        return tz.getLocation(name);
      } catch (_) {
        // Unknown timezone name — fall through to the device timezone.
      }
    }
    try {
      return tz.local;
    } catch (_) {
      return tz.UTC;
    }
  }

  /// Asks to leave at [hour]:[minute] on [day].
  Future<void> submitRequest({
    required DateTime day,
    required int hour,
    required int minute,
    required String reason,
  }) async {
    if (employeeId.isEmpty) throw Exception('Employee ID is missing');
    if (!isDaySelectable(day)) throw Exception('This day cannot be selected.');
    if (reason.trim().isEmpty) throw Exception('Please provide a reason.');

    _isLoading = true;
    notifyListeners();
    try {
      await _service.submitRequest(EarlyLeaveRequest(
        id: '',
        storeId: storeId,
        employeeId: employeeId,
        employeeName: employeeName,
        date: tz.TZDateTime(_storeLocation, day.year, day.month, day.day),
        leaveTime:
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        reason: reason.trim(),
        status: EarlyLeaveStatus.pending,
      ));
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestSub?.cancel();
    super.dispose();
  }
}
