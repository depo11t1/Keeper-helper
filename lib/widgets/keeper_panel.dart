import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KeeperPanel extends StatelessWidget {
  const KeeperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.tone = KeeperPanelTone.base,
    this.showBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final KeeperPanelTone tone;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    final color = switch (tone) {
      KeeperPanelTone.base => palette.surface,
      KeeperPanelTone.high => palette.surfaceHigh,
      KeeperPanelTone.accent => palette.accentSurface,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: palette.outline.withValues(alpha: 0.55),
              )
            : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

enum KeeperPanelTone { base, high, accent }
