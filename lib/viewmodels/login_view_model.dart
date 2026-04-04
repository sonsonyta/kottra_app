import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kottra_app/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthServiceBase? authService})
    : _authService = authService ?? AuthService();

  final AuthServiceBase _authService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loginWithEmailPassword() async {
    return _runAuthAction(() async {
      final String email = emailController.text.trim();
      final String password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Please enter both email and password.');
      }

      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<bool> loginWithGoogle() async {
    return _runAuthAction(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<bool> loginWithToken() async {
    return _runAuthAction(() async {
      final String token = tokenController.text.trim();
      if (token.isEmpty) {
        throw Exception('Please enter a login token.');
      }

      await _authService.signInWithEmployeeToken(token);
    });
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on Exception catch (error) {
      _errorMessage = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatError(Exception error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'Firebase authentication failed.';
    }
    if (error is FirebaseFunctionsException) {
      return error.message ?? 'Cloud Function call failed.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    tokenController.dispose();
    super.dispose();
  }
}
