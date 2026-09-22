// lib/widgets/status_timeline.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/format.dart';
import '../models/order_status_event.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.events});
  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No status updates yet.',
            style: TextStyle(color: AppColors.textTertiary)),
      );
    }
    final last = events.length - 1;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(events.length, (i) {
          final e = events[i];
          final isCurrent = i == last;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent ? AppColors.primary : AppColors.border,
                  ),
                ),
                if (!isCurrent)
                  Container(width: 2, height: 36, color: AppColors.border),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.fromStatus != null
                            ? '${e.toStatus} · from ${e.fromStatus}'
                            : e.toStatus,
                        style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(formatOrderDateTime(e.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                      if (e.note != null && e.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(e.note!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}