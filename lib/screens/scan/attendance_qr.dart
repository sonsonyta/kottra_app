/// Parsing and validation for the store attendance QR code.
///
/// The store posts a static QR encoding its identity in the form
/// `kottra-attendance:<storeId>`. Employees scan it to check in/out; the app
/// verifies the encoded store matches their own store before proceeding.
///
/// The raw scanned string is also forwarded to the check-in Cloud Function
/// (`qrToken`), so the payload can later be upgraded to a signed/rotating token
/// verified server-side without changing the scanner UI.
library;

/// Prefix that marks a Kottra attendance QR code.
const String kAttendanceQrPrefix = 'kottra-attendance';

/// Outcome of scanning a QR code, distinguishing "wrong store" (a real but
/// mismatched code) from "not one of ours" so the UI can show the right hint.
enum AttendanceQrResult { valid, wrongStore, invalid }

/// Builds the canonical payload a store would encode for [storeId].
String buildAttendanceQrPayload(String storeId) =>
    '$kAttendanceQrPrefix:$storeId';

/// Extracts the store id from a scanned [raw] payload, or null if it isn't a
/// Kottra attendance code. Tolerates surrounding whitespace.
String? parseAttendanceQrStoreId(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  final sep = value.indexOf(':');
  if (sep <= 0) return null;
  if (value.substring(0, sep) != kAttendanceQrPrefix) return null;
  final storeId = value.substring(sep + 1).trim();
  return storeId.isEmpty ? null : storeId;
}

/// Validates a scanned [raw] payload against the [expectedStoreId].
AttendanceQrResult validateAttendanceQr(String? raw, String expectedStoreId) {
  final storeId = parseAttendanceQrStoreId(raw);
  if (storeId == null) return AttendanceQrResult.invalid;
  if (storeId != expectedStoreId) return AttendanceQrResult.wrongStore;
  return AttendanceQrResult.valid;
}
