// lib/screens/main/activity_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../core/app_theme.dart';
import '../../models/activity_item.dart';
import '../../widgets/state_views.dart';

enum _ActivityStatus { loading, error, ready }

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TextEditingController _searchController = TextEditingController();

  _ActivityStatus _status = _ActivityStatus.loading;
  List<ActivityItem> _items = const [];
  String _filter = 'All';

  static const List<String> _filters = ['All', 'Today', 'This week', 'Income'];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _ActivityStatus.loading);

    try {
      final orders = await widget.auth.orders();
      if (!mounted) return;
      setState(() {
        _items = orders.map(ActivityItem.fromOrder).toList();
        _status = _ActivityStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _ActivityStatus.error);
    }
  }

  List<ActivityItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);

      final matchesFilter = switch (_filter) {
        'Today' => item.timeLabel.toLowerCase().startsWith('today'),
        'This week' => !item.timeLabel.toLowerCase().contains('d ago'),
        'Income' => item.isPositive && item.amount != null,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Page title -------------------------------------------------
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: Text(
                'Activity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ---- Search + filters -------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search activity',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final label = _filters[index];
                  final selected = label == _filter;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = label),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ---- List / states ----------------------------------------------
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ActivityStatus.loading:
        return const LoadingIndicator(message: 'Loading activity…');

      case _ActivityStatus.error:
        return ErrorStateView(
          title: 'Could not load activity',
          message: 'Please check your connection and try again.',
          onRetry: _load,
        );

      case _ActivityStatus.ready:
        final items = _visibleItems;
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: _items.isEmpty ? 'No activity yet' : 'No results found',
            message: _items.isEmpty
                ? 'Your recent activity will appear here.'
                : 'Try a different search term or filter.',
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _ActivityTile(item: items[index]),
          ),
        );
    }
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.timeLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (item.amount != null)
            Text(
              item.amount!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: item.isPositive
                    ? AppColors.success
                    : AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
