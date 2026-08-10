import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kottra_app/models/hr_employee.dart';
import 'package:kottra_app/services/employee_service.dart';
import 'package:kottra_app/services/notification_service.dart';
import 'package:kottra_app/view_models/employee_identity.dart';

export 'package:kottra_app/models/hr_employee.dart';

/// Owns the profile tab's state: the employee's profile info, notification
/// preferences, and profile editing (name + avatar upload). Like the other
/// view models in this app it subscribes to Firestore itself rather than
/// depending on [MainViewModel], keeping the profile feature self-contained.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    FirebaseAuth? firebaseAuth,
    EmployeeService? employeeService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _employeeService = employeeService ?? EmployeeService() {
    _loadPreferences();
    _subscribeToEmployee();
  }

  final FirebaseAuth _firebaseAuth;
  final EmployeeService _employeeService;

  StreamSubscription<HREmployee?>? _employeeSub;

  HREmployee? _employee;

  bool _disposed = false;

  // ── Identity ─────────────────────────────────────────────────────────────────

  /// Parsed from the Firebase Auth UID (`hr_employee:<storeId>:<employeeId>`).
  ({String storeId, String employeeId})? get _identity {
    final uid = _currentUser?.uid;
    if (uid == null) return null;
    return parseEmployeeUid(uid);
  }

  User? get _currentUser => _firebaseAuth.currentUser;

  void _subscribeToEmployee() {
    final identity = _identity;
    if (identity == null) return;

    _employeeSub?.cancel();
    _employeeSub = _employeeService
        .streamEmployee(identity.storeId, identity.employeeId)
        .listen((emp) {
      _employee = emp;
      notifyListeners();

      if (_remindersEnabled &&
          emp?.startWorkingTime != null &&
          emp?.endWorkingTime != null) {
        NotificationService.instance
            .scheduleAttendanceReminders(emp!.startWorkingTime!, emp.endWorkingTime!);
      }
    });
  }

  // ── Preferences ─────────────────────────────────────────────────────────────

  bool _remindersEnabled = false;
  bool get remindersEnabled => _remindersEnabled;

  bool _leaveNotificationsEnabled = true;
  bool get leaveNotificationsEnabled => _leaveNotificationsEnabled;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _remindersEnabled = prefs.getBool('attendance_reminders') ?? false;
    _leaveNotificationsEnabled = prefs.getBool('leave_notifications') ?? true;
    NotificationService.instance.leaveNotificationsEnabled = _leaveNotificationsEnabled;
    notifyListeners();
  }

  Future<void> toggleReminders(bool value) async {
    _remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('attendance_reminders', value);
    if (_disposed) return;
    notifyListeners();

    if (value) {
      await NotificationService.instance.requestPermissions();
      if (startWorkingTime != null && endWorkingTime != null) {
        await NotificationService.instance.scheduleAttendanceReminders(startWorkingTime!, endWorkingTime!);
      }
    } else {
      await NotificationService.instance.cancelAllReminders();
    }
  }

  Future<void> toggleLeaveNotifications(bool value) async {
    _leaveNotificationsEnabled = value;
    NotificationService.instance.leaveNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('leave_notifications', value);
    if (_disposed) return;
    notifyListeners();
  }

  // ── User info ────────────────────────────────────────────────────────────────

  String get userName {
    if (_employee != null && _employee!.fullName.trim().isNotEmpty) {
      return _employee!.fullName;
    }
    final user = _currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Employee';
  }

  String get userEmail => _currentUser?.email ?? '';

  String get userInitials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : 'E';
  }

  // ── Employee profile ─────────────────────────────────────────────────────────

  String get storeId => _identity?.storeId ?? '';
  String get employeeId => _identity?.employeeId ?? '';
  String get firstName => _employee?.firstName ?? '';
  String get lastName => _employee?.lastName ?? '';
  String get employeeCode => _employee?.employeeCode ?? _identity?.employeeId ?? '—';
  String get position => _employee?.position ?? '—';
  String? get department => _employee?.department;
  String? get workLocation => _employee?.workLocation;
  String? get startWorkingTime => _employee?.startWorkingTime;
  String? get endWorkingTime => _employee?.endWorkingTime;
  int? get lateTime => _employee?.lateTime;
  EmployeeStatus get employeeStatus => _employee?.status ?? EmployeeStatus.active;
  String? get profileImageUrl {
    final url = _employee?.profileImageThumbnail ?? _employee?.profileImage;
    return _resolveEmulatorUrl(url);
  }

  /// In debug mode the Storage emulator returns download URLs pointing at
  /// `localhost`/`127.0.0.1`, which the Android emulator cannot reach — it must
  /// use `10.0.2.2` (matching the emulator host wired up in `main.dart`).
  String? _resolveEmulatorUrl(String? url) {
    if (url == null) return null;
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  /// On Android the Storage emulator returns download URLs hosted at
  /// `10.0.2.2` (the emulator host). Persisting that would make the URL
  /// unreachable from iOS. Store the canonical `localhost` form instead and let
  /// [_resolveEmulatorUrl] rewrite it back to `10.0.2.2` per-platform on read.
  /// A no-op in release, where URLs point at real Firebase Storage hosts.
  String _canonicalizeUploadUrl(String url) => url.replaceFirst('10.0.2.2', 'localhost');

  // ── Mutations ────────────────────────────────────────────────────────────────

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    Uint8List? croppedImageBytes,
  }) async {
    final identity = _identity;
    if (identity == null) return;

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (firstName != null && firstName.isNotEmpty) updates['firstName'] = firstName;
      if (lastName != null && lastName.isNotEmpty) updates['lastName'] = lastName;

      if (croppedImageBytes != null) {
        final profile = await _compressImage(croppedImageBytes, 700);
        final thumbnail = await _compressImage(croppedImageBytes, 120);

        final profileRef = FirebaseStorage.instance.ref().child(
            'stores/${identity.storeId}/employees/${identity.employeeId}/profile.${profile.ext}');
        final thumbRef = FirebaseStorage.instance.ref().child(
            'stores/${identity.storeId}/employees/${identity.employeeId}/profile_thumbnail.${thumbnail.ext}');

        final profileTask = await _withTimeout(
          profileRef.putData(
            profile.bytes,
            SettableMetadata(contentType: profile.contentType),
          ),
          'uploading profile image',
        );
        final thumbTask = await _withTimeout(
          thumbRef.putData(
            thumbnail.bytes,
            SettableMetadata(contentType: thumbnail.contentType),
          ),
          'uploading thumbnail',
        );

        updates['profileImage'] = _canonicalizeUploadUrl(
            await _withTimeout(profileTask.ref.getDownloadURL(), 'getting profile image URL'));
        updates['profileImageThumbnail'] = _canonicalizeUploadUrl(
            await _withTimeout(thumbTask.ref.getDownloadURL(), 'getting thumbnail URL'));
      }

      if (updates.isNotEmpty) {
        await _withTimeout(
          _employeeService.updateEmployee(
              identity.storeId, identity.employeeId, updates),
          'saving profile',
        );
      }
    } finally {
      _isUpdatingProfile = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Guards a network step so a stalled backend (e.g. an unresponsive emulator
  /// connection) surfaces a clear error instead of leaving the UI spinning
  /// forever. The [step] label names which operation timed out.
  Future<T> _withTimeout<T>(Future<T> future, String step) {
    return future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Timed out while $step'),
    );
  }

  /// Compresses [source] to a square of [size]px. Prefers WebP, but on Android
  /// WebP encoding can return an empty list, so we fall back to JPEG (which is
  /// reliably supported on both platforms). Throws if compression fails
  /// entirely, so callers surface an error instead of silently doing nothing.
  Future<_CompressedImage> _compressImage(Uint8List source, int size) async {
    final webp = await FlutterImageCompress.compressWithList(
      source,
      minWidth: size,
      minHeight: size,
      quality: 85,
      format: CompressFormat.webp,
    );
    if (webp.isNotEmpty) {
      return _CompressedImage(webp, 'webp', 'image/webp');
    }

    final jpeg = await FlutterImageCompress.compressWithList(
      source,
      minWidth: size,
      minHeight: size,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (jpeg.isNotEmpty) {
      return _CompressedImage(jpeg, 'jpg', 'image/jpeg');
    }

    throw Exception('Image compression failed to produce any output.');
  }

  @override
  void dispose() {
    _disposed = true;
    _employeeSub?.cancel();
    super.dispose();
  }
}

class _CompressedImage {
  const _CompressedImage(this.bytes, this.ext, this.contentType);

  final Uint8List bytes;
  final String ext;
  final String contentType;
}
