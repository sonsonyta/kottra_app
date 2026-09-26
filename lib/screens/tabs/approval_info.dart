import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/services/actor_name_service.dart';

/// Who approved/rejected a request, when, and their note — shown on the
/// employee's own leave, late-excuse and salary-advance cards once decided.
class ApprovalInfo extends StatelessWidget {
  const ApprovalInfo({
    super.key,
    required this.rejected,
    this.actionedBy,
    this.actionedAt,
    this.note,
  });

  final bool rejected;
  final String? actionedBy;
  final DateTime? actionedAt;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final trimmedNote = note?.trim() ?? '';
    final hasActor = (actionedBy?.trim() ?? '').isNotEmpty;
    if (!hasActor && actionedAt == null && trimmedNote.isEmpty) {
      return const SizedBox.shrink();
    }

    final names = ActorNameService.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Divider(height: 1, color: c.textSecondary.withValues(alpha: 0.2)),
        const SizedBox(height: 10),
        if (hasActor)
          FutureBuilder<String?>(
            initialData: names.cachedName(actionedBy),
            future: names.resolve(actionedBy),
            builder: (context, snapshot) {
              final name = snapshot.data ?? '…';
              return _Line(
                icon: Icons.person_outline_rounded,
                text: rejected ? l10n.rejectedBy(name) : l10n.approvedBy(name),
              );
            },
          ),
        if (actionedAt != null) ...[
          if (hasActor) const SizedBox(height: 4),
          _Line(
            icon: Icons.schedule_rounded,
            text: DateFormat(
              'E, d MMM yyyy · HH:mm',
              locale,
            ).format(actionedAt!),
          ),
        ],
        if (trimmedNote.isNotEmpty) ...[
          const SizedBox(height: 4),
          _Line(
            icon: Icons.notes_rounded,
            text: trimmedNote,
            italic: true,
            color: rejected ? c.error : null,
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    this.italic = false,
    this.color,
  });

  final IconData icon;
  final String text;
  final bool italic;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? appColors(context).textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: fg,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
