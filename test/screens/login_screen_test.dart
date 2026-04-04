import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/screens/login_screen.dart';
import 'package:kottra_app/services/auth_service.dart';
import 'package:kottra_app/viewmodels/login_view_model.dart';

class FakeAuthService implements AuthServiceBase {
  FakeAuthService({
    this.onEmailPasswordSignIn,
    this.onGoogleSignIn,
    this.onTokenSignIn,
  });

  Future<void> Function(String email, String password)? onEmailPasswordSignIn;
  Future<void> Function()? onGoogleSignIn;
  Future<void> Function(String token)? onTokenSignIn;

  int emailPasswordLoginCalls = 0;

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    emailPasswordLoginCalls++;
    await onEmailPasswordSignIn?.call(email, password);
  }

  @override
  Future<void> signInWithGoogle() async => onGoogleSignIn?.call();

  @override
  Future<void> signInWithEmployeeToken(String loginToken) async =>
      onTokenSignIn?.call(loginToken);

  @override
  Future<void> signOut() async {}
}

GoRouter _createRouter({required LoginViewModel viewModel}) {
  return GoRouter(
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return LoginScreen(viewModel: viewModel);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Text('Home Page'));
        },
      ),
    ],
  );
}

void main() {
  testWidgets('navigates to home after email login succeeds', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService();
    final LoginViewModel viewModel = LoginViewModel(authService: authService);
    final GoRouter router = _createRouter(viewModel: viewModel);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Login with Email'));
    await tester.pumpAndSettle();

    expect(authService.emailPasswordLoginCalls, 1);
    expect(find.text('Home Page'), findsOneWidget);

    viewModel.dispose();
  });

  testWidgets('shows an error message when email login fails', (
    WidgetTester tester,
  ) async {
    final FakeAuthService authService = FakeAuthService(
      onEmailPasswordSignIn: (String email, String password) async {
        throw Exception('Invalid credentials');
      },
    );
    final LoginViewModel viewModel = LoginViewModel(authService: authService);
    final GoRouter router = _createRouter(viewModel: viewModel);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.text('Login with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(find.text('Home Page'), findsNothing);

    viewModel.dispose();
  });
}
