/// A single entry in a store document's `userRoles` array, granting a POS/admin
/// user (one who signs in with email/password rather than an employee token) a
/// role within that store. Mirrors the `StoreUserRole` shape written by the POS
/// and admin apps.
class StoreUserRole {
  const StoreUserRole({
    required this.uid,
    required this.role,
    this.roleName,
    this.isActive = true,
  });

  /// Firebase Auth UID of the user this role belongs to.
  final String uid;

  /// Built-in [StoreRole] value (e.g. `Owner`) or a custom role id.
  final String role;

  /// Human-readable name. Same as [role] for built-in roles; a custom name for
  /// custom roles. Falls back to [role] when absent.
  final String? roleName;

  /// Whether this grant is currently active. Inactive grants should be ignored.
  final bool isActive;

  /// Best label to show a user for this role.
  String get displayName {
    final name = roleName?.trim();
    return (name != null && name.isNotEmpty) ? name : role;
  }

  factory StoreUserRole.fromMap(Map<String, dynamic> map) => StoreUserRole(
        uid: (map['uid'] as String?) ?? '',
        role: (map['role'] as String?) ?? '',
        roleName: map['roleName'] as String?,
        isActive: map['isActive'] as bool? ?? true,
      );
}

/// Built-in store role names, matching the `StoreRole` enum in the POS/admin apps.
class StoreRole {
  StoreRole._();

  static const String owner = 'Owner';
  static const String admin = 'Admin';
  static const String manager = 'Manager';
  static const String cashier = 'Cashier';
}
