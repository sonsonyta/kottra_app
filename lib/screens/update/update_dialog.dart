import 'package:flutter/material.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/app_version_config.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/services/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

bool _dialogOpen = false;

/// Checks for a new release and, if there is one, shows the update dialog:
/// "Update available" (Update / Later) or, below `minVersion`, a blocking
/// "Update required". Safe to call on every app start or resume.
Future<void> checkForAppUpdate(
  BuildContext context, {
  AppUpdateService? service,
}) async {
  if (_dialogOpen) return;
  final updates = service ?? AppUpdateService();
  final result = await updates.check();
  if (result.status == UpdateStatus.none || !context.mounted || _dialogOpen) {
    return;
  }
  _dialogOpen = true;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: result.status == UpdateStatus.optional,
      builder: (_) => UpdateDialog(
        check: result,
        onLater: () => updates.snooze(result.config!.latestVersion),
      ),
    );
  } finally {
    _dialogOpen = false;
  }
}

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.check, required this.onLater});

  final UpdateCheck check;
  final Future<void> Function() onLater;

  bool get _required => check.status == UpdateStatus.required;

  Future<void> _openStore(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(check.storeUrl),
      mode: LaunchMode.externalApplication,
    );
    // A required update stays open so the old build can't be used.
    if (ok && !_required && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = appColors(context);
    final config = check.config!;
    final notes = config.notesFor(Localizations.localeOf(context).languageCode);

    return PopScope(
      // Back button can't close a required update.
      canPop: !_required,
      child: AlertDialog(
        icon: Icon(Icons.system_update_rounded, color: c.primary, size: 36),
        title: Text(
          _required ? l10n.updateRequiredTitle : l10n.updateAvailableTitle,
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _required
                  ? l10n.updateRequiredMessage(config.latestVersion)
                  : l10n.updateAvailableMessage(config.latestVersion),
              style: TextStyle(color: c.textSecondary),
            ),
            if (notes != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.updateWhatsNew,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(notes, style: TextStyle(color: c.textSecondary)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.updateCurrentVersion(check.currentVersion.split('+').first),
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (!_required)
            TextButton(
              onPressed: () async {
                await onLater();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                l10n.updateLater,
                style: TextStyle(color: c.textSecondary),
              ),
            ),
          ElevatedButton(
            onPressed: () => _openStore(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
  }
}
