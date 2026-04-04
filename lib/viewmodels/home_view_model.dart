import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kottra_app/services/auth_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({AuthServiceBase? authService, FirebaseAuth? firebaseAuth})
    : _authService = authService ?? AuthService(),
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthServiceBase _authService;
  final FirebaseAuth _firebaseAuth;

  String get userLabel {
    final User? currentUser = _firebaseAuth.currentUser;
    return currentUser?.email ?? currentUser?.uid ?? 'Authenticated user';
  }

  Future<void> logout() {
    return _authService.signOut();
  }
}
