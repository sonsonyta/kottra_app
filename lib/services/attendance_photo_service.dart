import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Captures, persists, and uploads the photo an employee must attach when the
/// store requires a photo on check-in/out.
///
/// The capture and upload steps are split so an offline check-in can persist
/// the photo locally (see [savePending]) and upload it later, on sync, from the
/// stored file — mirroring how the offline queue defers the check-in call
/// itself.
class AttendancePhotoService {
  AttendancePhotoService({
    ImagePicker? picker,
    FirebaseStorage? storage,
  })  : _picker = picker ?? ImagePicker(),
        _storage = storage;

  final ImagePicker _picker;

  /// Resolved lazily so constructing the service (e.g. as a default dependency
  /// in tests) never touches `FirebaseStorage.instance` before Firebase is
  /// initialized. Only the actual upload path needs it.
  final FirebaseStorage? _storage;
  FirebaseStorage get _storageInstance => _storage ?? FirebaseStorage.instance;

  /// Subdirectory (under the app documents dir) holding photos awaiting upload.
  static const String _pendingDir = 'attendance_photos';

  /// Launches the device camera and returns the captured JPEG bytes, or null if
  /// the employee cancelled. The image is downscaled and compressed by
  /// image_picker so uploads stay small on mobile connections.
  Future<Uint8List?> capture() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 60,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Persists [bytes] to a stable local file keyed by [localId] so an offline
  /// check-in/out can upload it later even across app restarts. Returns the
  /// absolute file path.
  Future<String> savePending(String localId, Uint8List bytes) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/$_pendingDir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/$localId.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Removes a pending photo file once its check-in/out has synced. Best-effort:
  /// a missing or already-deleted file is ignored.
  Future<void> deletePending(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Could not delete pending attendance photo: $e');
    }
  }

  /// Uploads [bytes] to Firebase Storage under the store's attendance-photos
  /// path and returns a canonical download URL. [isCheckIn] only affects the
  /// stored filename so check-in and check-out photos never collide.
  Future<String> uploadBytes({
    required String storeId,
    required String employeeId,
    required Uint8List bytes,
    required bool isCheckIn,
    required int eventAtMs,
  }) async {
    final kind = isCheckIn ? 'checkin' : 'checkout';
    final ref = _storageInstance.ref().child(
        'stores/$storeId/hr_attendance_photos/$employeeId/${eventAtMs}_$kind.jpg');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return _canonicalizeUploadUrl(await task.ref.getDownloadURL());
  }

  /// Uploads a previously [savePending]-ed file. Returns null when the file is
  /// gone (e.g. cleared storage) so the caller can still complete the
  /// check-in/out without a photo rather than losing the action entirely.
  Future<String?> uploadFromPath({
    required String storeId,
    required String employeeId,
    required String path,
    required bool isCheckIn,
    required int eventAtMs,
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return uploadBytes(
      storeId: storeId,
      employeeId: employeeId,
      bytes: await file.readAsBytes(),
      isCheckIn: isCheckIn,
      eventAtMs: eventAtMs,
    );
  }

  /// On Android the Storage emulator returns download URLs hosted at `10.0.2.2`
  /// (the emulator host); persisting that would make the URL unreachable from
  /// iOS. Store the canonical `localhost` form instead. A no-op in release,
  /// where URLs point at real Firebase Storage hosts.
  String _canonicalizeUploadUrl(String url) =>
      url.replaceFirst('10.0.2.2', 'localhost');
}
