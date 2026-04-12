import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/keeper_panel.dart';
import '../widgets/spider_avatar.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/timeline_chart.dart';

// Экран подробной карточки животного.
// Здесь редактируются базовые данные, фото, влажность, кормления и линьки.
class SpiderDetailScreen extends StatefulWidget {
  const SpiderDetailScreen({
    super.key,
    required this.spider,
    required this.globalAccent,
    required this.language,
    required this.onAvatarChanged,
    required this.onPhotoChanged,
    required this.onSpiderUpdated,
    required this.onHumidityUpdated,
    required this.onFeedingEdited,
    required this.onFeedingDeleted,
    required this.onMoltAdded,
    required this.onMoltEdited,
    required this.onMoltDeleted,
  });

  final SpiderProfile spider;
  final Color globalAccent;
  final AppLanguage language;
  final ValueChanged<int> onAvatarChanged;
  final ValueChanged<String?> onPhotoChanged;
  final void Function(String name, String latinName, SpiderSex sex) onSpiderUpdated;
  final ValueChanged<int> onHumidityUpdated;
  final void Function(int index, DateTime value) onFeedingEdited;
  final ValueChanged<int> onFeedingDeleted;
  final Future<void> Function() onMoltAdded;
  final void Function(int index, DateTime date, String stage) onMoltEdited;
  final ValueChanged<int> onMoltDeleted;

  @override
  State<SpiderDetailScreen> createState() => _SpiderDetailScreenState();
}

class _SpiderDetailScreenState extends State<SpiderDetailScreen> {
  var _showAllFeedings = false;
  var _showAllMolts = false;
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final scheme = theme.colorScheme;
    final strings = AppStrings.of(widget.language);
    final feedings = widget.spider.feedings.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final molts = widget.spider.molts.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final visibleFeedings = _showAllFeedings ? feedings : feedings.take(2).toList();
    final visibleMolts = _showAllMolts ? molts : molts.take(2).toList();
    final feedingAverage = TimelineChart.averageDays(
      feedings.map((entry) => entry.date).toList()..sort(),
    );
    final moltAverage = TimelineChart.averageDays(
      molts.map((entry) => entry.date).toList()..sort(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spider.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (widget.spider.archived && widget.spider.archivedAt != null) ...[
            KeeperPanel(
              tone: KeeperPanelTone.base,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${strings.archivedSince} '
                    '${DateFormat('d MMMM yyyy', strings.localeCode).format(widget.spider.archivedAt!)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          KeeperPanel(
            tone: KeeperPanelTone.base,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showAvatarActions(context),
                      child: SpiderAvatar(
                        seed: widget.spider.avatarSeed,
                        accent: widget.globalAccent,
                        label: widget.spider.name,
                        size: 94,
                        photoPath: widget.spider.photoPath,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.spider.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.spider.latinName.trim().isEmpty
                                ? strings.speciesPlaceholder
                                : widget.spider.latinName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showHumiditySheet(context),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            palette.badgeBackground,
                            scheme.surfaceContainerLow,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: palette.badgeForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.spider.humidity}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: palette.badgeForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          palette.badgeBackground,
                          scheme.surfaceContainerLow,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.spider.sex == SpiderSex.female
                                ? Icons.female_rounded
                                : widget.spider.sex == SpiderSex.male
                                    ? Icons.male_rounded
                                    : Icons.help_outline_rounded,
                            size: 18,
                            color: palette.badgeForeground,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sexLabel(widget.spider.sex),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: palette.badgeForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _DetailGroupCard(
            position: _DetailGroupPosition.top,
            color: scheme.surfaceContainerLow,
            child: _SummaryStrip(
              title: strings.avgEats,
              value: feedingAverage == null
                  ? strings.littleData
                  : strings.everyDays(feedingAverage),
            ),
          ),
          const SizedBox(height: 6),
          _DetailGroupCard(
            position: _DetailGroupPosition.middle,
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: TimelineChart(
              dates: feedings.map((entry) => entry.date).toList(),
              accent: widget.globalAccent,
              emptyLabel: strings.noFeedingRecords,
              averageLabel: strings.avgEats,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: List.generate(visibleFeedings.length, (index) {
                final entry = visibleFeedings[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleFeedings.length - 1 ? 0 : 6,
                  ),
                  child: _EditableDateTile(
                    position: visibleFeedings.length == 1
                        ? _DetailGroupPosition.bottom
                        : index == visibleFeedings.length - 1
                            ? _DetailGroupPosition.bottom
                            : _DetailGroupPosition.middle,
                    title: DateFormat('d MMMM yyyy', 'ru').format(entry.date),
                    subtitle: null,
                    accent: widget.globalAccent,
                    color: scheme.surfaceContainerLow,
                    onEdit: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: entry.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        locale: const Locale('ru'),
                      );
                      if (picked != null) {
                        final originalIndex = feedings.indexOf(entry);
                        widget.onFeedingEdited(originalIndex, picked);
                        setState(() {});
                      }
                    },
                    onDelete: () {
                      final originalIndex = feedings.indexOf(entry);
                      widget.onFeedingDeleted(originalIndex);
                      setState(() {});
                    },
                  ),
                );
              }),
            ),
          ),
          if (feedings.length > 2) ...[
            const SizedBox(height: 8),
            Center(
              child: IconButton(
                onPressed: () {
                  setState(() => _showAllFeedings = !_showAllFeedings);
                },
                icon: AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _showAllFeedings ? 0.5 : 0.0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _SectionHeader(
            title: strings.molts,
            trailing: FilledButton.icon(
              onPressed: () async {
                await widget.onMoltAdded();
                if (mounted) {
                  setState(() {});
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: palette.badgeBackground,
                foregroundColor: palette.badgeForeground,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.create),
            ),
          ),
          const SizedBox(height: 10),
          _DetailGroupCard(
            position: _DetailGroupPosition.top,
            color: scheme.surfaceContainerLow,
            child: _SummaryStrip(
              title: strings.avgMolts,
              value: moltAverage == null
                  ? strings.littleData
                  : strings.everyDays(moltAverage),
            ),
          ),
          const SizedBox(height: 6),
          _DetailGroupCard(
            position: _DetailGroupPosition.middle,
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: TimelineChart(
              dates: molts.map((entry) => entry.date).toList(),
              accent: widget.globalAccent,
              emptyLabel: strings.noMoltsAdded,
              averageLabel: strings.avgMolts,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: List.generate(visibleMolts.length, (index) {
                final entry = visibleMolts[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleMolts.length - 1 ? 0 : 6,
                  ),
                  child: _EditableDateTile(
                    position: visibleMolts.length == 1
                        ? _DetailGroupPosition.bottom
                        : index == visibleMolts.length - 1
                            ? _DetailGroupPosition.bottom
                            : _DetailGroupPosition.middle,
                    title:
                        '${entry.stage} • ${DateFormat('d MMMM yyyy', 'ru').format(entry.date)}',
                    subtitle: null,
                    accent: widget.globalAccent,
                    color: scheme.surfaceContainerLow,
                    onEdit: () => _showEditMoltDialog(context, entry, molts),
                    onDelete: () {
                      final originalIndex = molts.indexOf(entry);
                      widget.onMoltDeleted(originalIndex);
                      setState(() {});
                    },
                  ),
                );
              }),
            ),
          ),
          if (molts.length > 2) ...[
            const SizedBox(height: 8),
            Center(
              child: IconButton(
                onPressed: () {
                  setState(() => _showAllMolts = !_showAllMolts);
                },
                icon: AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _showAllMolts ? 0.5 : 0.0,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAvatarSheet(BuildContext context) async {
    final palette = keeperPalette(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Выбрать фото-стиль',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(4, (index) {
                  return GestureDetector(
                    onTap: () {
                      widget.onAvatarChanged(index);
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                    child: SpiderAvatar(
                      seed: index,
                      accent: widget.globalAccent,
                      label: widget.spider.name,
                      size: 78,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAvatarActions(BuildContext context) async {
    // Фото меняется не отдельной кнопкой, а по нажатию на саму аватарку.
    final palette = keeperPalette(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                leading: const Icon(Icons.photo_camera_back_rounded),
                title: const Text('Изменить фото'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tileColor:
                    Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.34),
                iconColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.error,
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Удалить фото'),
                onTap: () {
                  widget.onPhotoChanged(null);
                  widget.onAvatarChanged(-1);
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _showPhotoUnavailable();
      return;
    }
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    widget.onPhotoChanged(picked.path);
    setState(() {});
  }

  void _showPhotoUnavailable() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Фото'),
          content: const Text('Выбор фото доступен только на мобильных устройствах.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ок'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHumiditySheet(BuildContext context) async {
    // Влажность задается в процентах через slider.
    final palette = keeperPalette(context);
    double humidity = widget.spider.humidity.toDouble();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Влажность',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${humidity.round()}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Slider(
                    min: 30,
                    max: 100,
                    divisions: 70,
                    value: humidity,
                    onChanged: (value) {
                      setSheetState(() => humidity = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      widget.onHumidityUpdated(humidity.round());
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                    child: const Text('Сохранить'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showEditSpiderSheet(BuildContext context) async {
    // Редактирование базовых полей карточки.
    final nameController = TextEditingController(text: widget.spider.name);
    final latinController = TextEditingController(text: widget.spider.latinName);
    final formKey = GlobalKey<FormState>();
    var sex = widget.spider.sex;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Редактировать паука',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: latinController,
                      decoration: const InputDecoration(labelText: 'Вид'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Пол',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<SpiderSex>(
                        segments: const [
                          ButtonSegment(
                            value: SpiderSex.female,
                            label: Text('Самка'),
                            icon: Icon(Icons.female_rounded),
                          ),
                          ButtonSegment(
                            value: SpiderSex.male,
                            label: Text('Самец'),
                            icon: Icon(Icons.male_rounded),
                          ),
                          ButtonSegment(
                            value: SpiderSex.unknown,
                            label: Text('Не знаю'),
                            icon: Icon(Icons.help_outline_rounded),
                          ),
                        ],
                        selected: {sex},
                        onSelectionChanged: (value) {
                          setLocalState(() => sex = value.first);
                        },
                        style: ButtonStyle(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() != true) {
                          return;
                        }
                        widget.onSpiderUpdated(
                          nameController.text.trim(),
                          latinController.text.trim(),
                          sex,
                        );
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showEditMoltDialog(
    BuildContext context,
    MoltEntry entry,
    List<MoltEntry> sortedEntries,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ru'),
    );
    if (picked == null || !context.mounted) {
      return;
    }

    var stage = entry.stage;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Изменить линьку'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Возраст',
                ),
                child: Text(stage),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final originalIndex = sortedEntries.indexOf(entry);
                widget.onMoltEdited(originalIndex, picked, stage);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.trailing,
  });

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _EditableDateTile extends StatelessWidget {
  const _EditableDateTile({
    required this.position,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final _DetailGroupPosition position;
  final String title;
  final String? subtitle;
  final Color accent;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    return _DetailGroupCard(
      position: position,
      color: color,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        minVerticalPadding: 0,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: palette.textPrimary,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle!,
                  style: TextStyle(color: palette.textMuted),
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_rounded, color: palette.textPrimary),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DetailGroupPosition { single, top, middle, bottom }

class _DetailGroupCard extends StatelessWidget {
  const _DetailGroupCard({
    required this.child,
    required this.color,
    required this.position,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color color;
  final _DetailGroupPosition position;
  final EdgeInsetsGeometry padding;

  BorderRadius _radius() {
    switch (position) {
      case _DetailGroupPosition.single:
        return BorderRadius.circular(22);
      case _DetailGroupPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _DetailGroupPosition.middle:
        return BorderRadius.circular(10);
      case _DetailGroupPosition.bottom:
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
    return Material(
      color: color,
      borderRadius: _radius(),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w400,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SexChoiceChip extends StatelessWidget {
  const _SexChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    final scheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: palette.badgeBackground,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? palette.badgeForeground : palette.textMuted,
            fontWeight: FontWeight.w500,
          ),
      onSelected: (_) => onTap(),
    );
  }
}

String _sexLabel(SpiderSex sex) {
  return switch (sex) {
    SpiderSex.female => 'Самка',
    SpiderSex.male => 'Самец',
    SpiderSex.unknown => 'Пол неизвестен',
  };
}
