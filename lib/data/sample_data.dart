import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/spider.dart';

AppSettings buildInitialSettings() {
  return AppSettings(
    accentColor: const Color(0xFF93C5FD),
    language: AppLanguage.en,
    analyticsIncludeIds: <String>{},
  );
}

List<SpiderProfile> buildSampleSpiders() {
  final now = DateTime.now();

  return [
    SpiderProfile(
      id: 'b-smithi',
      name: 'Тора',
      latinName: 'Brachypelma hamorii',
      sex: SpiderSex.female,
      humidity: 68,
      avatarSeed: -1,
      accent: const Color(0xFF86EFAC),
      archived: false,
      archivedAt: null,
      feedings: [
        FeedingEntry(date: now.subtract(const Duration(days: 2))),
        FeedingEntry(date: now.subtract(const Duration(days: 8))),
        FeedingEntry(date: now.subtract(const Duration(days: 13))),
        FeedingEntry(date: now.subtract(const Duration(days: 20))),
        FeedingEntry(date: now.subtract(const Duration(days: 29))),
      ],
      molts: [
        MoltEntry(date: now.subtract(const Duration(days: 32)), stage: 'L4'),
        MoltEntry(date: now.subtract(const Duration(days: 78)), stage: 'L3'),
      ],
    ),
    SpiderProfile(
      id: 'c-versicolor',
      name: 'Мока',
      latinName: 'Caribena versicolor',
      sex: SpiderSex.unknown,
      humidity: 74,
      avatarSeed: -1,
      accent: const Color(0xFF7EC8FF),
      archived: false,
      archivedAt: null,
      feedings: [
        FeedingEntry(date: now.subtract(const Duration(days: 5))),
        FeedingEntry(date: now.subtract(const Duration(days: 11))),
        FeedingEntry(date: now.subtract(const Duration(days: 17))),
        FeedingEntry(date: now.subtract(const Duration(days: 26))),
        FeedingEntry(date: now.subtract(const Duration(days: 34))),
      ],
      molts: [
        MoltEntry(date: now.subtract(const Duration(days: 18)), stage: 'L5'),
        MoltEntry(date: now.subtract(const Duration(days: 49)), stage: 'L4'),
      ],
    ),
    SpiderProfile(
      id: 'g-pulchra',
      name: 'Нокс',
      latinName: 'Grammostola pulchra',
      sex: SpiderSex.male,
      humidity: 61,
      avatarSeed: -1,
      accent: const Color(0xFFFFB86C),
      archived: false,
      archivedAt: null,
      feedings: [
        FeedingEntry(date: now.subtract(const Duration(days: 1))),
        FeedingEntry(date: now.subtract(const Duration(days: 7))),
        FeedingEntry(date: now.subtract(const Duration(days: 14))),
        FeedingEntry(date: now.subtract(const Duration(days: 22))),
        FeedingEntry(date: now.subtract(const Duration(days: 31))),
      ],
      molts: [
        MoltEntry(date: now.subtract(const Duration(days: 64)), stage: 'L3'),
      ],
    ),
  ];
}
