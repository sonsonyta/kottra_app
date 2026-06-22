import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kottra_app/firebase_options.dart';
import 'package:kottra_app/router/app_router.dart';
import 'package:kottra_app/theme/app_theme.dart';
import 'package:kottra_app/theme/theme_controller.dart';
import 'package:kottra_app/theme/locale_controller.dart';
import 'package:kottra_app/services/notification_service.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_localizations.dart';

import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await NotificationService.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService.instance.setupForegroundMessaging();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await ThemeController.instance.load();
  await LocaleController.instance.load();

  if (kDebugMode) {

    final String localHostString = defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

    await FirebaseAuth.instance.useAuthEmulator(localHostString, 9099);
    FirebaseFunctions.instance.useFunctionsEmulator(localHostString, 5001);
    FirebaseFunctions.instanceFor(region: 'asia-southeast1').useFunctionsEmulator(localHostString, 5001);
    FirebaseFirestore.instance.useFirestoreEmulator(localHostString, 8080);
    
    // Clear persistence to prevent emulator cache issues where data does not update
    await FirebaseFirestore.instance.clearPersistence();

    await FirebaseStorage.instance.useStorageEmulator(localHostString, 9199);

    /*await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
      providerApple: const AppleDebugProvider()
    );*/
  }else{
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestProvider(),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeController.instance, LocaleController.instance]),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Kottra App',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: ThemeController.instance.mode,
          locale: LocaleController.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        );
      },
    );
  }
}
