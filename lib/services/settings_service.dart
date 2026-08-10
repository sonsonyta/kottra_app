import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kottra_app/models/hr_settings.dart';

/// Reads the store's `settings/{storeId}` document, where the POS admin app
/// stores HR/payroll configuration under the `hrSettings` key.
class SettingsService {
  SettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _docRef(String storeId) =>
      _firestore.collection('settings').doc(storeId);

  /// Fetches HR settings once. Returns [HrSettings.defaults] when the document
  /// or its `hrSettings` key is missing.
  Future<HrSettings> getHrSettings(String storeId) async {
    final doc = await _docRef(storeId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return HrSettings.defaults;
    return HrSettings.fromSettingsDoc(data);
  }

  /// Streams HR settings, emitting on every change to the settings document so
  /// deduction config edits from the POS reflect without an app restart.
  Stream<HrSettings> streamHrSettings(String storeId) {
    return _docRef(storeId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return HrSettings.defaults;
      return HrSettings.fromSettingsDoc(data);
    });
  }
}
