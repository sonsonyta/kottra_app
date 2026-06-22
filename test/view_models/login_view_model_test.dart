import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/view_models/login_view_model.dart';

class FakeAuthService implements AuthServiceBase {
  FakeAuthService({
    this.onEmailPasswordSignIn,
    this.onGoogleSignIn,
    this.onTokenSignIn,
  });

  Future<void> Function(String email, String password)? onEmailPasswordSignIn;
  Future<void> Function()? onGoogleSignIn;
  Future<void> Function(String token)? onTokenSignIn;

  String? lastEmail;
  String? lastPassword;
  String? lastToken;
  int emailPasswordLoginCalls = 0;
  int googleLoginCalls = 0;
  int tokenLoginCalls = 0;

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    emailPasswordLoginCalls++;
    lastEmail = email;
    lastPassword = password;
    await onEmailPasswordSignIn?.call(email, password);
  }

  @override
  Future<void> signInWithGoogle() async {
    googleLoginCalls++;
    await onGoogleSignIn?.call();
  }

  @override
  Future<void> signInWithEmployeeToken(String loginToken) async {
    tokenLoginCalls++;
    lastToken = loginToken;
    await onTokenSignIn?.call(loginToken);
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  group('LoginViewModel', () {
    test('logs in with email and password successfully', () async {
      final FakeAuthService authService = FakeAuthService();
      final LoginViewModel viewModel = LoginViewModel(authService: authService);

      viewModel.emailController.text = ' employee@example.com ';
      viewModel.passwordController.text = 'secret123';

      final bool result = await viewModel.loginWithEmailPassword();

      expect(result, isTrue);
      expect(authService.emailPasswordLoginCalls, 1);
      expect(authService.lastEmail, 'employee@example.com');
      expect(authService.lastPassword, 'secret123');
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);

      viewModel.dispose();
    });

    test(
      'returns validation error when email or password is missing',
      () async {
        final LoginViewModel viewModel = LoginViewModel(
          authService: FakeAuthService(),
        );

        viewModel.emailController.text = '';
        viewModel.passwordController.text = '';

        final bool result = await viewModel.loginWithEmailPassword();

        expect(result, isFalse);
        expect(viewModel.errorMessage, 'Please enter both email and password.');
        expect(viewModel.isLoading, isFalse);

        viewModel.dispose();
      },
    );

    test('logs in with token successfully', () async {
      final FakeAuthService authService = FakeAuthService();
      final LoginViewModel viewModel = LoginViewModel(authService: authService);

      viewModel.tokenController.text = ' employee-token ';

      final bool result = await viewModel.loginWithToken();

      expect(result, isTrue);
      expect(authService.tokenLoginCalls, 1);
      expect(authService.lastToken, 'employee-token');
      expect(viewModel.errorMessage, isNull);

      viewModel.dispose();
    });

    test('surfaces service errors from Google sign in', () async {
      final LoginViewModel viewModel = LoginViewModel(
        authService: FakeAuthService(
          onGoogleSignIn: () async {
            throw Exception('Google login failed.');
          },
        ),
      );

      final bool result = await viewModel.loginWithGoogle();

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'Google login failed.');
      expect(viewModel.isLoading, isFalse);

      viewModel.dispose();
    });
  });
}
