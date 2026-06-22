import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kottra_app/firebase_options.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/view_models/employee_identity.dart';

const _employeeLoginToken = '7pZXQuJa7YXWCdkkQV3e0bxBrjz5wd-H';
const _latitude = '11.568574105178529';
const _longitude = '104.87069224278316';

double? _parseCoord(String raw) => raw.isEmpty ? null : double.parse(raw);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'employeeCheckIn reaches live Cloud Functions',
    skip: _employeeLoginToken.isEmpty,
    (tester) async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

      await FirebaseAuth.instance.signOut();

      final authService = AuthService();
      final attendanceService = AttendanceService();

      await authService.signInWithEmployeeToken(_employeeLoginToken);

      final currentUser = FirebaseAuth.instance.currentUser;
      expect(currentUser, isNotNull, reason: 'Expected employee auth session.');

      final identity = parseEmployeeUid(currentUser!.uid);
      expect(
        identity,
        isNotNull,
        reason: 'Expected UID in the form hr_employee:<storeId>:<employeeId>.',
      );

      final result = await attendanceService.checkIn(
        storeId: identity!.storeId,
        employeeId: identity.employeeId,
        latitude: _parseCoord(_latitude),
        longitude: _parseCoord(_longitude),
      );

      expect(result.success, isTrue);
      expect(result.attendanceId, isNotEmpty);
      expect(
        result.status,
        anyOf(AttendanceStatus.present, AttendanceStatus.late),
      );
    },
  );
}
