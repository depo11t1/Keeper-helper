import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/sample_data.dart';
import 'l10n/app_strings.dart';
import 'models/app_settings.dart';
import 'models/spider.dart';
import 'screens/analytics_placeholder_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/spider_detail_screen.dart';
import 'theme/app_theme.dart';

// Точка входа приложения.
// Здесь включаем русскую локаль и запускаем корневой виджет KeeperApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  Intl.defaultLocale = 'en';
  runApp(const KeeperApp());
}

class KeeperApp extends StatefulWidget {
  const KeeperApp({super.key});

  @override
  State<KeeperApp> createState() => _KeeperAppState();
}

class _KeeperAppState extends State<KeeperApp> {
  // Глобальные ключи нужны, чтобы безопасно открывать диалоги, bottom sheet
  // и snackBar из любого сценария внутри приложения.
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late AppSettings _settings;
  late List<SpiderProfile> _spiders;
  var _currentTab = 0;
  static const _storageKey = 'keeper_state_v1';

  @override
  void initState() {
    super.initState();
    _settings = buildInitialSettings();
    _spiders = buildSampleSpiders();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final settingsJson = data['settings'] as Map<String, dynamic>? ?? {};
    final spidersJson = data['spiders'] as List<dynamic>? ?? [];
    setState(() {
      _settings = AppSettings.fromJson(settingsJson);
      _spiders = spidersJson
          .map((entry) => SpiderProfile.fromJson(entry as Map<String, dynamic>))
          .toList();
      Intl.defaultLocale = AppStrings.of(_settings.language).localeCode;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'settings': _settings.toJson(),
      'spiders': _spiders.map((spider) => spider.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  @override
  Widget build(BuildContext context) {
    final activeSpiders = _spiders.where((spider) => !spider.archived).toList();
    final analyticsSpiders = _filteredAnalyticsSpiders(activeSpiders);
    final strings = AppStrings.of(_settings.language);
    // Все вкладки живут в одном MaterialApp, а тема пересобирается от выбранного
    // акцентного цвета.
    return MaterialApp(
      title: 'Keeper',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      locale: Locale(strings.localeCode),
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: buildKeeperTheme(_settings.accentColor),
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_currentTab) {
            0 => HomeScreen(
                key: const ValueKey('home'),
                spiders: activeSpiders,
                accent: _settings.accentColor,
                language: _settings.language,
                onSpiderTap: _openSpider,
                onSpiderLongPress: _showSpiderActions,
                onFeedTap: (spider) => _confirmFeeding(spider, DateTime.now()),
                onFeedLongPress: _pickFeedingDate,
                onCreateSpider: _createSpider,
              ),
            1 => AnalyticsPlaceholderScreen(
                key: const ValueKey('analytics'),
                spiders: analyticsSpiders,
                accent: _settings.accentColor,
                language: _settings.language,
              ),
            _ => SettingsScreen(
                key: const ValueKey('settings'),
                currentAccent: _settings.accentColor,
                currentLanguage: _settings.language,
                onAccentChanged: (color) {
                  setState(() {
                    _settings.accentColor = color;
                  });
                  _saveState();
                },
                onLanguageChanged: (language) {
                  setState(() {
                    _settings.language = language;
                    Intl.defaultLocale = AppStrings.of(language).localeCode;
                  });
                  _saveState();
                },
                onOpenArchive: _openArchiveSheet,
                onOpenAnalytics: _openAnalyticsSheet,
              ),
          },
        ),
        bottomNavigationBar: NavigationBar(
          height: 76,
          selectedIndex: _currentTab,
          onDestinationSelected: (index) {
            setState(() => _currentTab = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.grid_view_rounded),
              label: strings.menu,
            ),
            NavigationDestination(
              icon: const Icon(Icons.analytics_rounded),
              label: strings.analytics,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_rounded),
              label: strings.settings,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmFeeding(SpiderProfile spider, DateTime date) async {
    // Обычное кормление идет через подтверждение, чтобы не создавать лишние
    // записи случайным тапом.
    final dialogContext = _navigatorKey.currentContext!;
    final strings = AppStrings.of(_settings.language);
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: Row(
            children: [
              Expanded(
                child: Text(strings.feedSpiderTitle(spider.name)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.confirm),
              ),
            ],
          ),
          content: Text(
            strings.feedMarkPrompt(
              DateFormat('d MMMM yyyy', strings.localeCode).format(date),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        spider.feedings.add(FeedingEntry(date: _normalizeDate(date)));
      });
      _saveState();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            strings.feedingMarked(
              spider.name,
              DateFormat('d MMMM', strings.localeCode).format(date),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickFeedingDate(SpiderProfile spider) async {
    // Долгое нажатие на кнопку кормления открывает выбор произвольной даты.
    final dialogContext = _navigatorKey.currentContext!;
    final localeCode = AppStrings.of(_settings.language).localeCode;
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: Locale(localeCode),
    );

    if (picked != null) {
      await _confirmFeeding(spider, picked);
    }
  }

  Future<void> _openSpider(SpiderProfile spider) async {
    // Экран деталей работает поверх текущего списка, поэтому локальные
    // изменения сразу пробрасываем обратно в общий список пауков.
    await _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) {
          return StatefulBuilder(
            builder: (context, detailSetState) {
              void refresh() {
                setState(() {});
                detailSetState(() {});
                _saveState();
              }

              return SpiderDetailScreen(
                spider: spider,
                globalAccent: _settings.accentColor,
                language: _settings.language,
                onAvatarChanged: (seed) {
                  spider.avatarSeed = seed;
                  refresh();
                },
                onPhotoChanged: (path) {
                  spider.photoPath = path;
                  refresh();
                },
                onSpiderUpdated: (name, latinName, sex) {
                  spider.name = name;
                  spider.latinName = latinName;
                  spider.sex = sex;
                  refresh();
                },
                onHumidityUpdated: (humidity) {
                  spider.humidity = humidity;
                  refresh();
                },
                onFeedingEdited: (index, value) {
                  final sorted = spider.feedings.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  final entry = sorted[index];
                  entry.date = _normalizeDate(value);
                  refresh();
                },
                onFeedingDeleted: (index) {
                  final sorted = spider.feedings.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  spider.feedings.remove(sorted[index]);
                  refresh();
                },
                onMoltAdded: () async {
                  final result = await _showCreateMoltDialog(context);
                  if (result != null) {
                    spider.molts.add(result);
                    refresh();
                  }
                },
                onMoltEdited: (index, date, stage) {
                  final sorted = spider.molts.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  final entry = sorted[index];
                  entry
                    ..date = _normalizeDate(date)
                    ..stage = stage;
                  refresh();
                },
                onMoltDeleted: (index) {
                  final sorted = spider.molts.toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  spider.molts.remove(sorted[index]);
                  refresh();
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createSpider() async {
    // Создание нового паука через нижний sheet.
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final latinController = TextEditingController();
    final sheetContext = _navigatorKey.currentContext!;
    final strings = AppStrings.of(_settings.language);

    final created = await showModalBottomSheet<SpiderProfile>(
      context: sheetContext,
      isScrollControlled: true,
      builder: (context) {
        String stage = strings.missingValue;
        SpiderSex sex = SpiderSex.unknown;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.newSpider,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: strings.name),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return strings.enterName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: latinController,
                        decoration: InputDecoration(labelText: strings.species),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.sex,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<SpiderSex>(
                          segments: [
                            ButtonSegment(
                              value: SpiderSex.female,
                              label: Text(strings.female),
                              icon: const Icon(Icons.female_rounded),
                            ),
                            ButtonSegment(
                              value: SpiderSex.male,
                              label: Text(strings.male),
                              icon: const Icon(Icons.male_rounded),
                            ),
                            ButtonSegment(
                              value: SpiderSex.unknown,
                              label: Text(strings.dontKnow),
                              icon: const Icon(Icons.help_outline_rounded),
                            ),
                          ],
                          selected: {sex},
                          onSelectionChanged: (value) {
                            setState(() => sex = value.first);
                          },
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final picked = await _pickMoltStage(context, stage);
                          if (picked != null) {
                            setState(() => stage = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: strings.currentStage,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(stage),
                              const Icon(Icons.keyboard_arrow_down_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(strings.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() != true) {
                                  return;
                                }

                                Navigator.of(context).pop(
                                  SpiderProfile(
                                    id: DateTime.now()
                                        .microsecondsSinceEpoch
                                        .toString(),
                                    name: nameController.text.trim(),
                                    latinName: latinController.text.trim(),
                                    sex: sex,
                                    humidity: 70,
                                    avatarSeed: -1,
                                    accent: _settings.accentColor,
                                    archived: false,
                                    feedings: [],
                                    molts: stage == strings.missingValue
                                        ? []
                                        : [
                                            MoltEntry(
                                              date: _normalizeDate(DateTime.now()),
                                              stage: stage,
                                            ),
                                          ],
                                  ),
                                );
                              },
                              child: Text(strings.create),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (created != null) {
      setState(() {
        _spiders.insert(0, created);
      });
      _saveState();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(strings.spiderAdded(created.name))),
      );
    }
  }

  Future<MoltEntry?> _showCreateMoltDialog(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ru'),
    );
    if (date == null || !context.mounted) {
      return null;
    }

    String stage = 'Неизвестно';
    final pickedStage = await _pickMoltStage(context, stage);
    if (pickedStage != null) {
      stage = pickedStage;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новая линька'),
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      return null;
    }

    return MoltEntry(
      date: _normalizeDate(date),
      stage: stage,
    );
  }

  Future<String?> _pickMoltStage(BuildContext context, String current) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Текущий возраст'),
          children: _moltStageOptions
              .map(
                (value) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(value),
                  child: Text(value),
                ),
              )
              .toList(),
        );
      },
    );
    return result ?? (current == '—' ? null : current);
  }

  List<SpiderProfile> _filteredAnalyticsSpiders(List<SpiderProfile> activeSpiders) {
    final ids = _settings.analyticsIncludeIds;
    if (ids.isEmpty) {
      return activeSpiders;
    }
    return activeSpiders.where((spider) => ids.contains(spider.id)).toList();
  }

  void _showSpiderActions(SpiderProfile spider) {
    final palette = keeperPalette(_navigatorKey.currentContext!);
    final strings = AppStrings.of(_settings.language);
    showModalBottomSheet<void>(
      context: _navigatorKey.currentContext!,
      backgroundColor: palette.surface,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                leading: const Icon(Icons.edit_rounded),
                title: Text(strings.edit),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditSpiderSheetFromMenu(spider);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                leading: const Icon(Icons.archive_outlined),
                title: Text(strings.moveToArchive),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    spider.archived = true;
                    spider.archivedAt = DateTime.now();
                    _settings.analyticsIncludeIds.remove(spider.id);
                  });
                  _saveState();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor:
                    Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.34),
                iconColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.error,
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(strings.delete),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(spider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(SpiderProfile spider) {
    final strings = AppStrings.of(_settings.language);
    showDialog<void>(
      context: _navigatorKey.currentContext!,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteSpiderTitle),
          content: Text(strings.deleteSpiderMessage(spider.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _spiders.removeWhere((item) => item.id == spider.id);
                  _settings.analyticsIncludeIds.remove(spider.id);
                });
                _saveState();
              },
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSpiderSheetFromMenu(SpiderProfile spider) async {
    final strings = AppStrings.of(_settings.language);
    final nameController = TextEditingController(text: spider.name);
    final latinController = TextEditingController(text: spider.latinName);
    final formKey = GlobalKey<FormState>();
    var sex = spider.sex;

    await showModalBottomSheet<void>(
      context: _navigatorKey.currentContext!,
      isScrollControlled: true,
      backgroundColor: keeperPalette(_navigatorKey.currentContext!).surface,
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
                      strings.edit,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: strings.name),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return strings.enterName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: latinController,
                      decoration: InputDecoration(labelText: strings.species),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.sex,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<SpiderSex>(
                        segments: [
                          ButtonSegment(
                            value: SpiderSex.female,
                            label: Text(strings.female),
                            icon: const Icon(Icons.female_rounded),
                          ),
                          ButtonSegment(
                            value: SpiderSex.male,
                            label: Text(strings.male),
                            icon: const Icon(Icons.male_rounded),
                          ),
                          ButtonSegment(
                            value: SpiderSex.unknown,
                            label: Text(strings.dontKnow),
                            icon: const Icon(Icons.help_outline_rounded),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(strings.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() != true) {
                                return;
                              }
                              setState(() {
                                spider.name = nameController.text.trim();
                                spider.latinName = latinController.text.trim();
                                spider.sex = sex;
                              });
                              _saveState();
                              Navigator.of(context).pop();
                            },
                            child: Text(strings.save),
                          ),
                        ),
                      ],
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

  void _openArchiveSheet() {
    final context = _navigatorKey.currentContext!;
    final palette = keeperPalette(context);
    final strings = AppStrings.of(_settings.language);
    final archived = _spiders.where((spider) => spider.archived).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.archive,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              if (archived.isEmpty)
                Text(
                  strings.archiveEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                ...archived.map((spider) {
                  final index = archived.indexOf(spider);
                  final position = archived.length == 1
                      ? _ArchiveTilePosition.single
                      : index == 0
                          ? _ArchiveTilePosition.top
                          : index == archived.length - 1
                              ? _ArchiveTilePosition.bottom
                              : _ArchiveTilePosition.middle;
                  final radius = switch (position) {
                    _ArchiveTilePosition.single => BorderRadius.circular(18),
                    _ArchiveTilePosition.top => const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    _ArchiveTilePosition.middle => BorderRadius.circular(10),
                    _ArchiveTilePosition.bottom => const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                  };
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == archived.length - 1 ? 0 : 6,
                    ),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: radius,
                      child: InkWell(
                        borderRadius: radius,
                        onTap: () {
                          Navigator.of(context).pop();
                          _openSpider(spider);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(spider.name),
                                    const SizedBox(height: 2),
                                    Text(
                                      spider.latinName.trim().isEmpty
                                          ? strings.speciesPlaceholder
                                          : spider.latinName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: keeperPalette(context).textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    spider.archived = false;
                                    spider.archivedAt = null;
                                  });
                                  _saveState();
                                  Navigator.of(context).pop();
                                },
                                child: Text(strings.returnAction),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _openAnalyticsSheet() {
    final context = _navigatorKey.currentContext!;
    final palette = keeperPalette(context);
    final strings = AppStrings.of(_settings.language);
    final activeSpiders = _spiders.where((spider) => !spider.archived).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final selected = _settings.analyticsIncludeIds.isEmpty
        ? activeSpiders.map((spider) => spider.id).toSet()
        : _settings.analyticsIncludeIds.toSet();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.analytics,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.analyticsChoose,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (activeSpiders.isEmpty)
                    Text(
                      strings.noActiveCards,
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...activeSpiders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final spider = entry.value;
                      final position = activeSpiders.length == 1
                          ? _ArchiveTilePosition.single
                          : index == 0
                              ? _ArchiveTilePosition.top
                              : index == activeSpiders.length - 1
                                  ? _ArchiveTilePosition.bottom
                                  : _ArchiveTilePosition.middle;
                      final radius = switch (position) {
                        _ArchiveTilePosition.single => BorderRadius.circular(18),
                        _ArchiveTilePosition.top => const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        _ArchiveTilePosition.middle => BorderRadius.circular(10),
                        _ArchiveTilePosition.bottom => const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                      };

                      final checked = selected.contains(spider.id);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == activeSpiders.length - 1 ? 0 : 6,
                        ),
                        child: Material(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: radius,
                          child: InkWell(
                            borderRadius: radius,
                            onTap: () {
                              setLocalState(() {
                                if (checked) {
                                  selected.remove(spider.id);
                                } else {
                                  selected.add(spider.id);
                                }
                              });
                              setState(() {
                                if (selected.length == activeSpiders.length) {
                                  _settings.analyticsIncludeIds = <String>{};
                                } else {
                                  _settings.analyticsIncludeIds = selected;
                                }
                              });
                              _saveState();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: checked,
                                    onChanged: (_) {
                                      setLocalState(() {
                                        if (checked) {
                                          selected.remove(spider.id);
                                        } else {
                                          selected.add(spider.id);
                                        }
                                      });
                                      setState(() {
                                        if (selected.length == activeSpiders.length) {
                                          _settings.analyticsIncludeIds = <String>{};
                                        } else {
                                          _settings.analyticsIncludeIds = selected;
                                        }
                                      });
                                      _saveState();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(spider.name),
                                        const SizedBox(height: 2),
                                        Text(
                                          spider.latinName.trim().isEmpty
                                              ? strings.speciesPlaceholder
                                              : spider.latinName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: keeperPalette(context).textMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

const _moltStageOptions = [
  'Неизвестно',
  'L1',
  'L2',
  'L3',
  'L4',
  'L5',
  'L6',
  'L7',
  'L8',
  'L9',
  'L10',
  'L11',
  'L12',
  'L13',
  'L14',
  'L15',
];

enum _ArchiveTilePosition { single, top, middle, bottom }
