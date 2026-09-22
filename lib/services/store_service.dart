import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/store.dart';
import 'package:kottra_app/models/store_user_role.dart';

/// A user's active role within a specific store, resolved from that store's
/// `userRoles` array.
class StoreMembership {
  const StoreMembership({
    required this.storeId,
    required this.storeName,
    required this.userRole,
  });

  final String storeId;
  final String? storeName;
  final StoreUserRole userRole;
}

class StoreService {
  StoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Fetches the store document (e.g. for its configured timezone).
  Future<Store?> getStore(String storeId) async {
    final doc = await _firestore.collection('stores').doc(storeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Store.fromMap(doc.id, doc.data()!);
  }

  /// Finds every store where [uid] has an active role. Used to classify and
  /// scope email/password users, who (unlike employee-token users) don't carry
  /// their store/role in their UID and may belong to more than one store.
  ///
  /// Returns an empty list when the user isn't an active member of any store.
  Future<List<StoreMembership>> findMembershipsForUid(String uid) async {
    final snapshot = await _firestore
        .collection('stores')
        .where('userIDs', arrayContains: uid)
        .get();

    final memberships = <StoreMembership>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final rawRoles = data['userRoles'];
      if (rawRoles is! List) continue;

      for (final raw in rawRoles) {
        if (raw is! Map) continue;
        final userRole = StoreUserRole.fromMap(Map<String, dynamic>.from(raw));
        if (userRole.uid == uid && userRole.isActive) {
          memberships.add(StoreMembership(
            storeId: doc.id,
            storeName: data['storeName'] as String?,
            userRole: userRole,
          ));
          break; // one active role per store is enough
        }
      }
    }

    memberships.sort((a, b) =>
        (a.storeName ?? a.storeId).compareTo(b.storeName ?? b.storeId));
    return memberships;
  }

  /// Convenience: the user's first active store membership, or null when they
  /// aren't an active member of any store.
  Future<StoreMembership?> findMembershipForUid(String uid) async {
    final memberships = await findMembershipsForUid(uid);
    return memberships.isEmpty ? null : memberships.first;
  }
}
