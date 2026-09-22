import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/app_user.dart';

/// Reads and updates the root `users/{uid}` collection — the account documents
/// for email/password (POS/admin) users. Employee-token users don't have one.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users');

  Stream<AppUser?> streamUser(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  /// Updates the user's own document. Only the provided fields are overwritten.
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _col.doc(uid).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
