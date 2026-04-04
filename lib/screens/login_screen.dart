import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/viewmodels/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.viewModel});

  final LoginViewModel? viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? LoginViewModel();
    _ownsViewModel = widget.viewModel == null;
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _handleLogin(Future<bool> Function() loginAction) async {
    FocusScope.of(context).unfocus();
    final bool isSuccess = await loginAction();
    if (!mounted || !isSuccess) {
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/logo.png', height: 120, width: 120),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _viewModel.emailController,
                      enabled: !_viewModel.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _viewModel.passwordController,
                      enabled: !_viewModel.isLoading,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () =>
                                _handleLogin(_viewModel.loginWithEmailPassword),
                      child: const Text('Login with Email'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () => _handleLogin(_viewModel.loginWithGoogle),
                      child: const Text('Login with Google'),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _viewModel.tokenController,
                      enabled: !_viewModel.isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Employee Login Token',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () => _handleLogin(_viewModel.loginWithToken),
                      child: const Text('Login with Token'),
                    ),
                    if (_viewModel.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_viewModel.isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
