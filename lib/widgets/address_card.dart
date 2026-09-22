// lib/widgets/address_card.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/address.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.onEdit,
    this.onMakeDefault,
    this.onDelete,
  });
  final Address address;
  final VoidCallback? onEdit;
  final VoidCallback? onMakeDefault;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (address.label != null && address.label!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(address.label!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.primary)),
                    ),
                  if (address.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Default',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.success)),
                    ),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(address.recipientName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(address.phone,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(address.oneLine,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onEdit != null || onMakeDefault != null || onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textTertiary),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit?.call();
                  case 'default':
                    onMakeDefault?.call();
                  case 'delete':
                    onDelete?.call();
                }
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onMakeDefault != null && !address.isDefault)
                  const PopupMenuItem(
                      value: 'default', child: Text('Set as default')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ]),
      ),
    );
  }
}