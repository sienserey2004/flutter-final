// lib/screens/settings/account_settings_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../core/session_actions.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/settings_item.dart';
import '../../widgets/app_text_field.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            // ---- Account ----------------------------------------------------
            SettingsSection(
              title: 'Account',
              children: [
                SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordSheet(context),
                ),
                SettingsItem(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email / Account information',
                  subtitle: user?.email ?? '—',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _AccountInfoScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ---- Preferences ------------------------------------------------
            SettingsSection(
              title: 'Preferences',
              children: [
                SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Push notifications',
                  showArrow: false,
                  trailing: Switch.adaptive(
                    value: _pushNotifications,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _pushNotifications = value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Email updates',
                  showArrow: false,
                  trailing: Switch.adaptive(
                    value: _emailUpdates,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _emailUpdates = value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English (US)',
                  onTap: () => _showNotWiredUp(context, 'Language'),
                ),
                SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark theme',
                  showArrow: false,
                  trailing: Switch.adaptive(
                    value: _darkMode,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => _darkMode = value),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ---- Security ---------------------------------------------------
            SettingsSection(
              title: 'Security',
              children: [
                SettingsItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  subtitle: 'This action cannot be undone',
                  isDestructive: true,
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ---- Session ----------------------------------------------------
            SettingsSection(
              title: 'Session',
              children: [
                SettingsItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isDestructive: true,
                  showArrow: false,
                  onTap: () => confirmAndLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete account?',
      message:
          'This permanently removes your account and all associated data. '
          'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete account flow not wired up yet.')),
    );
  }

  void _showNotWiredUp(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label settings are not wired up yet.')),
    );
  }
}

/// Minimal account information screen.
class _AccountInfoScreen extends StatelessWidget {
  const _AccountInfoScreen();

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Account information')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            SettingsSection(
              children: [
                SettingsItem(
                  icon: Icons.badge_outlined,
                  title: 'Full name',
                  subtitle: user?.fullName ?? '—',
                  showArrow: false,
                ),
                SettingsItem(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle: user?.email ?? '—',
                  showArrow: false,
                ),
                SettingsItem(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: (user?.phone.isEmpty ?? true)
                      ? 'Not provided'
                      : user!.phone,
                  showArrow: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder change-password form.
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  bool _saving = false;
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Change password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'For security, we will ask you to sign in again after changing '
            'your password.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _password,
            label: 'New password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _confirm,
            label: 'Confirm password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_password.text.length < 6 || _password.text != _confirm.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords must match and be at least 6 characters.')));
                      return;
                    }
                    setState(() => _saving = true);
                    final auth = AuthScope.of(context, listen: false);
                    final user = auth.user;
                    final success = await auth.updateProfile(
                      fullName: user?.fullName ?? '',
                      email: user?.email ?? '',
                      phone: user?.phone ?? '',
                      newPassword: _password.text,
                    );
                    if (!context.mounted) return;
                    if (!success) {
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Could not change password.')));
                      return;
                    }
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully.')),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
