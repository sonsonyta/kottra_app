import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
    final controller = TextEditingController(text: viewModel.managerName);
    final messenger = ScaffoldMessenger.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      await viewModel.updateDisplayName(newName);
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update: $e')));
    }
  }

  Future<void> _editPhoto(BuildContext context) async {
    if (viewModel.isUploadingPhoto) return;
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not upload photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = appColors(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
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
                      tooltip: 'Update profile',
                      onPressed: () => _editName(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Store',
                  value: viewModel.storeName ?? viewModel.storeId,
                  color: c,
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Role', value: viewModel.roleLabel, color: c),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Notifications ──
          SettingsCard(
            title: 'Notifications',
            icon: Icons.notifications_active_outlined,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Employee requests',
                style: TextStyle(fontSize: 14, color: c.textPrimary),
              ),
              subtitle: Text(
                'Get notified when employees submit leave or late-excuse requests',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
              activeThumbColor: c.primary,
              value: viewModel.requestNotificationsEnabled,
              onChanged: viewModel.toggleRequestNotifications,
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
              label: 'Switch store',
              color: c,
              onTap: onSwitchStore!,
            ),
          if (onLogout != null) ...[
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
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
