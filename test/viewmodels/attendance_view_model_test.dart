import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/services/attendance_service.dart';
import 'package:kottra_app/services/location_service.dart';
import 'package:kottra_app/viewmodels/attendance_view_model.dart';

class FakeUser implements User {
  FakeUser({required this.uid});

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.user});

  final User? user;

  @override
  User? get currentUser => user;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeAttendanceService implements AttendanceService {
  String? lastStoreId;
  String? lastEmployeeId;
  String? lastAttendanceId;
  double? lastLatitude;
  double? lastLongitude;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  Object? checkInError;
  CheckInResult checkInResult = const CheckInResult(
    success: true,
    alreadyCheckedIn: false,
    attendanceId: 'att-1',
    status: AttendanceStatus.present,
  );

  @override
  Future<CheckInResult> checkIn({
    required String storeId,
    required String employeeId,
    double? latitude,
    double? longitude,
  }) async {
    checkInCalls++;
    lastStoreId = storeId;
    lastEmployeeId = employeeId;
    lastLatitude = latitude;
    lastLongitude = longitude;

    if (checkInError != null) throw checkInError!;
    return checkInResult;
  }

  @override
  Future<CheckOutResult> checkOut({
    required String storeId,
    required String attendanceId,
    required String employeeId,
    double? latitude,
    double? longitude,
  }) async {
    checkOutCalls++;
    lastStoreId = storeId;
    lastEmployeeId = employeeId;
    lastAttendanceId = attendanceId;
    lastLatitude = latitude;
    lastLongitude = longitude;
  }

  @override
  Stream<List<AttendanceRecord>> streamHistory(
    String storeId,
    String employeeId, {
    int limit = 30,
  }) => Stream.value(const []);

  @override
  Stream<AttendanceRecord?> streamTodayRecord(
    String storeId,
    String employeeId,
  ) => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeLocationService implements LocationServiceBase {
  FakeLocationService({this.coords, this.error});

  final LocationCoords? coords;
  final Object? error;
  int calls = 0;

  @override
  Future<LocationCoords?> getCurrentCoords() async {
    calls++;
    if (error != null) throw error!;
    return coords;
  }
}

void main() {
  group('AttendanceViewModel.checkIn', () {
    test('passes identity and coordinates to attendance service', () async {
      final attendanceService = FakeAttendanceService();
      final locationService = FakeLocationService(
        coords: const LocationCoords(latitude: 11.5564, longitude: 104.9282),
      );
      final viewModel = AttendanceViewModel(
        firebaseAuth: FakeFirebaseAuth(
          user: FakeUser(uid: 'hr_employee:store-1:emp-1'),
        ),
        attendanceService: attendanceService,
        locationService: locationService,
      );

      final result = await viewModel.checkIn();

      expect(result, isNotNull);
      expect(result!.attendanceId, 'att-1');
      expect(locationService.calls, 1);
      expect(attendanceService.checkInCalls, 1);
      expect(attendanceService.lastStoreId, 'store-1');
      expect(attendanceService.lastEmployeeId, 'emp-1');
      expect(attendanceService.lastLatitude, 11.5564);
      expect(attendanceService.lastLongitude, 104.9282);
      expect(viewModel.isCheckedIn, isTrue);
      expect(viewModel.isActionLoading, isFalse);

      viewModel.dispose();
    });

    test('toggles loading state and resets it when check-in fails', () async {
      final attendanceService = FakeAttendanceService()
        ..checkInError = StateError('boom');
      final viewModel = AttendanceViewModel(
        firebaseAuth: FakeFirebaseAuth(
          user: FakeUser(uid: 'hr_employee:store-1:emp-1'),
        ),
        attendanceService: attendanceService,
        locationService: FakeLocationService(),
      );
      final loadingStates = <bool>[];

      viewModel.addListener(() {
        loadingStates.add(viewModel.isActionLoading);
      });

      await expectLater(viewModel.checkIn(), throwsA(isA<StateError>()));

      expect(loadingStates, containsAllInOrder([true, false]));
      expect(viewModel.isActionLoading, isFalse);

      viewModel.dispose();
    });

    test(
      'returns null without calling dependencies when identity is invalid',
      () async {
        final attendanceService = FakeAttendanceService();
        final locationService = FakeLocationService();
        final viewModel = AttendanceViewModel(
          firebaseAuth: FakeFirebaseAuth(user: FakeUser(uid: 'invalid-user-id')),
          attendanceService: attendanceService,
          locationService: locationService,
        );

        final result = await viewModel.checkIn();

        expect(result, isNull);
        expect(locationService.calls, 0);
        expect(attendanceService.checkInCalls, 0);
        expect(viewModel.isActionLoading, isFalse);

        viewModel.dispose();
      },
    );
  });
}
