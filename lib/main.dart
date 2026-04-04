import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kottra_app/firebase_options.dart';
import 'package:kottra_app/router/app_router.dart';

const Color _brandBlue = Color(0xFF2579A6);
const BorderRadius _inputBorderRadius = BorderRadius.all(Radius.circular(18));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _brandBlue);

    return MaterialApp.router(
      title: 'Kottra App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
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
          cursorColor: _brandBlue,
          selectionHandleColor: _brandBlue,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
