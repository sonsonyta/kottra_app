import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kottra_app/firebase_options.dart';
import 'package:kottra_app/router/app_router.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';

const BorderRadius _inputBorderRadius = BorderRadius.all(Radius.circular(18));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      surface: kSurface,
      error: kError,
    );

    return MaterialApp.router(
      title: 'Kottra App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: kBackground,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: colorScheme.primary),
          floatingLabelStyle: TextStyle(color: colorScheme.primary),
          enabledBorder: OutlineInputBorder(
            borderRadius: _inputBorderRadius,
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _inputBorderRadius,
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: _inputBorderRadius,
            borderSide: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: kPrimary,
          selectionHandleColor: kPrimary,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
