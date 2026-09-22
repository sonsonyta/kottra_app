import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/theme/locale_controller.dart';
import 'package:kottra_app/theme/theme_controller.dart';

import '../../l10n/app_localizations.dart';

/// Card wrapper shared by the settings sections so they read as one system in
/// both the employee and manager profiles.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    // The surface color lives on a Material (not a plain DecoratedBox) so that
    // ListTile-based children — e.g. a SwitchListTile — can paint their ink and
    // background on it. A colored Container here would hide those effects and
    // trip ListTile's "background may be invisible" assertion.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: c.shadowSubtle,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: c.primary, size: 20),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme (light/dark/system) selector card. Backed by the global
/// [ThemeController], so it works for any signed-in user.
class AppearanceSettingSection extends StatelessWidget {
  const AppearanceSettingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: AppLocalizations.of(context)!.appearance,
      icon: Icons.dark_mode_outlined,
      child: ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) {
          final selected = ThemeController.instance.mode;
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: appColors(context).surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedOption(
                    icon: Icons.brightness_auto_outlined,
                    label: AppLocalizations.of(context)!.themeAuto,
                    isSelected: selected == ThemeMode.system,
                    onTap: () => ThemeController.instance.setMode(ThemeMode.system),
                  ),
                ),
                Expanded(
                  child: SegmentedOption(
                    icon: Icons.light_mode_outlined,
                    label: AppLocalizations.of(context)!.themeLight,
                    isSelected: selected == ThemeMode.light,
                    onTap: () => ThemeController.instance.setMode(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: SegmentedOption(
                    icon: Icons.dark_mode_outlined,
                    label: AppLocalizations.of(context)!.themeDark,
                    isSelected: selected == ThemeMode.dark,
                    onTap: () => ThemeController.instance.setMode(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Language (English/Khmer) selector card. Backed by the global
/// [LocaleController].
class LanguageSettingSection extends StatelessWidget {
  const LanguageSettingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: AppLocalizations.of(context)!.language,
      icon: Icons.language_outlined,
      child: ListenableBuilder(
        listenable: LocaleController.instance,
        builder: (context, _) {
          final selected = LocaleController.instance.locale.languageCode;
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: appColors(context).surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedOption(
                    icon: Icons.translate,
                    label: 'English',
                    isSelected: selected == 'en',
                    onTap: () =>
                        LocaleController.instance.setLocale(const Locale('en')),
                  ),
                ),
                Expanded(
                  child: SegmentedOption(
                    icon: Icons.translate,
                    label: 'ភាសាខ្មែរ',
                    isSelected: selected == 'km',
                    onTap: () =>
                        LocaleController.instance.setLocale(const Locale('km')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One pill in a segmented selector (theme mode, language, …).
class SegmentedOption extends StatelessWidget {
  const SegmentedOption({
    super.key,
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
