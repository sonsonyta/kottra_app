import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kottra_app/models/pending_attendance_action.dart';

/// Persistence backing for [OfflineAttendanceQueue]. Abstracted so tests can
/// supply an in-memory store instead of the SharedPreferences plugin, matching
/// the repo's fake-service testing pattern.
abstract class PendingActionStore {
  Future<List<String>> read(String key);
  Future<void> write(String key, List<String> values);
}

class SharedPreferencesPendingStore implements PendingActionStore {
  @override
  Future<List<String>> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key) ?? const [];
    } catch (e) {
      debugPrint('Could not read offline attendance queue: $e');
      return const [];
    }
  }

  @override
  Future<void> write(String key, List<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (values.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setStringList(key, values);
      }
    } catch (e) {
      debugPrint('Could not persist offline attendance queue: $e');
    }
  }
}

/// Durable FIFO queue of check-in/out actions awaiting replay to the backend.
///
/// The queue is scoped per employee (via [loadFor]) so actions captured under
/// one login are never replayed under another. It is a [ChangeNotifier] so the
/// view model can reflect pending/offline state in the UI.
class OfflineAttendanceQueue extends ChangeNotifier {
  OfflineAttendanceQueue({PendingActionStore? store})
      : _store = store ?? SharedPreferencesPendingStore();

  static const String _keyPrefix = 'offline_attendance_queue';

  final PendingActionStore _store;

  List<PendingAttendanceAction> _actions = [];
  String? _scopeKey;

  /// Pending actions, oldest first.
  List<PendingAttendanceAction> get actions => List.unmodifiable(_actions);

  bool get isEmpty => _actions.isEmpty;
  bool get isNotEmpty => _actions.isNotEmpty;

  /// Loads the persisted queue for the given employee. Safe to call again on
  /// re-auth; a different employee swaps to their own scope.
  Future<void> loadFor(String storeId, String employeeId) async {
    final key = '$_keyPrefix:$storeId:$employeeId';
    if (_scopeKey == key && _actions.isNotEmpty) {
      // Already loaded for this employee.
      return;
    }
    _scopeKey = key;
    final raw = await _store.read(key);
    _actions = raw
        .map((s) {
          try {
            return PendingAttendanceAction.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            );
          } catch (e) {
            debugPrint('Dropping unparseable queued attendance action: $e');
            return null;
          }
        })
        .whereType<PendingAttendanceAction>()
        .toList();
    notifyListeners();
  }

  Future<void> enqueue(PendingAttendanceAction action) async {
    _actions = [..._actions, action];
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String localId) async {
    _actions = _actions.where((a) => a.localId != localId).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> update(PendingAttendanceAction action) async {
    _actions = _actions
        .map((a) => a.localId == action.localId ? action : a)
        .toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final key = _scopeKey;
    if (key == null) return;
    await _store.write(
      key,
      _actions.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
