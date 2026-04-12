import 'package:flutter/material.dart';
import 'package:kottra_app/screens/tabs/shared_widgets.dart';
import 'package:kottra_app/screens/tabs/tab_colors.dart';
import 'package:kottra_app/viewmodels/home_view_model.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.viewModel, required this.onLogout});

  final HomeViewModel viewModel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
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
                    label: 'Employee ID',
                    value: viewModel.employeeCode,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.work_outline_rounded,
                    label: 'Position',
                    value: viewModel.position,
                  ),
                  if (viewModel.department != null)
                    _ProfileMenuItem(
                      icon: Icons.business_center_outlined,
                      label: 'Department',
                      value: viewModel.department!,
                    ),
                  if (viewModel.workLocation != null)
                    _ProfileMenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Office',
                      value: viewModel.workLocation!,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                items: [
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: 'Enabled',
                  ),
                  _ProfileMenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: kTextSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _LogoutButton(onLogout: onLogout),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: kPrimary,
      elevation: 0,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimaryDark, kPrimary],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2E86DE),
            blurRadius: 24,
            offset: Offset(0, 8),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (viewModel.userEmail.isNotEmpty)
                  Text(
                    viewModel.userEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: viewModel.employeeStatus == EmployeeStatus.active
                        ? kSuccessLight
                        : kWarningLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    viewModel.employeeStatus.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: viewModel.employeeStatus == EmployeeStatus.active
                          ? kSuccess
                          : kWarning,
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
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2E86DE),
            blurRadius: 12,
            offset: Offset(0, 4),
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
    this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: kError,
          side: const BorderSide(color: kError),
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
