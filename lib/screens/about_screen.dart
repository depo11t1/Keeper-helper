import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.language,
  });

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(language);
    final palette = keeperPalette(context);
    final accent = palette.accent;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.aboutApp),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFA78BFA),
                  Color(0xFF7DD3FC),
                  Color(0xFF93C5FD),
                  Color(0xFFF9A8D4),
                  Color(0xFFFDBA74),
                  Color(0xFF86EFAC),
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                'Keeper',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 62,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AboutGroupCard(
            position: _AboutGroupPosition.top,
            child: Text(
              strings.aboutStub,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: palette.textPrimary,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          _AboutGroupCard(
            position: _AboutGroupPosition.middle,
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  color: palette.badgeForeground,
                ),
                const SizedBox(width: 10),
                Text(
                  strings.aboutSource,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: palette.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _AboutGroupCard(
            position: _AboutGroupPosition.bottom,
            child: Text(
              strings.aboutVersion,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: palette.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AboutGroupPosition { single, top, middle, bottom }

class _AboutGroupCard extends StatelessWidget {
  const _AboutGroupCard({
    required this.child,
    required this.position,
  });

  final Widget child;
  final _AboutGroupPosition position;

  BorderRadius _radius() {
    switch (position) {
      case _AboutGroupPosition.single:
        return BorderRadius.circular(22);
      case _AboutGroupPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _AboutGroupPosition.middle:
        return BorderRadius.circular(10);
      case _AboutGroupPosition.bottom:
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: _radius(),
      ),
      child: child,
    );
  }
}
