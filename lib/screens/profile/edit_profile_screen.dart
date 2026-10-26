// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/state_views.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = AuthScope.of(context, listen: false).user;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    for (final controller in [_nameController, _phoneController]) {
      controller.addListener(_onChanged);
    }
  }

  void _onChanged() {
    final user = AuthScope.of(context, listen: false).user;
    final changed = _nameController.text.trim() != (user?.fullName ?? '') ||
        _phoneController.text.trim() != (user?.phone ?? '');

    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await auth.updateProfile(
      fullName: _nameController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } else {
      setState(() {
        _errorMessage =
            auth.errorMessage ?? 'Could not save your changes. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed:
              auth.isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---- Avatar ---------------------------------------------
                    Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primarySoft,
                        backgroundImage: user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!)
                            : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                user?.initials ?? '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'Jane Doe',
                      prefixIcon: Icons.person_outline_rounded,
                      enabled: !auth.isSubmitting,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // The backend doesn't allow changing the email, so it is
                    // shown read-only.
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Email can\'t be changed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone number (optional)',
                      hint: '+1 555 0000',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      enabled: !auth.isSubmitting,
                      onFieldSubmitted: (_) => _save(),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ErrorBanner(message: _errorMessage!),
                    ],

                    const SizedBox(height: AppSpacing.xxl),

                    AppButton(
                      label: 'Save changes',
                      isLoading: auth.isSubmitting,
                      onPressed: _save,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: auth.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}