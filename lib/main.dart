import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'data/sample_data.dart';
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
  await initializeDateFormatting('ru');
  Intl.defaultLocale = 'ru';
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

  @override
  void initState() {
    super.initState();
    _settings = buildInitialSettings();
    _spiders = buildSampleSpiders();
  }

  @override
  Widget build(BuildContext context) {
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
      locale: const Locale('ru'),
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
                spiders: _spiders,
                accent: _settings.accentColor,
                onSpiderTap: _openSpider,
                onFeedTap: (spider) => _confirmFeeding(spider, DateTime.now()),
                onFeedLongPress: _pickFeedingDate,
                onCreateSpider: _createSpider,
              ),
            1 => AnalyticsPlaceholderScreen(
                key: const ValueKey('analytics'),
                spiders: _spiders,
                accent: _settings.accentColor,
              ),
            _ => SettingsScreen(
                key: const ValueKey('settings'),
                currentAccent: _settings.accentColor,
                onAccentChanged: (color) {
                  setState(() {
                    _settings.accentColor = color;
                  });
                },
              ),
          },
        ),
        bottomNavigationBar: NavigationBar(
          height: 76,
          selectedIndex: _currentTab,
          onDestinationSelected: (index) {
            setState(() => _currentTab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Меню',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_rounded),
              label: 'Аналитика',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Настройки',
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
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text('Кормить ${spider.name}?'),
          content: Text(
            'Отметить кормление на ${DateFormat('d MMMM yyyy').format(date)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        spider.feedings.add(FeedingEntry(date: _normalizeDate(date)));
      });
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Кормление для ${spider.name} отмечено на ${DateFormat('d MMMM').format(date)}',
          ),
        ),
      );
    }
  }

  Future<void> _pickFeedingDate(SpiderProfile spider) async {
    // Долгое нажатие на кнопку кормления открывает выбор произвольной даты.
    final dialogContext = _navigatorKey.currentContext!;
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ru'),
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
              }

              return SpiderDetailScreen(
                spider: spider,
                globalAccent: _settings.accentColor,
                onAvatarChanged: (seed) {
                  spider.avatarSeed = seed;
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

    final created = await showModalBottomSheet<SpiderProfile>(
      context: sheetContext,
      isScrollControlled: true,
      builder: (context) {
        String stage = 'Неизвестно';
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
                        'Новый паук',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: latinController,
                        decoration: const InputDecoration(
                          labelText: 'Вид',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Пол',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SexChoiceChip(
                            label: 'Самка',
                            selected: sex == SpiderSex.female,
                            onTap: () => setState(() => sex = SpiderSex.female),
                          ),
                          _SexChoiceChip(
                            label: 'Самец',
                            selected: sex == SpiderSex.male,
                            onTap: () => setState(() => sex = SpiderSex.male),
                          ),
                          _SexChoiceChip(
                            label: 'Не знаю',
                            selected: sex == SpiderSex.unknown,
                            onTap: () => setState(() => sex = SpiderSex.unknown),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: stage,
                        items: _moltStageOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => stage = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Текущий возраст',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Отмена'),
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
                                    feedings: [],
                                    molts: [
                                      MoltEntry(
                                        date: _normalizeDate(DateTime.now()),
                                        stage: stage,
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Создать'),
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
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('${created.name} добавлен в Keeper')),
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новая линька'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                initialValue: stage,
                items: _moltStageOptions
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => stage = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Возраст',
                ),
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

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      side: BorderSide.none,
      backgroundColor: palette.surfaceHigh,
      selectedColor: palette.accentSurface,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? palette.textPrimary : palette.textMuted,
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
