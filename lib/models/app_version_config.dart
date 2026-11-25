import 'package:flutter/foundation.dart';

/// Store pages used when Remote Config doesn't override them.
const defaultAndroidStoreUrl =
    'https://play.google.com/store/apps/details?id=app.kottra.mobile';
const defaultIosStoreUrl = 'https://apps.apple.com/app/id6763726229';

/// Release info the app checks on start, from Firebase Remote Config
/// (Firebase console → Remote Config). All parameters are strings:
///
/// ```
/// latest_version:   "1.9.8"   // newest release; add an iOS/Android
///                             // condition when the stores go live on
///                             // different days
/// min_version:      "1.9.0"   // optional: older builds must update
/// android_url / ios_url       // optional: override the store pages
/// release_notes / release_notes_kh   // optional, English / Khmer
/// ```
@immutable
class AppVersionConfig {
  const AppVersionConfig({
    required this.latestVersion,
    this.minVersion,
    this.androidUrl,
    this.iosUrl,
    this.releaseNotes,
    this.releaseNotesKH,
  });

  final String latestVersion;
  final String? minVersion;
  final String? androidUrl;
  final String? iosUrl;
  final String? releaseNotes;
  final String? releaseNotesKH;

  /// Null when the doc has no usable `latestVersion`.
  static AppVersionConfig? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    String? str(String key) {
      final v = map[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final latest = str('latestVersion');
    if (latest == null || parseVersion(latest) == null) return null;
    return AppVersionConfig(
      latestVersion: latest,
      minVersion: str('minVersion'),
      androidUrl: str('androidUrl'),
      iosUrl: str('iosUrl'),
      releaseNotes: str('releaseNotes'),
      releaseNotesKH: str('releaseNotesKH'),
    );
  }

  /// From Remote Config parameter values ([value] returns '' when unset).
  static AppVersionConfig? fromRemoteValues(
    String Function(String key) value,
  ) => fromMap({
    'latestVersion': value('latest_version'),
    'minVersion': value('min_version'),
    'androidUrl': value('android_url'),
    'iosUrl': value('ios_url'),
    'releaseNotes': value('release_notes'),
    'releaseNotesKH': value('release_notes_kh'),
  });

  /// Release notes in the user's language, falling back to English.
  String? notesFor(String languageCode) =>
      languageCode == 'km' ? (releaseNotesKH ?? releaseNotes) : releaseNotes;
}

enum UpdateStatus {
  /// Up to date (or no config).
  none,

  /// A newer release exists; the user may choose Later.
  optional,

  /// This build is below `minVersion`; the dialog can't be dismissed.
  required,
}

/// "1.9.7+29" → [1, 9, 7, 29]; "1.9" → [1, 9, 0, 0]. Null if not numeric.
/// The build number (after '+') only breaks ties between equal versions.
List<int>? parseVersion(String version) {
  final plus = version.trim().split('+');
  final parts = plus[0].split('.');
  if (parts.isEmpty || parts.length > 3) return null;
  final nums = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0) return null;
    nums.add(n);
  }
  while (nums.length < 3) {
    nums.add(0);
  }
  final build = plus.length > 1 ? int.tryParse(plus[1]) : null;
  nums.add(build ?? 0);
  return nums;
}

/// Negative when [a] is older than [b], 0 when equal, positive when newer.
/// A version without a build number compares equal to any build of it, so
/// "1.9.8" in the config matches an installed "1.9.8+30".
int compareVersions(String a, String b) {
  final x = parseVersion(a);
  final y = parseVersion(b);
  if (x == null || y == null) return 0;
  final bothHaveBuild = a.contains('+') && b.contains('+');
  final length = bothHaveBuild ? 4 : 3;
  for (var i = 0; i < length; i++) {
    if (x[i] != y[i]) return x[i] - y[i];
  }
  return 0;
}

/// Whether the installed [current] version should update, per [config].
UpdateStatus updateStatusFor(String current, AppVersionConfig? config) {
  if (config == null || parseVersion(current) == null) return UpdateStatus.none;
  final min = config.minVersion;
  if (min != null && compareVersions(current, min) < 0) {
    return UpdateStatus.required;
  }
  return compareVersions(current, config.latestVersion) < 0
      ? UpdateStatus.optional
      : UpdateStatus.none;
}

/// How long "Later" hides the reminder for the same release.
const updateSnoozeDuration = Duration(hours: 24);

/// Whether an optional-update reminder for [latestVersion] should show, given
/// the release the user last chose Later for and when.
bool shouldRemind({
  required String latestVersion,
  required String? snoozedVersion,
  required DateTime? snoozedAt,
  required DateTime now,
}) {
  if (snoozedVersion != latestVersion || snoozedAt == null) return true;
  return now.difference(snoozedAt) >= updateSnoozeDuration;
}
