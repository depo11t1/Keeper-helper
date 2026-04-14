import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.currentAccent,
    required this.currentLanguage,
    required this.onAccentChanged,
    required this.onLanguageChanged,
    required this.onOpenArchive,
    required this.onOpenAnalytics,
  });

  final Color currentAccent;
  final AppLanguage currentLanguage;
  final ValueChanged<Color> onAccentChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback onOpenArchive;
  final VoidCallback onOpenAnalytics;

  static const accentOptions = [
    Color(0xFFA78BFA),
    Color(0xFF7DD3FC),
    Color(0xFF93C5FD),
    Color(0xFFF9A8D4),
    Color(0xFFFDBA74),
    Color(0xFF86EFAC),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final scheme = theme.colorScheme;
    final strings = AppStrings.of(currentLanguage);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          titleSpacing: 20,
          title: Text(
            strings.settings,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _SettingsBlockCard(
          color: scheme.surfaceContainerLow,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: accentOptions.map((color) {
              final selected = color.toARGB32() == currentAccent.toARGB32();
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onAccentChanged(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.surfaceContainerHighest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: selected ? 1 : 0.94,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        _SettingsActionTile(
          position: _SettingsBlockPosition.top,
          icon: Icons.language_rounded,
          title:
              '${strings.languageLabel}: ${currentLanguage == AppLanguage.en ? strings.english : strings.russian}',
          backgroundColor: scheme.surfaceContainerLow,
          iconColor: palette.badgeForeground,
          onTap: () => _showLanguageSheet(context, strings),
        ),
        const SizedBox(height: 8),
        _SettingsActionTile(
          position: _SettingsBlockPosition.middle,
          icon: Icons.archive_outlined,
          title: strings.archive,
          backgroundColor: scheme.surfaceContainerLow,
          iconColor: palette.badgeForeground,
          onTap: onOpenArchive,
        ),
        const SizedBox(height: 8),
        _SettingsActionTile(
          position: _SettingsBlockPosition.bottom,
          icon: Icons.insights_rounded,
          title: strings.analytics,
          backgroundColor: scheme.surfaceContainerLow,
          iconColor: palette.badgeForeground,
          onTap: onOpenAnalytics,
        ),
        const SizedBox(height: 18),
        _SettingsActionTile(
          position: _SettingsBlockPosition.top,
          icon: Icons.cloud_outlined,
          title: strings.backup,
          backgroundColor: scheme.surfaceContainerLow,
          iconColor: palette.badgeForeground,
          onTap: () => _showStub(
            context,
            strings.backup,
            strings.archiveStub,
          ),
        ),
        const SizedBox(height: 8),
        _SettingsActionTile(
          position: _SettingsBlockPosition.middle,
          icon: Icons.settings_backup_restore_rounded,
          title: strings.restore,
          backgroundColor: scheme.surfaceContainerLow,
          iconColor: palette.badgeForeground,
          onTap: () => _showStub(
            context,
            strings.restore,
            strings.restoreStub,
          ),
        ),
        const SizedBox(height: 8),
        _SettingsActionTile(
          position: _SettingsBlockPosition.bottom,
          icon: Icons.info_outline_rounded,
          title: strings.aboutApp,
          backgroundColor: scheme.surfaceContainerLow,
          iconColor: palette.badgeForeground,
          onTap: () => _showStub(
            context,
            strings.aboutApp,
            strings.aboutStub,
          ),
        ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStub(BuildContext context, String title, String text) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.of(currentLanguage).ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, AppStrings strings) {
    final palette = keeperPalette(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.background,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsActionTile(
                icon: Icons.translate_rounded,
                title: strings.english,
                position: _SettingsBlockPosition.top,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                iconColor: keeperPalette(context).badgeForeground,
                onTap: () {
                  onLanguageChanged(AppLanguage.en);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _SettingsActionTile(
                icon: Icons.translate_rounded,
                title: strings.russian,
                position: _SettingsBlockPosition.bottom,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                iconColor: keeperPalette(context).badgeForeground,
                onTap: () {
                  onLanguageChanged(AppLanguage.ru);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _SettingsBlockPosition { single, top, middle, bottom }

class _SettingsBlockCard extends StatelessWidget {
  const _SettingsBlockCard({
    required this.child,
    this.position = _SettingsBlockPosition.single,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final _SettingsBlockPosition position;
  final EdgeInsetsGeometry padding;
  final Color? color;

  BorderRadius _radius() {
    switch (position) {
      case _SettingsBlockPosition.single:
        return BorderRadius.circular(22);
      case _SettingsBlockPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _SettingsBlockPosition.middle:
        return BorderRadius.circular(10);
      case _SettingsBlockPosition.bottom:
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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: color ?? scheme.surfaceContainerLow,
      borderRadius: _radius(),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.position = _SettingsBlockPosition.single,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final _SettingsBlockPosition position;

  BorderRadius _radius() {
    switch (position) {
      case _SettingsBlockPosition.single:
        return BorderRadius.circular(22);
      case _SettingsBlockPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _SettingsBlockPosition.middle:
        return BorderRadius.circular(10);
      case _SettingsBlockPosition.bottom:
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
    final theme = Theme.of(context);
    return _SettingsBlockCard(
      position: position,
      padding: EdgeInsets.zero,
      child: Material(
        color: backgroundColor,
        borderRadius: _radius(),
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
