import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Numeric keypad: 1-9, 000, 0 and backspace in a 3-column grid built
/// from Rows and Expanded, so it stretches to any screen width.
class Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  const Keypad({super.key, required this.onKey, required this.onBackspace});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', '<'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _key(row[i])),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String label) {
    final isBackspace = label == '<';
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isBackspace ? onBackspace : () => onKey(label),
        child: SizedBox(
          height: 52,
          child: Center(
            child: isBackspace
                ? const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
