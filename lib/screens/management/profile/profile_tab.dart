import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kottra_app/l10n/app_localizations.dart';
import 'package:kottra_app/screens/management/management_widgets.dart';
import 'package:kottra_app/screens/tabs/settings_sections.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/view_models/store_management_view_model.dart';

class ManagementProfileTab extends StatelessWidget {
  const ManagementProfileTab({
    super.key,
    required this.viewModel,
    this.onSwitchStore,
    this.onLogout,
  });

  final StoreManagementViewModel viewModel;
  final VoidCallback? onSwitchStore;
  final VoidCallback? onLogout;

  Future<void> _editName(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: viewModel.managerName);
    final messenger = ScaffoldMessenger.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editProfile),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await viewModel.updateDisplayName(newName);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdate('$e'))),
      );
    }
  }

  Future<void> _editPhoto(BuildContext context) async {
    if (viewModel.isUploadingPhoto) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    try {
      await viewModel.updateProfilePhoto(bytes);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profilePhotoUpdated)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotUploadPhoto('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.background,
      appBar: managementAppBar(context, l10n.profile),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile update ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _EditableAvatar(
                      photoUrl: viewModel.photoUrl,
                      photoBytes: viewModel.photoBytes,
                      initials: initialsFor(viewModel.managerName),
                      isUploading: viewModel.isUploadingPhoto,
                      color: c,
                      onTap: () => _editPhoto(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.managerName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          if (viewModel.managerEmail.isNotEmpty)
                            Text(
                              viewModel.managerEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: c.primary),
                      tooltip: l10n.editProfile,
                      onPressed: () => _editName(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: l10n.store,
                  value: viewModel.storeName ?? viewModel.storeId,
                  color: c,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: l10n.role,
                  value: viewModel.roleLabel,
                  color: c,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Notifications ──
          SettingsCard(
            title: l10n.notifications,
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                // The manager's own attendance notifications, only when they
                // can check in/out (linked to an employee in this store).
                if (viewModel.selfAttendance != null) ...[
                  _NotificationSwitch(
                    title: l10n.attendanceReminders,
                    subtitle: l10n.dailyCheckInOutAlertsSubtitle,
                    value: viewModel.remindersEnabled,
                    onChanged: viewModel.toggleReminders,
                    color: c,
                  ),
                  Divider(height: 1, color: c.divider),
                  _NotificationSwitch(
                    title: l10n.leaveNotifications,
                    subtitle: l10n.leaveNotificationsSubtitle,
                    value: viewModel.leaveNotificationsEnabled,
                    onChanged: viewModel.toggleLeaveNotifications,
                    color: c,
                  ),
                  Divider(height: 1, color: c.divider),
                ],
                _NotificationSwitch(
                  title: l10n.employeeRequests,
                  subtitle: l10n.employeeRequestsSubtitle,
                  value: viewModel.requestNotificationsEnabled,
                  onChanged: viewModel.toggleRequestNotifications,
                  color: c,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Appearance ──
          const AppearanceSettingSection(),
          const SizedBox(height: 16),
          // ── Language ──
          const LanguageSettingSection(),
          const SizedBox(height: 20),
          if (onSwitchStore != null)
            _ProfileTile(
              icon: Icons.swap_horiz_rounded,
              label: l10n.switchStore,
              color: c,
              onTap: onSwitchStore!,
            ),
          if (onLogout != null) ...[
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: l10n.logout,
              color: c,
              destructive: true,
              onTap: onLogout!,
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.photoUrl,
    required this.photoBytes,
    required this.initials,
    required this.isUploading,
    required this.color,
    required this.onTap,
  });

  final String? photoUrl;
  final Uint8List? photoBytes;
  final String initials;
  final bool isUploading;
  final AppColors color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = (photoBytes != null && photoBytes!.isNotEmpty)
        ? MemoryImage(photoBytes!)
        : (photoUrl != null && photoUrl!.isNotEmpty)
        ? NetworkImage(photoUrl!)
        : null;
    final hasPhoto = image != null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.primary.withValues(alpha: 0.12),
              backgroundImage: image,
              child: hasPhoto
                  ? null
                  : Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color.primary,
                      ),
                    ),
            ),
            if (isUploading)
              const Positioned.fill(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black45,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.surface, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: color.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final AppColors color;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? color.error : color.textPrimary;
    return Material(
      color: color.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: color.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: color.textSecondary),
      ),
      activeThumbColor: color.primary,
      value: value,
      onChanged: onChanged,
    );
  }
}
