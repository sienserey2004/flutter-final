// lib/screens/info/help_screen.dart
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/app_button.dart';
import 'contact_screen.dart';

/// Frequently asked questions, grouped by topic, with a way to reach support.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _topics = <(String, List<(String, String)>)>[
    (
      'Orders',
      [
        (
          'How do I place an order?',
          'Add products to your cart, tap Proceed to Checkout, choose a '
              'delivery address and method, pick a payment method, then tap '
              'Place order.',
        ),
        (
          'Where can I see my orders?',
          'Go to Profile → My Orders to see every order, its status and its '
              'items.',
        ),
        (
          'Can I cancel or change an order?',
          'Contact our support team with your order number as soon as '
              'possible. Orders that have not shipped yet can usually be '
              'changed or cancelled.',
        ),
      ],
    ),
    (
      'Payment',
      [
        (
          'Which payment methods can I use?',
          'Cash on delivery, or KHQR. With KHQR you scan the code with any '
              'Bakong-supported banking app and the payment is confirmed '
              'automatically.',
        ),
        (
          'Can I use a coupon?',
          'Yes. Enter the code in the Coupon field at checkout and tap Apply. '
              'The discount is shown in the order summary.',
        ),
      ],
    ),
    (
      'Delivery',
      [
        (
          'How much does delivery cost?',
          'Each delivery method shows its fee and estimated delivery time at '
              'checkout. Some methods are free above a minimum order amount.',
        ),
        (
          'How do I manage my addresses?',
          'Go to Profile → Addresses to add, edit or delete addresses and to '
              'choose your default one. You can also add a new address at '
              'checkout.',
        ),
      ],
    ),
    (
      'Account',
      [
        (
          'I forgot my password.',
          'On the login screen, tap Forgot password and enter your email '
              'address to receive reset instructions.',
        ),
        (
          'How do I change my password?',
          'Go to Profile → Account Settings → Change Password. You will need '
              'your current password.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            const Text(
              'Frequently asked questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (topic, questions) in _topics) ...[
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  topic.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              // A Material (not a decorated Container) so the tiles' tap
              // ripples paint on the card instead of underneath it.
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < questions.length; i++) ...[
                      _FaqTile(
                        question: questions[i].$1,
                        answer: questions[i].$2,
                      ),
                      if (i != questions.length - 1)
                        const Divider(height: 1, indent: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Our support team can help with anything not covered here.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Contact us',
                    icon: Icons.support_agent_rounded,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ContactScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Drop the default ExpansionTile borders; the card draws its own.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: AppColors.primary,
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
