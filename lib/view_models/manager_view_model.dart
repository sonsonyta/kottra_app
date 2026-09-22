import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backs the store-user (email/password) home. Resolves every store the
/// signed-in user has an active role in and tracks which one is currently
/// selected. The selected store's dashboard is the home; the store list is only
/// shown when no store is selected yet (more than one store and none remembered).
/// Employee-token users never reach here; they use [MainViewModel] instead.
class ManagerViewModel extends ChangeNotifier {
  ManagerViewModel({
    AuthServiceBase? authService,
    FirebaseAuth? firebaseAuth,
    StoreService? storeService,
  })  : _authService = authService ?? AuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storeService = storeService ?? StoreService() {
    _resolveMemberships();
  }

  final AuthServiceBase _authService;
  final FirebaseAuth _firebaseAuth;
  final StoreService _storeService;

  bool _isLoading = true;
  List<StoreMembership> _memberships = const [];
  String? _errorMessage;
  String? _selectedStoreId;

  bool get isLoading => _isLoading;

  /// The stores this user can manage, sorted by name.
  List<StoreMembership> get memberships => _memberships;

  /// True once loading finished and the user has no active role in any store.
  bool get hasNoRole =>
      !_isLoading && _errorMessage == null && _memberships.isEmpty;

  String? get errorMessage => _errorMessage;

  /// The store whose dashboard is currently shown, or null when the user still
  /// needs to pick one from the store list.
  StoreMembership? get selectedMembership {
    final id = _selectedStoreId;
    if (id == null) return null;
    for (final m in _memberships) {
      if (m.storeId == id) return m;
    }
    return null;
  }

  /// Whether a store picker makes sense (the user belongs to more than one).
  bool get canSwitchStore => _memberships.length > 1;

  String get userName {
    final user = _firebaseAuth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'User';
  }

  Future<void> selectStore(StoreMembership membership) async {
    _selectedStoreId = membership.storeId;
    notifyListeners();
    await _persistSelectedStore(membership.storeId);
  }

  /// Clears the selection so the store list is shown again.
  Future<void> clearSelection() async {
    _selectedStoreId = null;
    notifyListeners();
    await _persistSelectedStore(null);
  }

  Future<void> refresh() => _resolveMemberships();

  Future<void> _resolveMemberships() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _memberships = await _storeService.findMembershipsForUid(uid);
      _selectedStoreId = await _resolveInitialSelection(uid);
    } catch (e) {
      _errorMessage = 'Could not load your stores. Please try again.';
      debugPrint('Error resolving store memberships: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Picks the store to open on load: the only one when there's a single store,
  /// otherwise the remembered choice when it's still valid, else none (show the
  /// list).
  Future<String?> _resolveInitialSelection(String uid) async {
    if (_memberships.length == 1) return _memberships.first.storeId;

    final remembered = await _readSelectedStore(uid);
    if (remembered != null &&
        _memberships.any((m) => m.storeId == remembered)) {
      return remembered;
    }
    return null;
  }

  String _prefsKey(String uid) => 'manager.selectedStore.$uid';

  Future<String?> _readSelectedStore(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey(uid));
    } catch (e) {
      debugPrint('Error reading selected store: $e');
      return null;
    }
  }

  Future<void> _persistSelectedStore(String? storeId) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (storeId == null) {
        await prefs.remove(_prefsKey(uid));
      } else {
        await prefs.setString(_prefsKey(uid), storeId);
      }
    } catch (e) {
      debugPrint('Error persisting selected store: $e');
    }
  }

  Future<void> logout() => _authService.signOut();
}
