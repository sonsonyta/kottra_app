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

class _RequestLateExcuseScreenState extends State<RequestLateExcuseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  AttendanceRecord? _selectedDay;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final day = _selectedDay;
    if (day == null) return;

    try {
      await widget.viewModel.submitRequest(
        record: day,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.lateExcuseSubmittedSuccess),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
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
          final lateDays = widget.viewModel.excusableLateDays;

          if (lateDays.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noExcusableLateDays,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
            );
          }

          // Keep the current selection valid as the stream refreshes.
          if (_selectedDay != null &&
              !lateDays.any((d) => d.id == _selectedDay!.id)) {
            _selectedDay = null;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                  onPressed: widget.viewModel.isLoading ? null : _submit,
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
