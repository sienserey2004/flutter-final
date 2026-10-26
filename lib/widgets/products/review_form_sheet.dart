// lib/widgets/products/review_form_sheet.dart
import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../products/product_repository.dart';
import '../app_button.dart';
import '../app_text_field.dart';

/// Bottom sheet for rating a product (1–5 stars) with an optional title and
/// comment. Pops `true` once the review is saved.
class ReviewFormSheet extends StatefulWidget {
  const ReviewFormSheet({
    super.key,
    required this.repository,
    required this.productId,
    required this.productName,
  });

  final ProductRepository repository;
  final int productId;
  final String productName;

  @override
  State<ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends State<ReviewFormSheet> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please choose a star rating.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.repository.submitReview(
        productId: widget.productId,
        rating: _rating,
        title: _titleController.text,
        comment: _commentController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e is AuthException ? e.message : 'Could not submit your review.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Write a review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.productName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star star${star == 1 ? '' : 's'}',
                    onPressed: _submitting ? null : () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 36,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _titleController,
              label: 'Title (optional)',
              hint: 'Sum it up in a few words',
              enabled: !_submitting,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _commentController,
              label: 'Comment (optional)',
              hint: 'How did it work for your skin?',
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 4,
              enabled: !_submitting,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.m),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit review',
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
