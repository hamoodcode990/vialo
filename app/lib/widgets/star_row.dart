import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A 3-star rating row. Port of decant.html's `starRow()`.
class StarRow extends StatelessWidget {
  final int stars; // 0-3
  final double size;
  const StarRow({super.key, required this.stars, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            on ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: on ? AppColors.gold : AppColors.edge,
          ),
        );
      }),
    );
  }
}
