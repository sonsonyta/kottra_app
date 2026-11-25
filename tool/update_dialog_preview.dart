// Dev-only preview of the app update dialog — no Firebase, no sign-in.
//   flutter run -t tool/update_dialog_preview.dart
import 'package:flutter/material.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/app_version_config.dart';
import 'package:kottra_app/screens/update/update_dialog.dart';
import 'package:kottra_app/services/app_update_service.dart';
import 'package:kottra_app/theme/app_theme.dart';

void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  Locale _locale = const Locale('en');
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _mode,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _PreviewHome(
        onLocale: (l) => setState(() => _locale = l),
        onDark: (d) =>
            setState(() => _mode = d ? ThemeMode.dark : ThemeMode.light),
        dark: _mode == ThemeMode.dark,
        locale: _locale,
      ),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome({
    required this.onLocale,
    required this.onDark,
    required this.dark,
    required this.locale,
  });

  final ValueChanged<Locale> onLocale;
  final ValueChanged<bool> onDark;
  final bool dark;
  final Locale locale;

  static const _config = AppVersionConfig(
    latestVersion: '1.9.8',
    minVersion: '1.9.8',
    releaseNotes:
        '• Extra pay for working on public holidays\n• No late deduction on holidays\n• Update reminders',
    releaseNotesKH:
        '• ប្រាក់បន្ថែមសម្រាប់ការធ្វើការថ្ងៃបុណ្យ\n• មិនកាត់ប្រាក់មកយឺតនៅថ្ងៃបុណ្យ\n• ការរំលឹកធ្វើបច្ចុប្បន្នភាព',
  );

  void _show(BuildContext context, UpdateStatus status) {
    showDialog<void>(
      context: context,
      barrierDismissible: status == UpdateStatus.optional,
      builder: (_) => UpdateDialog(
        check: UpdateCheck(status, _config, '1.9.7+29'),
        onLater: () async {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update dialog preview')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'km', label: Text('ខ្មែរ')),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) => onLocale(Locale(s.first)),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: dark,
            onChanged: onDark,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('optional'),
            onPressed: () => _show(context, UpdateStatus.optional),
            child: const Text('Show "Update available"'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('required'),
            onPressed: () => _show(context, UpdateStatus.required),
            child: const Text('Show "Update required"'),
          ),
        ],
      ),
    );
  }
}
