// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_scope.dart';
import '../../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/state_views.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthScope.of(context);
    final error = await auth.requestPasswordReset(_emailController.text);

    if (!mounted) return;

    setState(() {
      _errorMessage = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to login',
          onPressed:
              auth.isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Forgot password'),
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
              child: _sent ? _buildConfirmation(context) : _buildForm(auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AuthController auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Reset your password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Enter the email associated with your account and we will send '
            'you a link to reset your password.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !auth.isSubmitting,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Email is required.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ErrorBanner(message: _errorMessage!),
          ],

          const SizedBox(height: AppSpacing.xxl),

          AppButton(
            label: 'Send reset link',
            isLoading: auth.isSubmitting,
            onPressed: _submit,
          ),

          const SizedBox(height: AppSpacing.lg),

          AppButton(
            label: 'Back to login',
            variant: AppButtonVariant.ghost,
            onPressed:
                auth.isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const SuccessBanner(
          message:
              'If an account exists for that email, a reset link is on its way.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent instructions to ${_emailController.text.trim()}. '
          'The link expires in 30 minutes.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: 'Back to login',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Use a different email',
          variant: AppButtonVariant.ghost,
          onPressed: () => setState(() {
            _sent = false;
            _errorMessage = null;
          }),
        ),
      ],
    );
  }
}
