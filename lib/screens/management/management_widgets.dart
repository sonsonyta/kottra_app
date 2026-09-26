import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';

// Widgets and helpers shared by the store-management tabs.

/// Two-letter initials from a name, for avatar fallbacks.
String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : 'U';
}

/// Confirmation dialog with an optional note. Returns the (possibly empty)
/// note when confirmed, or null when dismissed.
Future<String?> promptDecision(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'Reason shown to the employee',
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

class SectionHeaderText extends StatelessWidget {
  const SectionHeaderText({super.key, required this.text, required this.color});

  final String text;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color.textPrimary,
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dateLine,
    required this.reason,
    required this.statusLabel,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
    this.detail,
    this.actionedBy,
    this.actionedAt,
    this.actionNote,
  });

  final String title;
  final String subtitle;
  final String dateLine;
  final String reason;
  final String statusLabel;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  /// Optional extra line under the date (e.g. the originally requested type).
  final String? detail;

  /// Approver's display name, or null while it's still being resolved.
  final String? actionedBy;
  final DateTime? actionedAt;
  final String? actionNote;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final note = actionNote?.trim() ?? '';
    final showDecision =
        !isPending &&
        (actionedBy != null || actionedAt != null || note.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusChip(label: statusLabel, color: c),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: c.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(dateLine, style: TextStyle(color: c.textSecondary)),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(reason, style: TextStyle(fontSize: 14, color: c.textPrimary)),
          ],
          if (showDecision) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: c.textSecondary.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            _DecisionLine(
              icon: Icons.person_outline_rounded,
              text: '$statusLabel by ${actionedBy ?? '…'}',
              color: c,
            ),
            if (actionedAt != null) ...[
              const SizedBox(height: 4),
              _DecisionLine(
                icon: Icons.schedule_rounded,
                text: DateFormat('EEE, d MMM yyyy · HH:mm').format(actionedAt!),
                color: c,
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              _DecisionLine(
                icon: Icons.notes_rounded,
                text: note,
                color: c,
                italic: true,
              ),
            ],
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: c.error),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DecisionLine extends StatelessWidget {
  const _DecisionLine({
    required this.icon,
    required this.text,
    required this.color,
    this.italic = false,
  });

  final IconData icon;
  final String text;
  final AppColors color;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color.textSecondary,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    Color fg;
    if (lower == 'approved' || lower == 'present') {
      fg = color.success;
    } else if (lower == 'rejected' || lower == 'absent') {
      fg = color.error;
    } else if (lower == 'pending' || lower == 'late') {
      fg = color.warning;
    } else {
      fg = color.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class TabWithBadge extends StatelessWidget {
  const TabWithBadge({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            CountBadge(count: count, color: color),
          ],
        ],
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.color});

  final int count;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: c.textSecondary),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: c.textSecondary)),
        ],
      ),
    );
  }
}
