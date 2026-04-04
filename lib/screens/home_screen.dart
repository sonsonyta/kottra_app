import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/viewmodels/home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 120, width: 120),
            const SizedBox(height: 24),
            Text('Welcome, ${_viewModel.userLabel}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _viewModel.logout();
                if (!context.mounted) {
                  return;
                }
                context.go('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
