import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/salary_advance_view_model.dart';

class RequestAdvanceScreen extends StatefulWidget {
  const RequestAdvanceScreen({super.key, required this.viewModel});

  final SalaryAdvanceViewModel viewModel;

  @override
  State<RequestAdvanceScreen> createState() => _RequestAdvanceScreenState();
}

class _RequestAdvanceScreenState extends State<RequestAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    try {
      await widget.viewModel.submitAdvance(
        amount: amount,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.advanceRequestSubmittedSuccess),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    final currency = widget.viewModel.currency.value;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.primary,
        title: Text(
          l10n.requestAdvance,
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
                _buildSectionHeader(context, l10n.advanceAmount),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    prefixText: currency == 'USD' ? '\$ ' : '៛ ',
                    hintText: l10n.enterAdvanceAmount,
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) {
                      return l10n.pleaseEnterValidAmount;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.reason),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.enterAdvanceReason,
                    filled: true,
                    fillColor: c.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.advanceDeductionNote,
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
