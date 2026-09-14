import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/theme/locale_controller.dart';

String fmtTime(DateTime? t) {
  if (t == null) return '--:--';
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

String fmtDateShort(DateTime d) =>
    DateFormat.MMMEd(LocaleController.instance.locale.languageCode).format(d);

String fmtDateFull(DateTime d) =>
    DateFormat.yMMMMEEEEd(LocaleController.instance.locale.languageCode)
        .format(d);

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Rewrites a stored Storage download URL for the current platform in debug.
///
/// Uploads canonicalize emulator URLs to the `localhost` host (see the upload
/// services); the Android emulator can't reach `localhost`/`127.0.0.1` and must
/// use `10.0.2.2`. A no-op in release and for null/real URLs.
String? resolveStorageUrl(String? url) {
  if (url == null) return null;
  if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
    return url
        .replaceFirst('localhost', '10.0.2.2')
        .replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return url;
}

String fmtMoney(double amount, String currency) {
  final isUsd = currency == 'USD';
  final symbol = isUsd ? '\$' : '៛';
  final value = isUsd
      ? amount.toStringAsFixed(2)
      : amount.toStringAsFixed(0);
  return '$symbol$value';
}
