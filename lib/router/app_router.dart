import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/screens/login_screen.dart';
import 'package:kottra_app/screens/main_screen.dart';
import 'package:kottra_app/screens/manager_screen.dart';
import 'package:kottra_app/view_models/employee_identity.dart';
import 'package:kottra_app/screens/leave/leave_list_screen.dart';
import 'package:kottra_app/screens/leave/request_leave_screen.dart';
import 'package:kottra_app/screens/advance/advance_list_screen.dart';
import 'package:kottra_app/screens/advance/request_advance_screen.dart';
import 'package:kottra_app/screens/late_excuse/late_excuse_list_screen.dart';
import 'package:kottra_app/screens/late_excuse/request_late_excuse_screen.dart';
import 'package:kottra_app/screens/schedule/schedule_screen.dart';
import 'package:kottra_app/view_models/leave_view_model.dart';
import 'package:kottra_app/view_models/salary_advance_view_model.dart';
import 'package:kottra_app/view_models/late_excuse_view_model.dart';
import 'package:kottra_app/view_models/profile_view_model.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/main',
  refreshListenable: _GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;
    final bool isOnLoginPage = state.matchedLocation == '/login';

    if (!isLoggedIn) {
      return isOnLoginPage ? null : '/login';
    }

    // Employee-token logins get the employee UI (`/main`); everyone else
    // (email/password store users) gets the management UI (`/manager`). The
    // login method is inferred from the UID shape (see `isEmployeeUid`).
    final String home = isEmployeeUid(user.uid) ? '/main' : '/manager';
    final bool isOnHome = state.matchedLocation == home;

    // Send users to their home from the login page, and keep them out of the
    // other role's home. Deeper routes (e.g. `/leaves`) are left untouched.
    if (isOnLoginPage ||
        (home == '/main' && state.matchedLocation == '/manager') ||
        (home == '/manager' && state.matchedLocation == '/main')) {
      return isOnHome ? null : home;
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    GoRoute(
      path: '/manager',
      builder: (context, state) => const ManagerScreen(),
    ),
    GoRoute(
      path: '/leaves',
      redirect: (context, state) =>
          state.extra is ProfileViewModel ? null : '/main',
      builder: (context, state) {
        final profileViewModel = state.extra as ProfileViewModel;
        return LeaveListScreen(profileViewModel: profileViewModel);
      },
    ),
    GoRoute(
      path: '/leaves/request',
      redirect: (context, state) =>
          state.extra is LeaveViewModel ? null : '/main',
      builder: (context, state) {
        final viewModel = state.extra as LeaveViewModel;
        return RequestLeaveScreen(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: '/advances',
      redirect: (context, state) =>
          state.extra is ProfileViewModel ? null : '/main',
      builder: (context, state) {
        final profileViewModel = state.extra as ProfileViewModel;
        return AdvanceListScreen(profileViewModel: profileViewModel);
      },
    ),
    GoRoute(
      path: '/advances/request',
      redirect: (context, state) =>
          state.extra is SalaryAdvanceViewModel ? null : '/main',
      builder: (context, state) {
        final viewModel = state.extra as SalaryAdvanceViewModel;
        return RequestAdvanceScreen(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: '/late-excuses',
      redirect: (context, state) =>
          state.extra is ProfileViewModel ? null : '/main',
      builder: (context, state) {
        final profileViewModel = state.extra as ProfileViewModel;
        return LateExcuseListScreen(profileViewModel: profileViewModel);
      },
    ),
    GoRoute(
      path: '/late-excuses/request',
      redirect: (context, state) =>
          state.extra is LateExcuseViewModel ? null : '/main',
      builder: (context, state) {
        final viewModel = state.extra as LateExcuseViewModel;
        return RequestLateExcuseScreen(viewModel: viewModel);
      },
    ),
    GoRoute(
      path: '/schedule',
      redirect: (context, state) =>
          state.extra is ProfileViewModel ? null : '/main',
      builder: (context, state) {
        final profileViewModel = state.extra as ProfileViewModel;
        return ScheduleScreen(profileViewModel: profileViewModel);
      },
    ),
  ],
);
