import 'package:flutter/foundation.dart';
import 'package:kottra_app/services/user_service.dart';

/// Resolves a request's `actionedBy` into a readable approver name.
///
/// `actionedBy` holds the approver's user UID (written by both this app and the
/// POS); older POS records hold a display name directly, which is passed
/// through unchanged. Names are looked up from `users/{uid}` once and cached
/// for the app session. Mirrors the POS `HrActorNameService`.
class ActorNameService {
  ActorNameService({UserService? userService})
    : _userService = userService ?? UserService();

  static final ActorNameService instance = ActorNameService();

  // Firebase Auth UIDs are 28 alphanumeric chars; display names never match.
  static final RegExp _uidPattern = RegExp(r'^[A-Za-z0-9]{28}$');

  final UserService _userService;
  final Map<String, String> _names = {};
  final Map<String, Future<String>> _pending = {};

  static bool isUid(String value) => _uidPattern.hasMatch(value);

  /// The name if already known (or [actionedBy] is a legacy name), else null.
  String? cachedName(String? actionedBy) {
    final id = actionedBy?.trim();
    if (id == null || id.isEmpty) return null;
    if (!isUid(id)) return id;
    return _names[id];
  }

  /// Resolves [actionedBy] to a name; null when it's empty.
  Future<String?> resolve(String? actionedBy) async {
    final id = actionedBy?.trim();
    if (id == null || id.isEmpty) return null;
    if (!isUid(id)) return id;
    final cached = _names[id];
    if (cached != null) return cached;
    return _pending[id] ??= _lookup(id);
  }

  Future<String> _lookup(String uid) async {
    String name;
    try {
      final user = await _userService.getUser(uid);
      final displayName = user?.displayName?.trim();
      final email = user?.email ?? '';
      name = displayName != null && displayName.isNotEmpty
          ? displayName
          : email.isNotEmpty
          ? email.split('@').first
          : 'Unknown user';
    } catch (e) {
      debugPrint('Error resolving approver $uid: $e');
      name = 'Unknown user';
    }
    _names[uid] = name;
    _pending.remove(uid);
    return name;
  }
}
