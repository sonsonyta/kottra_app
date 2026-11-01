import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/early_leave_view_model.dart';

/// Ask in advance to leave before the end of a shift: the day, the time the
/// employee will leave, and a reason.
class RequestEarlyLeaveScreen extends StatefulWidget {
  const RequestEarlyLeaveScreen({super.key, required this.viewModel});

  final EarlyLeaveViewModel viewModel;

  @override
  State<RequestEarlyLeaveScreen> createState() =>
      _RequestEarlyLeaveScreenState();
}

class _RequestEarlyLeaveScreenState extends State<RequestEarlyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _day;
  TimeOfDay? _time;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final vm = widget.viewModel;
    final initial = _day ??
        List.generate(
          EarlyLeaveViewModel.upcomingWindowDays + 1,
          (i) => vm.firstDay.add(Duration(days: i)),
        ).where(vm.isDaySelectable).firstOrNull;
    if (initial == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: vm.firstDay,
      lastDate: vm.lastDay,
      selectableDayPredicate: vm.isDaySelectable,
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final day = _day;
    final time = _time;
    if (day == null || time == null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.viewModel.submitRequest(
        day: day,
        hour: time.hour,
        minute: time.minute,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.earlyLeaveSubmittedSuccess)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorPrefix(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    InputDecoration boxDecoration(String? errorText, IconData icon) =>
        InputDecoration(
          filled: true,
          fillColor: c.surface,
          errorText: errorText,
          suffixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        );

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: Text(
          l10n.requestEarlyLeave,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          // Drop a day that a newer request has since taken.
          if (_day != null && !vm.isDaySelectable(_day!)) _day = null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionHeader(context, l10n.earlyLeaveDay),
                const SizedBox(height: 12),
                FormField<DateTime>(
                  validator: (_) =>
                      _day == null ? l10n.earlyLeaveDay : null,
                  builder: (field) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await _pickDay();
                      field.didChange(_day);
                    },
                    child: InputDecorator(
                      decoration: boxDecoration(
                          field.errorText, Icons.calendar_today_outlined),
                      child: Text(
                        _day == null
                            ? l10n.earlyLeaveDay
                            : DateFormat('E, d MMM yyyy', locale).format(_day!),
                        style: TextStyle(
                          color: _day == null ? c.textSecondary : c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader(context, l10n.earlyLeaveTime),
                const SizedBox(height: 12),
                FormField<TimeOfDay>(
                  validator: (_) =>
                      _time == null ? l10n.earlyLeaveTime : null,
                  builder: (field) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await _pickTime();
                      field.didChange(_time);
                    },
                    child: InputDecorator(
                      decoration:
                          boxDecoration(field.errorText, Icons.schedule),
                      child: Text(
                        _time == null
                            ? l10n.earlyLeaveTime
                            : _time!.format(context),
                        style: TextStyle(
                          color:
                              _time == null ? c.textSecondary : c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader(context, l10n.reason),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.earlyLeaveReasonHint,
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.earlyLeaveReasonHint
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.earlyLeaveDeductionNote,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: vm.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.submitRequest,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: appColors(context).textPrimary,
      ),
    );
  }
}
