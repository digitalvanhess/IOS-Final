import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const TagChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: context.palette.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.palette.textPrimary),
          ),
        ],
      ),
    );
  }
}
