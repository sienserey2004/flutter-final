// lib/screens/settings/account_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _pushKey = 'pref_push_notifications';
  static const _emailKey = 'pref_email_updates';

  bool _pushNotifications = true;
  bool _emailUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _pushNotifications = prefs.getBool(_pushKey) ?? true;
      _emailUpdates = prefs.getBool(_emailKey) ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

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
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                      _savePref(_pushKey, value);
                    },
                  ),
                ),
                SettingsItem(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Email updates',
                  showArrow: false,
                  trailing: Switch.adaptive(
                    value: _emailUpdates,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() => _emailUpdates = value);
                      _savePref(_emailKey, value);
                    },
                  ),
                ),
                SettingsItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English (US)',
                  showArrow: false,
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
          'This permanently closes your account. You will be signed out and '
          'will not be able to log in again. This action cannot be undone.',
      confirmLabel: 'Continue',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
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

/// Change-password form. Verifies the current password on the server, then
/// signs the user out so they log in again with the new one.
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  bool _saving = false;
  String? _error;
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String? error;
    if (_current.text.isEmpty) {
      error = 'Enter your current password.';
    } else if (_password.text.length < 6) {
      error = 'New password must be at least 6 characters.';
    } else if (_password.text != _confirm.text) {
      error = 'New passwords do not match.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = AuthScope.of(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final failure = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _saving = false;
        _error = failure;
      });
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
          content: Text('Password changed. Please sign in again.')),
    );
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
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
              controller: _current,
              label: 'Current password',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              enabled: !_saving,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _password,
              label: 'New password',
              obscureText: true,
              prefixIcon: Icons.lock_reset_rounded,
              enabled: !_saving,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirm,
              label: 'Confirm new password',
              obscureText: true,
              prefixIcon: Icons.lock_reset_rounded,
              textInputAction: TextInputAction.done,
              enabled: !_saving,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13.5),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
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
                  : const Text('Change password'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the password before closing the account for good.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    final auth = AuthScope.of(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final failure = await auth.deleteAccount(password: _password.text);
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _deleting = false;
        _error = failure;
      });
      return;
    }
    // Signing out pops every route (this dialog included) back to login.
    messenger.showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm with your password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _password,
            label: 'Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            enabled: !_deleting,
            onFieldSubmitted: (_) => _delete(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13.5),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _deleting ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete account'),
        ),
      ],
    );
  }
}
