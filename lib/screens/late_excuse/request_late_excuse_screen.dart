import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/models/attendance_record.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/late_excuse_view_model.dart';

class RequestLateExcuseScreen extends StatefulWidget {
  const RequestLateExcuseScreen({super.key, required this.viewModel});

  final LateExcuseViewModel viewModel;

  @override
  State<RequestLateExcuseScreen> createState() =>
      _RequestLateExcuseScreenState();
}

enum _ExcuseFor { pastDay, upcomingDay }

class _RequestLateExcuseScreenState extends State<RequestLateExcuseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  AttendanceRecord? _selectedDay;
  DateTime? _selectedUpcomingDay;
  _ExcuseFor? _excuseFor;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickUpcomingDay() async {
    final vm = widget.viewModel;
    final initial =
        _selectedUpcomingDay ??
        List.generate(
          LateExcuseViewModel.upcomingWindowDays + 1,
          (i) => vm.firstUpcomingDay.add(Duration(days: i)),
        ).where(vm.isUpcomingDaySelectable).firstOrNull;
    if (initial == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: vm.firstUpcomingDay,
      lastDate: vm.lastUpcomingDay,
      selectableDayPredicate: vm.isUpcomingDaySelectable,
    );
    if (picked != null) setState(() => _selectedUpcomingDay = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_excuseFor == _ExcuseFor.upcomingDay) {
        final day = _selectedUpcomingDay;
        if (day == null) return;
        await widget.viewModel.submitUpcomingRequest(
          day: day,
          reason: _reasonController.text,
        );
      } else {
        final day = _selectedDay;
        if (day == null) return;
        await widget.viewModel.submitRequest(
          record: day,
          reason: _reasonController.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.lateExcuseSubmittedSuccess,
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorPrefix(e.toString()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: Text(
          l10n.requestLateExcuse,
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
          final lateDays = vm.excusableLateDays;
          // Default to a past late day when there is one to excuse.
          final excuseFor =
              _excuseFor ??
              (lateDays.isEmpty ? _ExcuseFor.upcomingDay : _ExcuseFor.pastDay);
          _excuseFor = excuseFor;

          // Keep the current selections valid as the streams refresh.
          if (_selectedDay != null &&
              !lateDays.any((d) => d.id == _selectedDay!.id)) {
            _selectedDay = null;
          }
          if (_selectedUpcomingDay != null &&
              !vm.isUpcomingDaySelectable(_selectedUpcomingDay!)) {
            _selectedUpcomingDay = null;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<_ExcuseFor>(
                  segments: [
                    ButtonSegment(
                      value: _ExcuseFor.pastDay,
                      label: Text(l10n.lateExcusePastDay),
                      icon: const Icon(Icons.history),
                    ),
                    ButtonSegment(
                      value: _ExcuseFor.upcomingDay,
                      label: Text(l10n.lateExcuseUpcomingDay),
                      icon: const Icon(Icons.event),
                    ),
                  ],
                  selected: {excuseFor},
                  onSelectionChanged: (selection) =>
                      setState(() => _excuseFor = selection.first),
                ),
                const SizedBox(height: 24),
                if (excuseFor == _ExcuseFor.upcomingDay)
                  ..._buildUpcomingDayField(context, l10n, locale)
                else if (lateDays.isEmpty)
                  Text(
                    l10n.noExcusableLateDays,
                    style: TextStyle(color: c.textSecondary),
                  )
                else ...[
                  _buildSectionHeader(context, l10n.selectLateDay),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AttendanceRecord>(
                    initialValue: _selectedDay,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: lateDays.map((day) {
                      final label =
                          '${DateFormat('E, d MMM', locale).format(day.date.toDate())}'
                          ' · ${l10n.minutesLate(day.lateMinutes)}';
                      return DropdownMenuItem<AttendanceRecord>(
                        value: day,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedDay = value),
                    validator: (value) =>
                        value == null ? l10n.selectLateDay : null,
                  ),
                ],
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.reason),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.lateExcuseReasonHint,
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.lateExcuseReasonHint
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.lateExcuseDeductionNote,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed:
                      vm.isLoading ||
                          (excuseFor == _ExcuseFor.pastDay && lateDays.isEmpty)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.viewModel.isLoading
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

  List<Widget> _buildUpcomingDayField(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final c = appColors(context);
    final day = _selectedUpcomingDay;
    return [
      _buildSectionHeader(context, l10n.selectUpcomingLateDay),
      const SizedBox(height: 12),
      FormField<DateTime>(
        // Validate against the state field; the picker writes it directly.
        validator: (_) =>
            _selectedUpcomingDay == null ? l10n.selectUpcomingLateDay : null,
        builder: (field) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _pickUpcomingDay();
            field.didChange(_selectedUpcomingDay);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: c.surface,
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            child: Text(
              day == null
                  ? l10n.selectUpcomingLateDay
                  : DateFormat('E, d MMM yyyy', locale).format(day),
              style: TextStyle(
                color: day == null ? c.textSecondary : c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
