// lib/screens/info/contact_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/auth_scope.dart';
import '../../core/app_theme.dart';
import '../../widgets/settings_item.dart';
import '../../widgets/state_views.dart';

/// Store contact details, loaded from `GET /api/contact`.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  Map<String, dynamic>? _contact;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // The first load starts in the loading state already; retries and
    // pull-to-refresh need to flip back into it.
    if (_contact != null || _error != null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final api = AuthScope.of(context, listen: false).api;
      final response = await api.request('/contact');
      if (!mounted) return;
      setState(() {
        _contact = response['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load contact details.';
        _loading = false;
      });
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Contact Us')),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading && _contact == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_contact == null) {
      return ErrorStateView(message: _error ?? 'Something went wrong.', onRetry: _load);
    }
    final c = _contact!;
    String field(String key) => (c[key] as String?)?.trim() ?? '';

    final rows = [
      (Icons.mail_outline_rounded, 'Email', field('email')),
      (Icons.phone_outlined, 'Phone', field('phone')),
      (Icons.location_on_outlined, 'Address', field('address')),
    ].where((r) => r.$3.isNotEmpty);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          const Text(
            'We are here to help with orders, delivery, payments and product '
            'questions. Tap any detail to copy it.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsSection(
            title: 'Get in touch',
            children: [
              for (final (icon, label, value) in rows)
                SettingsItem(
                  icon: icon,
                  title: label,
                  subtitle: value,
                  trailing: const Icon(Icons.copy_rounded,
                      size: 18, color: AppColors.textTertiary),
                  onTap: () => _copy(label, value),
                ),
            ],
          ),
          if (field('hours').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SettingsSection(
              title: 'Opening hours',
              children: [
                SettingsItem(
                  icon: Icons.schedule_rounded,
                  title: 'Customer support',
                  subtitle: field('hours'),
                  showArrow: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
