import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/screens/scan/attendance_qr.dart';

void main() {
  group('parseAttendanceQrStoreId', () {
    test('extracts the store id from a valid payload', () {
      expect(parseAttendanceQrStoreId('kottra-attendance:store-123'),
          'store-123');
    });

    test('tolerates surrounding whitespace', () {
      expect(parseAttendanceQrStoreId('  kottra-attendance:store-123  '),
          'store-123');
    });

    test('round-trips with buildAttendanceQrPayload', () {
      final payload = buildAttendanceQrPayload('abc');
      expect(parseAttendanceQrStoreId(payload), 'abc');
    });

    test('rejects an unrelated code', () {
      expect(parseAttendanceQrStoreId('https://example.com'), isNull);
      expect(parseAttendanceQrStoreId('other-prefix:store-123'), isNull);
      expect(parseAttendanceQrStoreId('kottra-attendance:'), isNull);
      expect(parseAttendanceQrStoreId(null), isNull);
    });
  });

  group('validateAttendanceQr', () {
    test('valid when the store matches', () {
      expect(
        validateAttendanceQr('kottra-attendance:s1', 's1'),
        AttendanceQrResult.valid,
      );
    });

    test('wrongStore when a valid code targets another store', () {
      expect(
        validateAttendanceQr('kottra-attendance:s2', 's1'),
        AttendanceQrResult.wrongStore,
      );
    });

    test('invalid when the code is not ours', () {
      expect(
        validateAttendanceQr('garbage', 's1'),
        AttendanceQrResult.invalid,
      );
    });
  });
}
