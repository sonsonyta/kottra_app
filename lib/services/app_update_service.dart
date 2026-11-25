import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/models/app_version_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the app should show about updates right now.
class UpdateCheck {
  const UpdateCheck(this.status, this.config, this.currentVersion);

  final UpdateStatus status;
  final AppVersionConfig? config;
  final String currentVersion;

  /// The store page for this platform: Remote Config's link if set, else the
  /// app's own listing.
  String get storeUrl => defaultTargetPlatform == TargetPlatform.iOS
      ? config?.iosUrl ?? defaultIosStoreUrl
      : config?.androidUrl ?? defaultAndroidStoreUrl;
}

/// Compares the installed version with the Remote Config release parameters
/// and remembers when the user chose "Later" for a release.
class AppUpdateService {
  AppUpdateService({
    FirebaseRemoteConfig Function()? remoteConfig,
    Future<String> Function()? currentVersion,
    DateTime Function()? clock,
  }) : _remoteConfig = remoteConfig ?? (() => FirebaseRemoteConfig.instance),
       _currentVersion = currentVersion ?? _installedVersion,
       _clock = clock ?? DateTime.now;

  final FirebaseRemoteConfig Function() _remoteConfig;
  final Future<String> Function() _currentVersion;
  final DateTime Function() _clock;

  static const _snoozedVersionKey = 'update_snoozed_version';
  static const _snoozedAtKey = 'update_snoozed_at';

  static bool _configured = false;

  static Future<String> _installedVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
  }

  /// Fetch settings once per app run. Values are cached for an hour (none in
  /// debug, to try changes at once); a console publish also arrives live and
  /// is picked up on the next check.
  Future<void> _configure(FirebaseRemoteConfig rc) async {
    if (_configured) return;
    _configured = true;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );
    rc.onConfigUpdated.listen(
      (_) => rc.activate(),
      onError: (Object e) => debugPrint('Remote Config updates: $e'),
    );
  }

  /// The update to show now, or [UpdateStatus.none]. Optional updates the
  /// user snoozed within the last day are reported as none. Never throws:
  /// any failure (offline, nothing published) means "no reminder".
  Future<UpdateCheck> check() async {
    try {
      final current = await _currentVersion();
      final rc = _remoteConfig();
      await _configure(rc);
      try {
        await rc.fetchAndActivate();
      } catch (e) {
        // Offline / throttled: fall back to the last activated values.
        debugPrint('Remote Config fetch failed: $e');
      }
      final config = AppVersionConfig.fromRemoteValues(rc.getString);
      final status = updateStatusFor(current, config);
      if (status == UpdateStatus.optional) {
        final prefs = await SharedPreferences.getInstance();
        final at = prefs.getInt(_snoozedAtKey);
        final remind = shouldRemind(
          latestVersion: config!.latestVersion,
          snoozedVersion: prefs.getString(_snoozedVersionKey),
          snoozedAt: at == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(at),
          now: _clock(),
        );
        if (!remind) return UpdateCheck(UpdateStatus.none, config, current);
      }
      return UpdateCheck(status, config, current);
    } catch (e) {
      debugPrint('Update check failed: $e');
      return const UpdateCheck(UpdateStatus.none, null, '');
    }
  }

  /// "Later": hide the reminder for [latestVersion] for a day.
  Future<void> snooze(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snoozedVersionKey, latestVersion);
    await prefs.setInt(_snoozedAtKey, _clock().millisecondsSinceEpoch);
  }
}
