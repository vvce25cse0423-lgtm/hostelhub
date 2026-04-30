// lib/presentation/screens/student/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_snackbar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Iconsax.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Avatar ──────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 8),
            Text(user.role.toUpperCase(),
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1)),

            const SizedBox(height: 28),

            // ─── Info Card ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Information',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 16),

                    if (_isEditing) ...[
                      AppTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ] else ...[
                      _ProfileRow(icon: Icons.person_outline,
                          label: 'Name', value: user.name),
                      const SizedBox(height: 12),
                      _ProfileRow(icon: Icons.email_outlined,
                          label: 'Email', value: user.email),
                      if (user.usn != null) ...[
                        const SizedBox(height: 12),
                        _ProfileRow(icon: Icons.badge_outlined,
                            label: 'USN', value: user.usn!),
                      ],
                      if (user.phone != null) ...[
                        const SizedBox(height: 12),
                        _ProfileRow(icon: Icons.phone_outlined,
                            label: 'Phone', value: user.phone!),
                      ],
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // ─── Settings Card ────────────────────────────────────────────
            Card(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Iconsax.moon,
                    label: 'Dark Mode',
                    trailing: Switch(
                      value: ref.watch(themeModeNotifierProvider),
                      onChanged: (v) =>
                          ref.read(themeModeNotifierProvider.notifier).toggle(),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Iconsax.notification,
                    label: 'Notifications',
                    onTap: () => context.go(AppRoutes.notifications),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Iconsax.lock,
                    label: 'Change Password',
                    onTap: () {
                      AppSnackbar.showInfo(
                          context, 'Feature coming soon');
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // ─── Sign Out Button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                icon: const Icon(Iconsax.logout, color: Colors.red),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;

    final error = await ref.read(authNotifierProvider.notifier).updateProfile(
          userId: user.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (error != null) {
      AppSnackbar.showError(context, error);
    } else {
      AppSnackbar.showSuccess(context, 'Profile updated!');
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile(
      {required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
