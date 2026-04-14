import '../models/app_settings.dart';

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;
  String get localeCode => isRu ? 'ru' : 'en';

  static AppStrings of(AppLanguage language) => AppStrings._(language);

  String get appTitle => 'Keeper';
  String get menu => isRu ? 'Меню' : 'Menu';
  String get analytics => isRu ? 'Аналитика' : 'Analytics';
  String get settings => isRu ? 'Настройки' : 'Settings';
  String get backup => isRu ? 'Бекап' : 'Backup';
  String get restore => isRu ? 'Восстановление' : 'Restore';
  String get aboutApp => isRu ? 'О приложении' : 'About';
  String get archive => isRu ? 'Архив' : 'Archive';
  String get languageLabel => isRu ? 'Язык' : 'Language';
  String get english => 'English';
  String get russian => 'Русский';
  String get ok => isRu ? 'Ок' : 'OK';
  String get cancel => isRu ? 'Отмена' : 'Cancel';
  String get confirm => isRu ? 'Подтвердить' : 'Confirm';
  String get save => isRu ? 'Сохранить' : 'Save';
  String get create => isRu ? 'Создать' : 'Create';
  String get edit => isRu ? 'Редактировать' : 'Edit';
  String get delete => isRu ? 'Удалить' : 'Delete';
  String get moveToArchive => isRu ? 'В архив' : 'Archive';
  String get returnAction => isRu ? 'Вернуть' : 'Restore';
  String get newSpider => isRu ? 'Новый паук' : 'New spider';
  String get name => isRu ? 'Имя' : 'Name';
  String get species => isRu ? 'Вид' : 'Species';
  String get sex => isRu ? 'Пол' : 'Sex';
  String get female => isRu ? 'Самка' : 'Female';
  String get male => isRu ? 'Самец' : 'Male';
  String get dontKnow => isRu ? 'Не знаю' : 'Unknown';
  String get currentStage => isRu ? 'Текущий возраст' : 'Current stage';
  String get age => isRu ? 'Возраст' : 'Stage';
  String get choose => isRu ? 'Выбрать' : 'Choose';
  String get humidity => isRu ? 'Влажность' : 'Humidity';
  String get createMolt => isRu ? 'Новая линька' : 'New molt';
  String get editMolt => isRu ? 'Изменить линьку' : 'Edit molt';
  String get molts => isRu ? 'Линьки' : 'Molts';
  String get feeding => isRu ? 'Кормление' : 'Feeding';
  String get speciesPlaceholder => isRu ? 'Вид неизвестен' : 'Species unknown';
  String get missingValue => '—';
  String get archiveEmpty => isRu ? 'Архив пуст' : 'Archive is empty';
  String get archivedSince => isRu ? 'В архиве с' : 'Archived since';
  String get noActiveCards =>
      isRu ? 'Нет активных карточек.' : 'No active cards.';
  String get analyticsChoose =>
      isRu ? 'Выбери, кто будет участвовать в аналитике.' : 'Choose who participates in analytics.';
  String get noData => isRu ? 'Нет данных' : 'No data';
  String get littleData => isRu ? 'Мало данных' : 'Not enough data';
  String get noFeedings => isRu ? 'Нет кормлений' : 'No feedings';
  String get noMolts => isRu ? 'Нет линек' : 'No molts';
  String get noFeedingRecords =>
      isRu ? 'Пока нет записей о кормлении' : 'No feeding records yet';
  String get noMoltsAdded =>
      isRu ? 'Пока нет записей о линьках' : 'No molt records yet';
  String get avgEats => isRu ? 'В среднем едят' : 'Average feeding';
  String get avgMolts => isRu ? 'В среднем линяют' : 'Average molt';
  String get feedsSlowest => isRu ? 'Кто ест реже всех' : 'Feeds the least';
  String get feedsFastest => isRu ? 'Кто ест чаще всех' : 'Feeds the most';
  String get moltsFastest => isRu ? 'Кто линяет чаще всех' : 'Molts the most';
  String get sortByName => isRu ? 'Имя' : 'Name';
  String get sortByFeedingDate => isRu ? 'Дата кормления' : 'Feeding date';
  String get sortByCreatedDate => isRu ? 'Дата добавления' : 'Date added';
  String get moltLabel => isRu ? 'Линька' : 'Molt';
  String get dateLabel => isRu ? 'Дата' : 'Date';
  String get eatsShort => isRu ? 'Едят' : 'Feeds';
  String get moltsShort => isRu ? 'Линяют' : 'Molts';
  String get archiveStub =>
      isRu ? 'Заглушка. Здесь будет экспорт данных приложения.' : 'Stub. App data export will appear here.';
  String get restoreStub =>
      isRu ? 'Заглушка. Здесь будет восстановление данных из бекапа.' : 'Stub. Backup restore will appear here.';
  String get aboutStub =>
      isRu ? 'Keeper\n\nУчет кормлений, линек и карточек пауков.' : 'Keeper\n\nTrack feedings, molts, and spider cards.';
  String get enterName => isRu ? 'Введите имя' : 'Enter a name';
  String get photoStyle => isRu ? 'Выбрать фото-стиль' : 'Choose photo style';
  String get changePhoto => isRu ? 'Изменить фото' : 'Change photo';
  String get removePhoto => isRu ? 'Удалить фото' : 'Remove photo';
  String get editSpider => isRu ? 'Редактировать паука' : 'Edit spider';
  String get deleteSpiderTitle =>
      isRu ? 'Удалить карточку?' : 'Delete this card?';
  String deleteSpiderMessage(String name) => isRu
      ? 'Карточка $name будет удалена безвозвратно.'
      : '$name will be deleted permanently.';
  String feedSpiderTitle(String name) =>
      isRu ? 'Кормить $name?' : 'Feed $name?';
  String feedMarkPrompt(String formattedDate) => isRu
      ? 'Отметить кормление на $formattedDate?'
      : 'Mark feeding on $formattedDate?';
  String feedingMarked(String name, String formattedDate) => isRu
      ? 'Кормление для $name отмечено на $formattedDate'
      : 'Feeding for $name was marked on $formattedDate';
  String spiderAdded(String name) =>
      isRu ? '$name добавлен в Keeper' : '$name added to Keeper';
  String everyDays(int days) =>
      isRu ? 'каждые $days дн.' : 'every $days d';
  String daysAgo(int days) =>
      isRu ? '$days дн. назад' : '$days d ago';
  String get today => isRu ? 'сегодня' : 'today';
  String get removeFromAnalyticsDone => isRu ? 'Сохранить' : 'Save';
}
