import 'package:flutter/material.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';

// ── Avatar ────────────────────────────────────────────────────────────────────

class TabAvatar extends StatelessWidget {
  const TabAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.imageUrl,
    this.useGradient = false,
  });

  final String initials;
  final double size;
  final String? imageUrl;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsWidget(context),
        ),
      );
    }
    return _initialsWidget(context);
  }

  Widget _initialsWidget(BuildContext context) {
    final c = appColors(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, c.primaryDark],
              )
            : null,
        color: useGradient ? null : Colors.white.withValues(alpha: 0.2),
        border: useGradient
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: c.textPrimary,
      ),
    );
  }
}

// ── Attendance List Item ──────────────────────────────────────────────────────

class AttendanceListItem extends StatelessWidget {
  const AttendanceListItem({super.key, required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final cfg = _statusConfig(record.status, c);
    final displayDate = record.checkIn ?? record.checkOut ?? record.date.toDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.shadowSubtle,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cfg.background,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${displayDate.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: cfg.color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (record.checkIn != null)
                  Text(
                    'In: ${fmtDateShort(record.checkIn!)} ${fmtTime(record.checkIn)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                if (record.checkOut != null) ...[
                  if (record.checkIn != null) const SizedBox(height: 4),
                  Text(
                    'Out: ${fmtDateShort(record.checkOut!)} ${fmtTime(record.checkOut)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
                if (record.checkIn == null && record.checkOut == null) ...[
                  Text(
                    fmtDateShort(record.date.toDate()),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.status == AttendanceStatus.absent
                        ? 'No attendance recorded'
                        : record.status == AttendanceStatus.leave
                            ? record.leaveNote ?? 'On leave'
                            : record.status == AttendanceStatus.holiday
                                ? 'Public holiday'
                                : '--:--',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cfg.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cfg.color,
                  ),
                ),
              ),
              if (record.duration != null) ...[
                const SizedBox(height: 4),
                Text(
                  fmtDuration(record.duration!),
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  StatusConfig _statusConfig(AttendanceStatus status, AppColors c) {
    return switch (status) {
      AttendanceStatus.present => StatusConfig(
          label: 'Present',
          color: c.success,
          background: c.successLight,
        ),
      AttendanceStatus.late => StatusConfig(
          label: 'Late',
          color: c.warning,
          background: c.warningLight,
        ),
      AttendanceStatus.absent => StatusConfig(
          label: 'Absent',
          color: c.error,
          background: c.errorLight,
        ),
      AttendanceStatus.leave => StatusConfig(
          label: 'Leave',
          color: c.primary,
          background: c.infoLight,
        ),
      AttendanceStatus.holiday => StatusConfig(
          label: 'Holiday',
          color: c.holiday,
          background: c.holidayLight,
        ),
    };
  }
}

class StatusConfig {
  const StatusConfig({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;
}
