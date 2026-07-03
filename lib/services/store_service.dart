import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/store.dart';

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
}
