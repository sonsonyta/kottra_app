import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../view_models/attendance_view_model.dart';
import '../../../view_models/main_view_model.dart';
import '../tab_colors.dart';
import '../tab_helpers.dart';

class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key, required this.viewModel, required this.attendanceViewModel});

  final MainViewModel viewModel;
  final AttendanceViewModel attendanceViewModel;

  String _formatCheckInError(Object error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? 'Check-in failed.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<String?> _promptForNote(BuildContext context, String action) async {
    final c = appColors(context);
    final textController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(action, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action == AppLocalizations.of(context)!.checkIn ? AppLocalizations.of(context)!.addNoteCheckInLate : AppLocalizations.of(context)!.addNoteCheckOutEarly, style: TextStyle(color: c.textSecondary, fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.noteRequired,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: c.surface,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // returns null, meaning cancel
              child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: c.textSecondary)),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: textController,
              builder: (context, value, child) {
                final isEnabled = value.text.trim().isNotEmpty;
                return ElevatedButton(
                  onPressed: isEnabled ? () => Navigator.of(context).pop(value.text.trim()) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(AppLocalizations.of(context)!.confirm),
                );
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _handleCheckIn(BuildContext context) async {
    String? note;
    if (attendanceViewModel.isLateCheckIn(viewModel.startWorkingTime, viewModel.lateTime)) {
      note = await _promptForNote(context, AppLocalizations.of(context)!.checkIn);
      if (note == null) return; // User cancelled
      if (!context.mounted) return;
    }

    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await attendanceViewModel.checkIn(lateCheckInNote: note?.isEmpty ?? true ? null : note);
      if (result == null) return;
      final String message;
      if (result.alreadyCheckedIn) {
        message = localizations.alreadyCheckedIn;
      } else if (result.success) {
        message = localizations.checkInSuccess(result.status.value);
      } else {
        message = localizations.checkInFailed;
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_formatCheckInError(error))),
      );
    }
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    String? note;
    if (attendanceViewModel.isEarlyCheckOut(viewModel.startWorkingTime, viewModel.endWorkingTime)) {
      note = await _promptForNote(context, AppLocalizations.of(context)!.checkOut);
      if (note == null) return; // User cancelled
      if (!context.mounted) return;
    }

    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await attendanceViewModel.checkOut(earlyCheckOutNote: note?.isEmpty ?? true ? null : note);
      if (result == null) return;
      final String message;
      if (result.alreadyCheckedOut) {
        message = localizations.alreadyCheckedOut;
      } else if (result.success) {
        message = localizations.checkOutSuccess;
      } else {
        message = localizations.checkOutFailed;
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_formatCheckInError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final isCheckedIn = attendanceViewModel.isCheckedIn;
    final checkInTime = attendanceViewModel.checkInTime;
    final checkOutTime = attendanceViewModel.checkOutTime;
    final isCheckedOut = !isCheckedIn && checkOutTime != null;

    Duration? elapsed;
    if (isCheckedIn && checkInTime != null) {
      elapsed = DateTime.now().difference(checkInTime);
    } else if (!isCheckedIn && checkInTime != null && checkOutTime != null) {
      elapsed = checkOutTime.difference(checkInTime);
    }

    final isOnLeave = attendanceViewModel.isOnLeave;
    final isAbsent = attendanceViewModel.isAbsent;
    final isDayOff = attendanceViewModel.isDayOff;
    final isBlocked = isOnLeave || isAbsent || isDayOff;
    final localizations = AppLocalizations.of(context)!;
    final blockedLabel = isOnLeave
        ? localizations.onLeave
        : isDayOff
            ? localizations.dayOff
            : localizations.absent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isBlocked
                      ? c.warningLight
                      : (isCheckedIn ? c.successLight : c.infoLight),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isBlocked
                            ? c.warning
                            : (isCheckedIn ? c.success : c.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBlocked
                          ? blockedLabel
                          : (isCheckedIn
                              ? AppLocalizations.of(context)!.checkedIn
                              : (isCheckedOut
                                  ? AppLocalizations.of(context)!.checkedOut
                                  : AppLocalizations.of(context)!.notCheckedIn)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isBlocked
                            ? c.warning
                            : (isCheckedIn ? c.success : c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (elapsed != null)
                Text(
                  fmtDuration(elapsed),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeDisplay(
                  label: AppLocalizations.of(context)!.checkIn,
                  time: fmtTime(checkInTime),
                  iconColor: c.success,
                  icon: Icons.login_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: c.divider,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _TimeDisplay(
                  label: AppLocalizations.of(context)!.checkOut,
                  time: fmtTime(checkOutTime),
                  iconColor: c.error,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isBlocked)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.infoLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isOnLeave
                    ? '${AppLocalizations.of(context)!.onLeaveToday}${attendanceViewModel.todayRecord?.leaveType != null ? ' (${attendanceViewModel.todayRecord!.leaveType!.value})' : ''}.'
                    : isDayOff
                        ? AppLocalizations.of(context)!.onDayOffToday
                        : AppLocalizations.of(context)!.absent,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: isCheckedOut
                      ? null
                      : LinearGradient(
                          colors: isCheckedIn
                              ? [c.error, const Color(0xFFC0392B)]
                              : [c.primary, c.primaryDark],
                        ),
                  color: isCheckedOut ? c.divider : null,
                  boxShadow: [
                    if (!isCheckedOut)
                      BoxShadow(
                        color: (isCheckedIn ? c.error : c.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: (attendanceViewModel.isActionLoading || isCheckedOut)
                      ? null
                      : isCheckedIn
                      ? () => _handleCheckOut(context)
                      : () => _handleCheckIn(context),
                  icon: attendanceViewModel.isActionLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(
                    isCheckedOut ? Icons.check_circle_rounded : (isCheckedIn ? Icons.logout_rounded : Icons.login_rounded),
                    size: 20,
                  ),
                  label: Text(isCheckedOut
                      ? AppLocalizations.of(context)!.checkedOut
                      : (isCheckedIn ? AppLocalizations.of(context)!.checkOut : AppLocalizations.of(context)!.checkIn)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: isCheckedOut ? c.textSecondary : Colors.white,
                    disabledForegroundColor: isCheckedOut ? c.textSecondary : null,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({
    required this.label,
    required this.time,
    required this.iconColor,
    required this.icon,
  });

  final String label;
  final String time;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}