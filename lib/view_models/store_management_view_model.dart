import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:kottra_app/models/app_user.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/models/late_excuse_request.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/late_excuse_service.dart';
import 'package:kottra_app/services/leave_service.dart';
import 'package:kottra_app/services/notification_service.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backs the management dashboard for a single store the manager/owner selected.
/// Streams that store's attendance (for a chosen day), leave requests and
/// late-excuse requests, and exposes the approve/reject actions.
class StoreManagementViewModel extends ChangeNotifier {
  StoreManagementViewModel({
    required this.membership,
    FirebaseAuth? firebaseAuth,
    AttendanceService? attendanceService,
    LeaveService? leaveService,
    LateExcuseService? lateExcuseService,
    UserService? userService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _attendanceService = attendanceService ?? AttendanceService(),
        _leaveService = leaveService ?? LeaveService(),
        _lateExcuseService = lateExcuseService ?? LateExcuseService(),
        _userService = userService ?? UserService() {
    _selectedDate = _startOfToday();
    _displayName = _firebaseAuth.currentUser?.displayName;
    _loadNotificationPref();
    _subscribeUser();
    _subscribeAttendance();
    _subscribeLeaves();
    _subscribeLateExcuses();
  }

  final StoreMembership membership;
  final FirebaseAuth _firebaseAuth;
  final AttendanceService _attendanceService;
  final LeaveService _leaveService;
  final LateExcuseService _lateExcuseService;
  final UserService _userService;

  String get storeId => membership.storeId;
  String? get storeName => membership.storeName;
  String get roleLabel => membership.userRole.displayName;

  // ── Profile ───────────────────────────────────────────────────────────────

  static const String _notifPrefKey = 'manager_request_notifications';

  StreamSubscription<AppUser?>? _userSub;
  String? _displayName;
  String? _email;
  String? _photoUrl;
  Uint8List? _photoBytes;
  bool _requestNotificationsEnabled = true;
  bool _isUploadingPhoto = false;

  /// The avatar's network URL, when the stored photo is a Storage download URL.
  /// Null when there's no photo or the stored value is a legacy base64 image.
  String? get photoUrl => _photoUrl;

  /// The avatar's decoded bytes, when the stored photo is a legacy base64 image
  /// (written by older POS/admin builds). Null when it's a URL or absent.
  Uint8List? get photoBytes => _photoBytes;

  bool get isUploadingPhoto => _isUploadingPhoto;

  /// The manager's shown name: their `users/{uid}` display name, else the email
  /// prefix, else a generic label.
  String get managerName {
    final name = _displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = managerEmail;
    return email.isNotEmpty ? email.split('@').first : 'User';
  }

  String get managerEmail =>
      _email ?? _firebaseAuth.currentUser?.email ?? '';

  /// Streams the signed-in manager's root `users/{uid}` document for their name
  /// and profile photo.
  void _subscribeUser() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    _userSub = _userService.streamUser(uid).listen((user) {
      if (user == null) return;
      _displayName = user.displayName ?? _displayName;
      _email = user.email ?? _email;
      if (!_isUploadingPhoto) {
        _applyPhoto(user.imageThumbnail ?? user.imageUrl);
      }
      notifyListeners();
    }, onError: (Object e) => debugPrint('Error streaming user: $e'));
  }

  /// Resolves a stored photo [value] into either a network URL or decoded
  /// bytes. New photos are Storage download URLs; older POS/admin builds stored
  /// the image inline as a base64 data URI — both are supported here.
  void _applyPhoto(String? value) {
    if (value == null || value.isEmpty) {
      _photoUrl = null;
      _photoBytes = null;
    } else if (value.startsWith('http')) {
      _photoUrl = _resolveEmulatorUrl(value);
      _photoBytes = null;
    } else {
      _photoUrl = null;
      _photoBytes = _decodeImage(value);
    }
  }

  /// Whether the manager wants to be notified when employees submit requests.
  bool get requestNotificationsEnabled => _requestNotificationsEnabled;

  Future<void> _loadNotificationPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _requestNotificationsEnabled = prefs.getBool(_notifPrefKey) ?? true;
    } catch (e) {
      debugPrint('Error loading manager notification pref: $e');
    }
    NotificationService.instance.leaveNotificationsEnabled =
        _requestNotificationsEnabled;
    notifyListeners();
  }

  Future<void> toggleRequestNotifications(bool value) async {
    _requestNotificationsEnabled = value;
    NotificationService.instance.leaveNotificationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notifPrefKey, value);
    } catch (e) {
      debugPrint('Error saving manager notification pref: $e');
    }
  }

  String? get _uid => _firebaseAuth.currentUser?.uid;

  /// Updates the manager's display name on their `users/{uid}` document (and
  /// their Firebase Auth profile, to keep them in sync).
  Future<void> updateDisplayName(String name) async {
    final uid = _uid;
    final trimmed = name.trim();
    if (uid == null || trimmed.isEmpty) return;
    await _userService.updateUser(uid, {'displayName': trimmed});
    await _firebaseAuth.currentUser?.updateDisplayName(trimmed);
    _displayName = trimmed;
    notifyListeners();
  }

  /// Sets the manager's profile photo. Compresses [imageBytes] to a full image
  /// and a thumbnail, uploads both to Cloud Storage under `users/{uid}/…`, and
  /// writes their download URLs to the `users/{uid}` document's `imageUrl` /
  /// `imageThumbnail`.
  Future<void> updateProfilePhoto(Uint8List imageBytes) async {
    final uid = _uid;
    if (uid == null) return;

    _isUploadingPhoto = true;
    notifyListeners();
    try {
      final full = await _compress(imageBytes, 720, 80);
      final thumb = await _compress(imageBytes, 256, 70);

      final imageUrl = await _upload('users/$uid/profile.jpg', full);
      final thumbnail = await _upload('users/$uid/profile_thumb.jpg', thumb);

      await _userService.updateUser(uid, {
        'imageUrl': imageUrl,
        'imageThumbnail': thumbnail,
      });
      _applyPhoto(thumbnail);
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  /// Uploads [bytes] as a JPEG to [path] in Cloud Storage and returns its
  /// download URL, canonicalized for storage.
  Future<String> _upload(String path, Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return _canonicalizeUploadUrl(await task.ref.getDownloadURL());
  }

  /// Against the Storage emulator on Android, `getDownloadURL` returns a
  /// `10.0.2.2` host. Persisting that would make the URL unreachable from iOS
  /// and the web. Store the canonical `localhost` form instead and let
  /// [_resolveEmulatorUrl] rewrite it back to `10.0.2.2` per-platform on read.
  /// In release (real Storage) this is a no-op.
  String _canonicalizeUploadUrl(String url) =>
      url.replaceFirst('10.0.2.2', 'localhost');

  /// Compresses [source] to a square JPEG of [size]px at [quality].
  Future<Uint8List> _compress(Uint8List source, int size, int quality) async {
    final jpeg = await FlutterImageCompress.compressWithList(
      source,
      minWidth: size,
      minHeight: size,
      quality: quality,
    );
    if (jpeg.isEmpty) {
      throw Exception('Image compression produced no output.');
    }
    return jpeg;
  }

  /// Decodes a legacy base64 image (with or without a `data:` URI prefix) to
  /// bytes. Returns null for empty/invalid input.
  Uint8List? _decodeImage(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final comma = value.indexOf(',');
      final b64 = comma >= 0 ? value.substring(comma + 1) : value;
      return base64Decode(b64);
    } catch (e) {
      debugPrint('Error decoding profile image: $e');
      return null;
    }
  }

  /// In debug on Android, the Storage emulator returns `localhost`/`127.0.0.1`
  /// URLs the emulator can't reach — they must use `10.0.2.2`.
  String? _resolveEmulatorUrl(String? url) {
    if (url == null) return null;
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  // ── Bottom-nav ────────────────────────────────────────────────────────────

  int _navIndex = 0;
  int get navIndex => _navIndex;
  void setNavIndex(int index) {
    if (_navIndex == index) return;
    _navIndex = index;
    notifyListeners();
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  StreamSubscription<List<AttendanceRecord>>? _attendanceSub;
  late DateTime _selectedDate;
  List<AttendanceRecord> _attendance = const [];
  bool _attendanceLoading = true;

  DateTime get selectedDate => _selectedDate;
  List<AttendanceRecord> get attendance => _attendance;
  bool get attendanceLoading => _attendanceLoading;

  // Summary counts for the currently loaded day (drives the Home stat row).
  // A late arrival still counts as showing up, so present includes late.
  int get presentCount => _attendance
      .where((r) =>
          r.status == AttendanceStatus.present ||
          r.status == AttendanceStatus.late)
      .length;
  int get lateCount =>
      _attendance.where((r) => r.status == AttendanceStatus.late).length;
  int get absentCount =>
      _attendance.where((r) => r.status == AttendanceStatus.absent).length;
  int get leaveCount =>
      _attendance.where((r) => r.status == AttendanceStatus.leave).length;

  void setSelectedDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == _selectedDate) return;
    _selectedDate = normalized;
    _subscribeAttendance();
  }

  void _subscribeAttendance() {
    _attendanceSub?.cancel();
    _attendanceLoading = true;
    notifyListeners();
    _attendanceSub = _attendanceService
        .streamStoreAttendanceByDate(storeId, _selectedDate)
        .listen((records) {
      _attendance = records;
      _attendanceLoading = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Error streaming store attendance: $e');
      _attendanceLoading = false;
      notifyListeners();
    });
  }

  // ── Leave requests ──────────────────────────────────────────────────────────

  StreamSubscription<List<LeaveRequest>>? _leaveSub;
  List<LeaveRequest> _leaves = const [];
  bool _leavesLoading = true;

  List<LeaveRequest> get leaves => _leaves;
  bool get leavesLoading => _leavesLoading;
  int get pendingLeaveCount =>
      _leaves.where((l) => l.status == LeaveStatus.pending).length;

  void _subscribeLeaves() {
    _leaveSub?.cancel();
    _leaveSub = _leaveService.streamStoreLeaves(storeId).listen((leaves) {
      _leaves = leaves;
      _leavesLoading = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Error streaming store leaves: $e');
      _leavesLoading = false;
      notifyListeners();
    });
  }

  Future<void> actionLeave(
    LeaveRequest request,
    LeaveStatus status, {
    String? reason,
  }) async {
    await _leaveService.setLeaveStatus(
      storeId: storeId,
      requestId: request.id,
      status: status,
      actionedBy: _actorId,
      actionReason: reason,
    );
  }

  // ── Late-excuse requests ─────────────────────────────────────────────────────

  StreamSubscription<List<LateExcuseRequest>>? _lateSub;
  List<LateExcuseRequest> _lateExcuses = const [];
  bool _lateExcusesLoading = true;

  List<LateExcuseRequest> get lateExcuses => _lateExcuses;
  bool get lateExcusesLoading => _lateExcusesLoading;
  int get pendingLateExcuseCount =>
      _lateExcuses.where((r) => r.status == LateExcuseStatus.pending).length;

  void _subscribeLateExcuses() {
    _lateSub?.cancel();
    _lateSub =
        _lateExcuseService.streamStoreRequests(storeId).listen((requests) {
      _lateExcuses = requests;
      _lateExcusesLoading = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Error streaming store late excuses: $e');
      _lateExcusesLoading = false;
      notifyListeners();
    });
  }

  Future<void> actionLateExcuse(
    LateExcuseRequest request,
    LateExcuseStatus status, {
    String? reason,
  }) async {
    await _lateExcuseService.setStatus(
      request: request,
      status: status,
      actionedBy: _actorId,
      actionReason: reason,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String get _actorId => _firebaseAuth.currentUser?.uid ?? 'unknown';

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _attendanceSub?.cancel();
    _leaveSub?.cancel();
    _lateSub?.cancel();
    super.dispose();
  }
}
