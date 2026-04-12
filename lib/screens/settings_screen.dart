import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.currentAccent,
    required this.onAccentChanged,
  });

  final Color currentAccent;
  final ValueChanged<Color> onAccentChanged;

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          'Настройки',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _SettingsBlockCard(
          color: palette.accentSurface,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: accentOptions.map((color) {
              final palette = keeperPalette(context);
              final selected = color.toARGB32() == currentAccent.toARGB32();
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onAccentChanged(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? palette.surfaceHigher : Colors.transparent,
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
          icon: Icons.cloud_outlined,
          title: 'Бекап',
          backgroundColor: palette.accentSurface,
          iconColor: palette.badgeForeground,
          onTap: () => _showStub(
            context,
            'Бекап',
            'Заглушка. Здесь будет экспорт данных приложения.',
          ),
        ),
        const SizedBox(height: 8),
        _SettingsActionTile(
          position: _SettingsBlockPosition.middle,
          icon: Icons.settings_backup_restore_rounded,
          title: 'Восстановление',
          backgroundColor: palette.accentSurface,
          iconColor: palette.badgeForeground,
          onTap: () => _showStub(
            context,
            'Восстановление',
            'Заглушка. Здесь будет восстановление данных из бекапа.',
          ),
        ),
        const SizedBox(height: 8),
        _SettingsActionTile(
          position: _SettingsBlockPosition.bottom,
          icon: Icons.info_outline_rounded,
          title: 'О приложении',
          backgroundColor: palette.accentSurface,
          iconColor: palette.badgeForeground,
          onTap: () => _showStub(
            context,
            'О приложении',
            'Keeper\n\nУчет кормлений, линек и карточек пауков.',
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
              child: const Text('Ок'),
            ),
          ],
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
    final palette = keeperPalette(context);
    return Material(
      color: color ?? palette.surfaceHigh,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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
