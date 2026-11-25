import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/app_version_config.dart';
import 'package:kottra_app/screens/update/update_dialog.dart';
import 'package:kottra_app/services/app_update_service.dart';

Widget _host(UpdateCheck check, Future<void> Function() onLater) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          barrierDismissible: check.status == UpdateStatus.optional,
          builder: (_) => UpdateDialog(check: check, onLater: onLater),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  const config = AppVersionConfig(
    latestVersion: '1.9.8',
    androidUrl: 'https://example.com/app',
    releaseNotes: 'Holiday pay on payslips',
  );

  testWidgets('optional update shows notes, and Later snoozes and closes', (
    tester,
  ) async {
    var snoozed = 0;
    await tester.pumpWidget(
      _host(
        const UpdateCheck(UpdateStatus.optional, config, '1.9.7+29'),
        () async => snoozed++,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Holiday pay on payslips'), findsOneWidget);
    expect(find.text('Installed version: 1.9.7'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(snoozed, 1);
    expect(find.text('Update available'), findsNothing);
  });

  test('store links default to the app listings', () {
    const bare = AppVersionConfig(latestVersion: '1.9.8');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      const UpdateCheck(UpdateStatus.optional, bare, '1.9.7').storeUrl,
      defaultIosStoreUrl,
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      const UpdateCheck(UpdateStatus.optional, bare, '1.9.7').storeUrl,
      'https://play.google.com/store/apps/details?id=app.kottra.mobile',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('required update has no Later and survives the back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const UpdateCheck(UpdateStatus.required, config, '1.9.0+10'),
        () async {},
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Later'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
  });
}
