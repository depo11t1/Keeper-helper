import 'package:flutter/material.dart';

class SpiderAvatar extends StatelessWidget {
  const SpiderAvatar({
    super.key,
    required this.accent,
    this.seed = -1,
    this.label,
    this.size = 68,
  });

  final Color accent;
  final int seed;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPreview = seed >= 0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        color: hasPreview
            ? accent.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10),
      ),
      child: Center(
        child: hasPreview
            ? Icon(
                Icons.photo_size_select_actual_rounded,
                color: Colors.white.withValues(alpha: 0.88),
                size: size * 0.38,
              )
            : Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white.withValues(alpha: 0.82),
                size: size * 0.40,
              ),
      ),
    );
  }
}
