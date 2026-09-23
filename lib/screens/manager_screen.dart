import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/screens/management/store_management_screen.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/services/store_service.dart';
import 'package:kottra_app/view_models/manager_view_model.dart';

/// Home for store users who sign in with email/password (Owner, Admin,
/// Manager, …). The home is the selected store's management dashboard; the
/// store list is only shown as a selection step when no store is chosen yet.
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  late final ManagerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ManagerViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await _confirmLogout();
    if (!confirmed || !mounted) return;
    await _viewModel.logout();
    if (!mounted) return;
    context.go('/login');
  }

  Future<bool> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final c = appColors(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.confirmLogoutTitle,
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.confirmLogoutMessage,
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel, style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l10n.yesLogout),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // Home is the selected store's dashboard. The store list only appears
        // when nothing is selected yet.
        final selected = _viewModel.selectedMembership;
        if (selected != null) {
          return StoreManagementScreen(
            key: ValueKey(selected.storeId),
            membership: selected,
            onLogout: _handleLogout,
            // Always offer switching so the Home swap icon and the Profile
            // "Switch store" tile are always available. With a single store it
            // simply reopens the store list showing that one store.
            onSwitchStore: _viewModel.clearSelection,
          );
        }
        return _buildSelectionScaffold(context);
      },
    );
  }

  Widget _buildSelectionScaffold(BuildContext context) {
    final c = appColors(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: const Text('Select a store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.errorMessage != null) {
            return _CenteredMessage(
              icon: Icons.error_outline_rounded,
              iconColor: c.error,
              title: _viewModel.errorMessage!,
              actionLabel: 'Retry',
              onAction: _viewModel.refresh,
            );
          }
          if (_viewModel.hasNoRole) {
            return _CenteredMessage(
              icon: Icons.no_accounts_rounded,
              iconColor: c.textSecondary,
              title: 'No store role assigned',
              subtitle:
                  'This account isn\'t a member of any store. Ask a store owner '
                  'to add you, then sign in again.',
            );
          }
          return _buildStoreList(c);
        },
      ),
    );
  }

  Widget _buildStoreList(AppColors c) {
    final memberships = _viewModel.memberships;
    return RefreshIndicator(
      onRefresh: _viewModel.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: memberships.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                'Welcome, ${_viewModel.userName}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            );
          }
          final m = memberships[index - 1];
          return _StoreCard(
            membership: m,
            color: c,
            onTap: () => _viewModel.selectStore(m),
          );
        },
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.membership,
    required this.color,
    required this.onTap,
  });

  final StoreMembership membership;
  final AppColors color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store_rounded, color: color.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.storeName ?? membership.storeId,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      membership.userRole.displayName,
                      style: TextStyle(fontSize: 13, color: color.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
