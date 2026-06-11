
import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/theme/theme_controller.dart';
import 'package:kottra_app/theme/locale_controller.dart';
import 'package:kottra_app/viewmodels/main_view_model.dart';

import '../../../l10n/app_localizations.dart';
import 'edit_profile.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.viewModel, required this.onLogout});

  final MainViewModel viewModel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildHeader(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _ProfileInfoCard(viewModel: viewModel),
              const SizedBox(height: 20),
              _ProfileSection(
                items: [

                  _ProfileMenuItem(
                    icon: Icons.badge_outlined,
                    label: AppLocalizations.of(context)!.employeeId,
                    value: viewModel.employeeCode,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.work_outline_rounded,
                    label: AppLocalizations.of(context)!.position,
                    value: viewModel.position,
                  ),
                  if (viewModel.department != null)
                    _ProfileMenuItem(
                      icon: Icons.business_center_outlined,
                      label: AppLocalizations.of(context)!.department,
                      value: viewModel.department!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const _AppearanceSection(),
              const SizedBox(height: 16),
              const _LanguageSection(),
              const SizedBox(height: 24),
              _LogoutButton(onLogout: onLogout),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = appColors(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.primary,
      elevation: 0,
      title: Text(
        AppLocalizations.of(context)!.profile,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => EditProfileSheet(viewModel: viewModel),
            );
          },
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primaryDark, c.primary],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.viewModel});

  final MainViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
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
      child: Row(
        children: [
          TabAvatar(
            imageUrl: viewModel.profileImageUrl,
            initials: viewModel.userInitials,
            size: 64,
            useGradient: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (viewModel.userEmail.isNotEmpty)
                  Text(
                    viewModel.userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: viewModel.employeeStatus == EmployeeStatus.active
                        ? c.successLight
                        : c.warningLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    viewModel.employeeStatus.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: viewModel.employeeStatus == EmployeeStatus.active
                          ? c.success
                          : c.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
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
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.value, this.trailing, this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode_outlined, color: c.primary, size: 20),
              const SizedBox(width: 14),
              Text(
                AppLocalizations.of(context)!.appearance,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              final selected = ThemeController.instance.mode;
              return _ThemeModeSelector(
                selected: selected,
                onChanged: ThemeController.instance.setMode,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.selected,
    required this.onChanged,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeModeOption(
              icon: Icons.brightness_auto_outlined,
              label: AppLocalizations.of(context)!.themeAuto,
              isSelected: selected == ThemeMode.system,
              onTap: () => onChanged(ThemeMode.system),
            ),
          ),
          Expanded(
            child: _ThemeModeOption(
              icon: Icons.light_mode_outlined,
              label: AppLocalizations.of(context)!.themeLight,
              isSelected: selected == ThemeMode.light,
              onTap: () => onChanged(ThemeMode.light),
            ),
          ),
          Expanded(
            child: _ThemeModeOption(
              icon: Icons.dark_mode_outlined,
              label: AppLocalizations.of(context)!.themeDark,
              isSelected: selected == ThemeMode.dark,
              onTap: () => onChanged(ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: c.shadowSubtle,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? c.primary : c.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? c.textPrimary : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final c = appColors(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.confirmLogoutTitle, style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
          content: Text(l10n.confirmLogoutMessage, style: TextStyle(color: c.textSecondary)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.yesLogout),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(AppLocalizations.of(context)!.logout),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.error,
          side: BorderSide(color: c.error),
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_outlined, color: c.primary, size: 20),
              const SizedBox(width: 14),
              Text(
                l10n.language,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: LocaleController.instance,
            builder: (context, _) {
              final selected = LocaleController.instance.locale.languageCode;
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeModeOption(
                        icon: Icons.translate,
                        label: 'English',
                        isSelected: selected == 'en',
                        onTap: () => LocaleController.instance.setLocale(const Locale('en')),
                      ),
                    ),
                    Expanded(
                      child: _ThemeModeOption(
                        icon: Icons.translate,
                        label: 'ភាសាខ្មែរ',
                        isSelected: selected == 'km',
                        onTap: () => LocaleController.instance.setLocale(const Locale('km')),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


