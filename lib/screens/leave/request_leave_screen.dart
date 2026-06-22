import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/models/leave_request.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/screens/tabs/tab_helpers.dart';
import 'package:kottra_app/view_models/leave_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kottra_app/l10n/app_localizations.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key, required this.viewModel});

  final LeaveViewModel viewModel;

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  LeaveType _selectedType = LeaveType.other;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  PlatformFile? _attachment;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _attachment = result.files.first;
      });
    }
  }

  String _getLeaveType(BuildContext context, LeaveType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case LeaveType.sick: return l10n.sickLeave;
      case LeaveType.paid: return l10n.paidLeave;
      case LeaveType.other: return l10n.otherLeave;
      case LeaveType.unpaid: return l10n.unpaidLeave;
      case LeaveType.annual: return l10n.annualLeave;
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final c = appColors(context);
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: c.primary,
              onPrimary: Colors.white,
              surface: c.surface,
              onSurface: c.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await widget.viewModel.submitRequest(
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType,
        reason: _reasonController.text,
        attachment: _attachment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.leaveRequestSubmittedSuccess)),
      );
      context.pop();
    } catch (e,trace) {

      print(e);
      print(trace);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: Text(
          l10n.requestLeave,
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
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader(context, l10n.leaveType),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: LeaveType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(_getLeaveType(context, type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedType = type);
                        }
                      },
                      selectedColor: c.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : c.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: c.surface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.dateRange),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: l10n.startDate,
                        date: _startDate,
                        onTap: () => _pickDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DateField(
                        label: l10n.endDate,
                        date: _endDate,
                        onTap: () => _pickDate(context, false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.reason),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.enterLeaveReason,
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.pleaseEnterReason;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.attachmentOptional),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _attachment == null
                              ? Icons.upload_file_outlined
                              : Icons.insert_drive_file_outlined,
                          color: c.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _attachment == null
                                ? l10n.tapToSelectDocument
                                : _attachment!.name,
                            style: TextStyle(
                              color: _attachment == null
                                  ? c.textSecondary
                                  : c.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_attachment != null)
                          IconButton(
                            icon: Icon(Icons.close, color: c.error, size: 20),
                            onPressed: () => setState(() => _attachment = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: c.primary),
                const SizedBox(width: 8),
                Text(
                  fmtDateShort(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
