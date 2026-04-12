import 'package:flutter/material.dart';

// Пол паука. Unknown нужен, когда пользователь пока не знает пол.
enum SpiderSex {
  female,
  male,
  unknown,
}

class FeedingEntry {
  FeedingEntry({
    required this.date,
    this.note,
  });

  DateTime date;
  String? note;
}

// Одна запись о линьке с датой и возрастной стадией L1-L15.
class MoltEntry {
  MoltEntry({
    required this.date,
    required this.stage,
  });

  DateTime date;
  String stage;
}

// Основная модель карточки животного.
// Пока в проекте это паук, но структура уже довольно универсальна.
class SpiderProfile {
  SpiderProfile({
    required this.id,
    required this.name,
    required this.latinName,
    required this.sex,
    required this.humidity,
    required this.avatarSeed,
    required this.accent,
    required this.feedings,
    required this.molts,
  });

  final String id;
  String name;
  String latinName;
  SpiderSex sex;
  int humidity;
  int avatarSeed;
  Color accent;
  final List<FeedingEntry> feedings;
  final List<MoltEntry> molts;

  FeedingEntry? get lastFeeding =>
      feedings.isEmpty ? null : (feedings.toList()..sort(_sortDesc)).first;

  static int _sortDesc(dynamic a, dynamic b) =>
      (b.date as DateTime).compareTo(a.date as DateTime);
}
