import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/spider_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'data/sample_data.dart';
import 'l10n/app_strings.dart';
import 'models/app_settings.dart';
import 'models/spider.dart';
import 'screens/analytics_placeholder_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/spider_detail_screen.dart';
import 'theme/app_theme.dart';

const _storageKey = 'keeper_state_v1';

class _BootstrapState {
  const _BootstrapState({
    required this.settings,
    required this.spiders,
  });

  final AppSettings settings;
  final List<SpiderProfile> spiders;
}

List<int> _processBackupPhotoBytes(List<int> bytes) {
  final decoded = img.decodeImage(Uint8List.fromList(bytes));
  if (decoded == null) {
    return bytes;
  }
  final baked = img.bakeOrientation(decoded);
  final maxSide = math.max(baked.width, baked.height);
  final resized = maxSide > 1024
      ? img.copyResize(
          baked,
          width: baked.width >= baked.height ? 1024 : null,
          height: baked.height > baked.width ? 1024 : null,
        )
      : baked;
  return img.encodeJpg(resized, quality: 85);
}

List<int>? _encodeBackupArchive(
  Map<String, Object?> input,
) {
  final archive = Archive();
  final manifestRaw = input['manifest'] as String;
  final manifestBytes = utf8.encode(manifestRaw);
  archive.addFile(
    ArchiveFile('backup.json', manifestBytes.length, manifestBytes),
  );

  final photos = (input['photos'] as List<dynamic>?) ?? const [];
  for (final item in photos) {
    final entry = item as Map<String, dynamic>;
    final name = entry['name'] as String;
    final bytes = (entry['bytes'] as List<dynamic>).cast<int>();
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  return ZipEncoder().encode(archive);
}

AppLanguage _resolveSystemLanguage() {
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  for (final locale in locales) {
    final code = locale.languageCode.toLowerCase();
    switch (code) {
      case 'ru':
        return AppLanguage.ru;
      case 'en':
        return AppLanguage.en;
      case 'hi':
        return AppLanguage.hi;
      case 'fr':
        return AppLanguage.fr;
      case 'de':
        return AppLanguage.de;
      case 'es':
        return AppLanguage.es;
      case 'sv':
        return AppLanguage.sv;
      case 'nl':
        return AppLanguage.nl;
      case 'pt':
        return AppLanguage.pt;
      case 'ja':
        return AppLanguage.ja;
    }
  }
  return AppLanguage.en;
}

Future<void> _preparePhotoThumbs(List<SpiderProfile> spiders) async {
  for (final spider in spiders) {
    final path = spider.photoPath;
    if (path == null) {
      continue;
    }
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final thumbPath = await SpiderAvatar.ensureThumbnail(path);
    if (thumbPath != null) {
      await SpiderAvatar.cacheFileForPath(thumbPath);
    }
  }
}

Future<_BootstrapState> _loadBootstrapState() async {
  final defaultSettings = buildInitialSettings(
    language: _resolveSystemLanguage(),
  );
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return _BootstrapState(settings: defaultSettings, spiders: []);
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final settingsJson = data['settings'] as Map<String, dynamic>? ?? {};
    final spidersJson = data['spiders'] as List<dynamic>? ?? [];
    final settings = AppSettings.fromJson(settingsJson);
    final spiders = spidersJson
        .map((entry) => SpiderProfile.fromJson(entry as Map<String, dynamic>))
        .toList();
    await _preparePhotoThumbs(spiders);
    return _BootstrapState(settings: settings, spiders: spiders);
  } catch (_) {
    return _BootstrapState(settings: defaultSettings, spiders: []);
  }
}

// Точка входа приложения.
// Здесь включаем русскую локаль и запускаем корневой виджет KeeperApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  Intl.defaultLocale = 'en';
  final bootstrap = await _loadBootstrapState();
  Intl.defaultLocale =
      AppStrings.of(bootstrap.settings.language).localeCode;
  runApp(
    KeeperApp(
      initialSettings: bootstrap.settings,
      initialSpiders: bootstrap.spiders,
    ),
  );
}

class KeeperApp extends StatefulWidget {
  const KeeperApp({
    super.key,
    required this.initialSettings,
    required this.initialSpiders,
  });

  final AppSettings initialSettings;
  final List<SpiderProfile> initialSpiders;

  @override
  State<KeeperApp> createState() => _KeeperAppState();
}

class _KeeperAppState extends State<KeeperApp> {
  // Глобальные ключи нужны, чтобы безопасно открывать диалоги, bottom sheet
  // и snackBar из любого сценария внутри приложения.
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  OverlayEntry? _topNoticeEntry;
  late AppSettings _settings;
  late List<SpiderProfile> _spiders;
  var _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _spiders = List<SpiderProfile>.from(widget.initialSpiders);
    Intl.defaultLocale = AppStrings.of(_settings.language).localeCode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _precachePhotos());
  }

  void _precachePhotos() {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    for (final spider in _spiders) {
      final path = spider.photoPath;
      if (path == null) {
        continue;
      }
      final file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final resolved = SpiderAvatar.resolvePhotoPath(path);
      SpiderAvatar.precacheForSizes(
        context,
        resolved,
        const [68],
      );
    }
  }

  void _openBackupScreen() {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackupScreen(
          language: _settings.language,
          accent: _settings.accentColor,
          onExport: _exportBackupToDownloads,
          onRestore: _restoreFromFile,
        ),
      ),
    );
  }

  Map<String, dynamic> _buildBackupManifest() {
    final photos = <String, Map<String, String>>{};
    for (final spider in _spiders) {
      final photoPath = spider.photoPath;
      if (photoPath == null) {
        continue;
      }
      final file = File(photoPath);
      if (!file.existsSync()) {
        continue;
      }
      photos[spider.id] = {
        'file': 'photos/${spider.id}.jpg',
      };
    }

    return <String, dynamic>{
      'version': '1.1.0',
      'settings': _settings.toJson(),
      'spiders': _spiders.map((spider) => spider.toJson()).toList(),
      'photos': photos,
    };
  }

  Future<List<int>> _encodeBackupPhoto(String photoPath) async {
    final bytes = await File(photoPath).readAsBytes();
    return compute(_processBackupPhotoBytes, bytes);
  }

  Future<void> _exportBackupToDownloads() async {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    final strings = AppStrings.of(_settings.language);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final targetDir = await _resolveDownloadsDir();
    final keeperDir = Directory(path.join(targetDir.path, 'Keeper'));
    if (!keeperDir.existsSync()) {
      keeperDir.createSync(recursive: true);
    }
    final backupPath =
        path.join(keeperDir.path, 'keeper_backup_$timestamp.kpr.zip');
    final manifest = _buildBackupManifest();
    final photoEntries = <Map<String, Object>>[];
    for (final spider in _spiders) {
      final photoPath = spider.photoPath;
      if (photoPath == null) {
        continue;
      }
      final file = File(photoPath);
      if (!file.existsSync()) {
        continue;
      }
      final entry =
          (manifest['photos'] as Map<String, dynamic>)[spider.id] as Map?;
      final fileName = entry?['file'] as String?;
      if (fileName == null) {
        continue;
      }
      final bytes = await _encodeBackupPhoto(photoPath);
      photoEntries.add({
        'name': fileName,
        'bytes': bytes,
      });
    }
    final zipData = await compute(
      _encodeBackupArchive,
      <String, Object?>{
        'manifest': jsonEncode(manifest),
        'photos': photoEntries,
      },
    );
    if (zipData == null) {
      throw Exception('Backup archive failed');
    }
    await File(backupPath).writeAsBytes(zipData, flush: true);
  }

  Future<void> _restoreFromFile() async {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    final strings = AppStrings.of(_settings.language);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: strings.restore,
        type: FileType.custom,
        allowedExtensions: ['json', 'zip', 'kpr'],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = File(result.files.single.path!);
      final fileBytes = await file.readAsBytes();
      Archive? archive;
      try {
        archive = ZipDecoder().decodeBytes(fileBytes);
      } catch (_) {
        archive = null;
      }
      Map<String, dynamic> data;
      Map<String, dynamic> photos;
      if (archive != null && archive.isNotEmpty) {
        ArchiveFile? manifestFile;
        for (final entry in archive.files) {
          if (entry.name == 'backup.json') {
            manifestFile = entry;
            break;
          }
        }
        if (manifestFile == null || manifestFile.content is! List<int>) {
          throw Exception('Invalid backup');
        }
        final manifestRaw = utf8.decode(manifestFile.content as List<int>);
        data = jsonDecode(manifestRaw) as Map<String, dynamic>;
        photos = (data['photos'] as Map<String, dynamic>? ?? {});
      } else {
        final raw = utf8.decode(fileBytes);
        data = jsonDecode(raw) as Map<String, dynamic>;
        photos = (data['photos'] as Map<String, dynamic>? ?? {});
      }
      final settingsJson = data['settings'] as Map<String, dynamic>? ?? {};
      final spidersJson = data['spiders'] as List<dynamic>? ?? [];
      final photosMap = photos.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );

      final restoredSpiders = spidersJson
          .map((entry) => SpiderProfile.fromJson(entry as Map<String, dynamic>))
          .toList();

      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(dir.path, 'photos'));
      if (!photosDir.existsSync()) {
        photosDir.createSync(recursive: true);
      }

      for (final spider in restoredSpiders) {
        final photoEntry = photosMap[spider.id];
        if (photoEntry == null) {
          spider.photoPath = null;
          continue;
        }
        final fileRef = photoEntry['file'] as String?;
        final dataString = photoEntry['data'] as String?;
        List<int>? bytes;
        String filename = '${spider.id}.jpg';
        if (fileRef != null && archive != null) {
          ArchiveFile? entry;
          for (final fileEntry in archive.files) {
            if (fileEntry.name == fileRef) {
              entry = fileEntry;
              break;
            }
          }
          if (entry != null && entry.content is List<int>) {
            bytes = entry.content as List<int>;
            filename = path.basename(fileRef);
          }
        } else if (dataString != null) {
          bytes = base64Decode(dataString);
          final ext = photoEntry['ext'] as String? ?? 'jpg';
          filename = '${spider.id}.$ext';
        }
        if (bytes == null) {
          spider.photoPath = null;
          continue;
        }
        final targetPath = path.join(photosDir.path, filename);
        await File(targetPath).writeAsBytes(bytes, flush: true);
        spider.photoPath = targetPath;
      }

      final mergedById = <String, SpiderProfile>{
        for (final spider in _spiders) spider.id: spider,
      };
      for (final spider in restoredSpiders) {
        mergedById[spider.id] = spider;
      }
      final mergedSpiders = mergedById.values.toList();
      await _preparePhotoThumbs(mergedSpiders);
      setState(() {
        _settings = AppSettings.fromJson(settingsJson);
        _spiders = mergedSpiders;
        Intl.defaultLocale = AppStrings.of(_settings.language).localeCode;
      });
      await _saveState();
      _precachePhotos();
      _showTopNotice(
        context,
        message: strings.restoreDone,
        accent: keeperPalette(context).accent,
      );
    } catch (_) {
      _showTopNotice(
        context,
        message: strings.restoreFailed,
        accent: keeperPalette(context).accent,
      );
    }
  }

  Future<Directory> _resolveDownloadsDir() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    final fallback = await getDownloadsDirectory();
    if (fallback != null) {
      return fallback;
    }
    return await getApplicationDocumentsDirectory();
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
    final sortedActiveSpiders = _sortSpiders(activeSpiders);
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
        Locale('hi'),
        Locale('fr'),
        Locale('de'),
        Locale('es'),
        Locale('sv'),
        Locale('nl'),
        Locale('pt'),
        Locale('ja'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: buildKeeperTheme(
        _settings.accentColor,
        experimentalTintedBackground:
            _settings.experimentalTintedBackground,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentTab,
          children: [
            HomeScreen(
                key: const ValueKey('home'),
                spiders: sortedActiveSpiders,
                accent: _settings.accentColor,
                language: _settings.language,
                onSpiderTap: _openSpider,
                onSpiderLongPress: _showSpiderActions,
                onFeedTap: (spider) => _confirmFeeding(spider, DateTime.now()),
                onFeedLongPress: _pickFeedingDate,
                onCreateSpider: _createSpider,
                onOpenSort: _openSortSheet,
              ),
            AnalyticsPlaceholderScreen(
                key: const ValueKey('analytics'),
                spiders: analyticsSpiders,
                accent: _settings.accentColor,
                language: _settings.language,
              ),
            SettingsScreen(
                key: const ValueKey('settings'),
                currentAccent: _settings.accentColor,
                currentLanguage: _settings.language,
                experimentalTintedBackground:
                    !_settings.experimentalTintedBackground,
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
                onExperimentalTintedBackgroundChanged: (enabled) {
                  setState(() {
                    _settings.experimentalTintedBackground = !enabled;
                  });
                  _saveState();
                },
                onOpenArchive: _openArchiveSheet,
                onOpenAnalytics: _openAnalyticsSheet,
                onBackup: _openBackupScreen,
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 80,
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
          title: Text(strings.feedSpiderTitle(spider.name)),
          content: Text(
            strings.feedMarkPrompt(
              DateFormat('d MMMM yyyy', strings.localeCode).format(date),
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        spider.feedings.add(FeedingEntry(date: _normalizeDate(date)));
      });
      _saveState();
      _showTopNotice(
        _navigatorKey.currentContext!,
        message: strings.feedingMarked(
          spider.name,
          DateFormat('d MMMM', strings.localeCode).format(date),
        ),
        accent: keeperPalette(_navigatorKey.currentContext!).accent,
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

  List<SpiderProfile> _sortSpiders(List<SpiderProfile> spiders) {
    final items = spiders.toList();
    final descending = _settings.sortDescending;
    final field = _settings.sortField;

    int compare(SpiderProfile a, SpiderProfile b) {
      switch (field) {
        case SortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortField.feedingDate:
          final aDate = a.lastFeeding?.date;
          final bDate = b.lastFeeding?.date;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        case SortField.createdDate:
          return a.createdAt.compareTo(b.createdAt);
      }
    }

    items.sort((a, b) => descending ? -compare(a, b) : compare(a, b));
    return items;
  }

  void _openSortSheet() {
    final context = _navigatorKey.currentContext!;
    final palette = keeperPalette(context);
    final strings = AppStrings.of(_settings.language);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.background,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              Widget buildOption({
                required String title,
                required SortField field,
              }) {
                final selected = _settings.sortField == field;
                final descending = _settings.sortDescending;
                final usesLatin = switch (_settings.language) {
                  AppLanguage.en ||
                  AppLanguage.fr ||
                  AppLanguage.de ||
                  AppLanguage.es ||
                  AppLanguage.pt ||
                  AppLanguage.nl ||
                  AppLanguage.sv =>
                    true,
                  _ => false,
                };
                final label = field == SortField.name
                    ? (_settings.language == AppLanguage.ru
                        ? (descending ? 'Я - А' : 'А - Я')
                        : usesLatin
                            ? (descending ? 'Z - A' : 'A - Z')
                            : (descending ? '↓' : '↑'))
                    : descending
                        ? strings.sortNewestFirst
                        : strings.sortOldestFirst;
                final position = field == SortField.name
                    ? _ArchiveTilePosition.top
                    : field == SortField.createdDate
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

                return Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: radius,
                  child: InkWell(
                    borderRadius: radius,
                    onTap: () {
                      setState(() {
                        if (_settings.sortField == field) {
                          _settings.sortDescending = !_settings.sortDescending;
                        } else {
                          _settings.sortField = field;
                          _settings.sortDescending = false;
                        }
                      });
                      _saveState();
                      setLocalState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (selected)
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: field == SortField.name ? null : 16,
                                    fontWeight: FontWeight.w400,
                                    color: keeperPalette(context).accent,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  buildOption(title: strings.sortByName, field: SortField.name),
                  const SizedBox(height: 8),
                  buildOption(
                    title: strings.sortByFeedingDate,
                    field: SortField.feedingDate,
                  ),
                  const SizedBox(height: 8),
                  buildOption(
                    title: strings.sortByCreatedDate,
                    field: SortField.createdDate,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
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
                  _precachePhotos();
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
                  final result = await _showCreateMoltDialog(context, spider);
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
      backgroundColor: keeperPalette(sheetContext).background,
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
                        decoration: InputDecoration(
                          labelText: strings.name,
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
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
                        decoration: InputDecoration(
                          labelText: strings.species,
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
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
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            side: WidgetStateProperty.all(BorderSide.none),
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.surfaceContainerLow,
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.currentStage,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(stage),
                                  const Icon(Icons.keyboard_arrow_down_rounded),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }

                            Navigator.of(context).pop(
                              SpiderProfile(
                                id:
                                    DateTime.now().microsecondsSinceEpoch.toString(),
                                name: nameController.text.trim(),
                                latinName: latinController.text.trim(),
                                sex: sex,
                                humidity: 71,
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
      _showTopNotice(
        _navigatorKey.currentContext!,
        message: strings.spiderAdded(created.name),
        accent: keeperPalette(_navigatorKey.currentContext!).accent,
      );
    }
  }

  Future<MoltEntry?> _showCreateMoltDialog(
    BuildContext context,
    SpiderProfile spider,
  ) async {
    final palette = keeperPalette(context);
    final strings = AppStrings.of(_settings.language);
    final lastStage = spider.molts.isEmpty
        ? null
        : (spider.molts.toList()
              ..sort((a, b) => b.date.compareTo(a.date)))
            .first
            .stage;
    String stage = _nextMoltStage(lastStage) ?? strings.missingValue;
    DateTime date = DateTime.now();

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: palette.background,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildTile({
              required String title,
              required String value,
              required VoidCallback onTap,
              required _ArchiveTilePosition position,
            }) {
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

              return Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: keeperPalette(context).textMuted,
                                ),
                          ),
                        ),
                        Text(
                          value,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTile(
                    title: strings.moltLabel,
                    value: stage,
                    position: _ArchiveTilePosition.top,
                    onTap: () async {
                      final picked = await _pickMoltStage(context, stage);
                      if (picked != null) {
                        setState(() => stage = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  buildTile(
                    title: strings.dateLabel,
                    value: DateFormat('d MMMM yyyy', strings.localeCode)
                        .format(date),
                    position: _ArchiveTilePosition.bottom,
                    onTap: () async {
                      final picked = await _showThemedDatePicker(
                        context: context,
                        initialDate: date,
                      );
                      if (picked != null) {
                        setState(() => date = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(strings.create),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      return null;
    }

    return MoltEntry(
      date: _normalizeDate(date),
      stage: stage,
    );
  }

  Future<String?> _pickMoltStage(BuildContext context, String current) async {
    final palette = keeperPalette(context);
    final strings = AppStrings.of(_settings.language);
    final options = _moltStageOptions(strings);
    final initialIndex = options.indexOf(current);
    final controller = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 0,
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.background,
      builder: (context) {
        String selected = options[initialIndex >= 0 ? initialIndex : 0];
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.38,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: ListWheelScrollView.useDelegate(
                        controller: controller,
                        itemExtent: 36,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                        setState(() => selected = options[index]);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                          final value = options[index];
                            final isSelected = value == selected;
                            return Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontSize: isSelected ? 24 : 16,
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? palette.badgeForeground
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                    ),
                                child: Text(value),
                              ),
                            );
                          },
                        childCount: options.length,
                        ),
                      ),
                    ),
                    const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: Text(strings.choose),
                  ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return result ?? (current == strings.missingValue ? null : current);
  }

  List<SpiderProfile> _filteredAnalyticsSpiders(List<SpiderProfile> activeSpiders) {
    final ids = _settings.analyticsIncludeIds;
    if (ids.isEmpty) {
      return activeSpiders;
    }
    return activeSpiders.where((spider) => ids.contains(spider.id)).toList();
  }

  Future<DateTime?> _showThemedDatePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) {
    final palette = keeperPalette(context);
    final base = Theme.of(context);
    final localeCode = AppStrings.of(_settings.language).localeCode;
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: Locale(localeCode),
      builder: (context, child) {
        return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: palette.accent,
            onPrimary: base.colorScheme.onPrimary,
            surface: palette.surface,
            onSurface: palette.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: palette.surface,
            headerBackgroundColor: palette.surfaceHigh,
            headerForegroundColor: palette.textPrimary,
            dayForegroundColor: WidgetStateProperty.all(palette.textPrimary),
            todayForegroundColor: WidgetStateProperty.all(palette.accent),
            todayBackgroundColor:
                WidgetStateProperty.all(palette.accent.withValues(alpha: 0.16)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
          child: child!,
        );
      },
    );
  }

  String? _nextMoltStage(String? current) {
    final strings = AppStrings.of(_settings.language);
    if (current == null ||
        current == strings.missingValue ||
        current == strings.dontKnow) {
      return strings.dontKnow;
    }
    final match = RegExp(r'^L(\d+)$').firstMatch(current);
    if (match == null) {
      return current;
    }
    final value = int.tryParse(match.group(1) ?? '');
    if (value == null) {
      return current;
    }
    final next = value + 1;
    if (next > 15) {
      return 'L15';
    }
    return 'L$next';
  }

  void _showSpiderActions(SpiderProfile spider) {
    final palette = keeperPalette(_navigatorKey.currentContext!);
    final strings = AppStrings.of(_settings.language);
    showModalBottomSheet<void>(
      context: _navigatorKey.currentContext!,
      backgroundColor: palette.background,
      builder: (context) {
        Widget buildActionTile({
          required String title,
          required IconData icon,
          required _ArchiveTilePosition position,
          required VoidCallback onTap,
          Color? backgroundColor,
          Color? iconColor,
          Color? textColor,
        }) {
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

          return Material(
            color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildActionTile(
                title: strings.edit,
                icon: Icons.edit_rounded,
                position: _ArchiveTilePosition.top,
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditSpiderSheetFromMenu(spider);
                },
              ),
              const SizedBox(height: 6),
              buildActionTile(
                title: strings.moveToArchive,
                icon: Icons.archive_outlined,
                position: _ArchiveTilePosition.middle,
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
              const SizedBox(height: 6),
              buildActionTile(
                title: strings.delete,
                icon: Icons.delete_outline_rounded,
                position: _ArchiveTilePosition.bottom,
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.34),
                iconColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.error,
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
          actionsAlignment: MainAxisAlignment.end,
          actions: [
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
      backgroundColor: keeperPalette(_navigatorKey.currentContext!).background,
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
                      decoration: InputDecoration(
                        labelText: strings.name,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                      decoration: InputDecoration(
                        labelText: strings.species,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          side: WidgetStateProperty.all(BorderSide.none),
                          backgroundColor: WidgetStateProperty.all(
                            Theme.of(context).colorScheme.surfaceContainerLow,
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
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

    if (archived.isEmpty) {
      _showTopNotice(
        context,
        message: strings.archiveEmpty,
        accent: palette.accent,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.background,
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
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    strings.archiveEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

  void _showTopNotice(
    BuildContext context, {
    required String message,
    required Color accent,
  }) {
    final overlay = _navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _topNoticeEntry?.remove();
    _topNoticeEntry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;
        final background = Theme.of(context).colorScheme.surfaceContainerLow;
        return Positioned(
          left: 16,
          right: 16,
          top: topPadding + 12,
          child: Material(
            color: background,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_topNoticeEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      _topNoticeEntry?.remove();
      _topNoticeEntry = null;
    });
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
      backgroundColor: palette.background,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.72,
                  ),
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
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children: activeSpiders.asMap().entries.map((entry) {
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
                                          _RoundSelectionIndicator(
                                            checked: checked,
                                            accent: keeperPalette(context).badgeForeground,
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
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
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

List<String> _moltStageOptions(AppStrings strings) => [
      strings.dontKnow,
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

class _RoundSelectionIndicator extends StatelessWidget {
  const _RoundSelectionIndicator({
    required this.checked,
    required this.accent,
  });

  final bool checked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = checked
        ? accent
        : Color.alphaBlend(
            accent.withValues(alpha: 0.08),
            scheme.surfaceContainerHighest.withValues(alpha: 0.96),
          );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
          color: checked
              ? accent.withValues(alpha: 0.92)
              : accent.withValues(alpha: 0.34),
          width: checked ? 1.2 : 1.4,
        ),
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color: scheme.onPrimary,
            )
          : null,
    );
  }
}
