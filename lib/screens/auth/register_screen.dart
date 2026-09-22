// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/state_views.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await auth.register(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // This backend does not auto-authenticate -> back to Login.
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account created. Please log in.'),
        ),
      );
      return;
    }

    // If your backend DOES auto-authenticate, just call:
    // await auth.login(email: ..., password: ...);
    // and the root gate will take the user straight to Home.
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to login',
          onPressed: auth.isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Create account'),
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
                    const Text(
                      'Join us',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Create an account to get started.',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textSecondary,
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
                        if (value.trim().length < 2) {
                          return 'Enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !auth.isSubmitting,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Email is required.';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'At least 6 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      enabled: !auth.isSubmitting,
                      onToggleObscure: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required.';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppTextField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      hint: 'Re-enter your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      enabled: !auth.isSubmitting,
                      textInputAction: TextInputAction.done,
                      onToggleObscure: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password.';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ErrorBanner(message: auth.errorMessage!),
                    ],

                    const SizedBox(height: AppSpacing.xxl),

                    AppButton(
                      label: 'Create account',
                      isLoading: auth.isSubmitting,
                      onPressed: _submit,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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