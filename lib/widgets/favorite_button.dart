import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bookmark toggle. Keeps its own state with setState so the icon reacts
/// instantly, and reports every change to the parent through [onChanged].
class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final ValueChanged<bool> onChanged;
  final double size;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onChanged,
    this.size = 22,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool _isFavorite = widget.isFavorite;

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  void _toggle() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onChanged(_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggle,
      tooltip: _isFavorite ? 'Убрать из избранного' : 'В избранное',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          key: ValueKey(_isFavorite),
          size: widget.size,
          color: _isFavorite ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}
