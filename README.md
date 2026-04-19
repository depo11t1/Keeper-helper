# Keeper

Flutter-приложение для учета животных в террариуме.

Сейчас проект задуман вокруг пауков, но логика уже достаточно универсальна:
- карточки животных
- история кормлений
- история линек
- влажность
- аналитика по каждому животному
- настройки акцентного цвета

Этот README написан как карта проекта, чтобы даже новичок быстро понял:
- что делает приложение
- где лежит каждый экран
- в какой файл идти, если нужно что-то поменять
- где находится тема, модели и моковые данные

## Что умеет приложение

- `Меню` — главный экран со списком всех карточек животных
- `Аналитика` — grouped-графики по всем созданным карточкам
- `Настройки` — выбор акцентного цвета и заглушки под бэкап/восстановление
- карточка животного — фото, влажность, кормления, линьки, редактирование данных

## С чего начать

Если впервые открыл проект, смотри файлы в таком порядке:

1. [lib/main.dart](/home/dmitry/Project/Keeper/lib/main.dart)
2. [lib/models/spider.dart](/home/dmitry/Project/Keeper/lib/models/spider.dart)
3. [lib/theme/app_theme.dart](/home/dmitry/Project/Keeper/lib/theme/app_theme.dart)
4. нужный экран в [lib/screens](/home/dmitry/Project/Keeper/lib/screens)
5. общие UI-виджеты в [lib/widgets](/home/dmitry/Project/Keeper/lib/widgets)
6. моковые данные в [lib/data/sample_data.dart](/home/dmitry/Project/Keeper/lib/data/sample_data.dart)

## Как устроен проект

### Точка входа

Файл: [lib/main.dart](/home/dmitry/Project/Keeper/lib/main.dart)

Что здесь происходит:
- включается русская локаль
- запускается `KeeperApp`
- хранится основное состояние приложения
- настраивается навигация между вкладками
- открываются диалоги, bottom sheet и экран карточки животного

Если коротко: это главный управляющий файл всего приложения.

### Модели данных

Файл: [lib/models/spider.dart](/home/dmitry/Project/Keeper/lib/models/spider.dart)

Здесь описаны:
- `SpiderProfile` — основная карточка животного
- `FeedingEntry` — одна запись о кормлении
- `MoltEntry` — одна запись о линьке
- `SpiderSex` — пол животного

Хотя название модели пока связано с пауками, структуру можно развивать и для других животных.

### Настройки приложения

Файл: [lib/models/app_settings.dart](/home/dmitry/Project/Keeper/lib/models/app_settings.dart)

Здесь хранится:
- текущий акцентный цвет приложения

### Моковые данные

Файл: [lib/data/sample_data.dart](/home/dmitry/Project/Keeper/lib/data/sample_data.dart)

Здесь лежат:
- стартовый акцентный цвет
- стартовый список животных
- тестовые записи кормлений и линек

Если нужно изменить стартовые данные для демо, иди сюда.

### Тема и цвета

Файл: [lib/theme/app_theme.dart](/home/dmitry/Project/Keeper/lib/theme/app_theme.dart)

Здесь находятся:
- базовая AMOLED-палитра
- логика наследования оттенков от акцентного цвета
- `ThemeData` для всего приложения
- типографика, кнопки, поля ввода, нижняя навигация

Если хочешь менять:
- основные цвета
- скругления
- поведение подложек от акцентного цвета
- общий Material 3 стиль

то почти всегда иди в этот файл.

### Design Tokens: Accent System

В проекте используется фиксированный набор из 6 акцентных цветов:

- `violet` `#A78BFA`
- `sky` `#7DD3FC`
- `blue` `#93C5FD`
- `pink` `#F9A8D4`
- `orange` `#FDBA74`
- `green` `#86EFAC`

Маленькие акцентные плашки имеют фиксируемые цвета:

- `badgeForeground = accent`
- `badgeBackground = accent` с `alpha 0.2`

Производные цвета рассчитываются от выбранного акцента через `lerp`:

```dart
// lib/theme/app_theme.dart
accent = selectedAccent;
primary = accent;
badgeForeground = accent;
badgeBackground = accent.withAlpha(0x33); // 0.2

surface = lerp(base.surface, accent, 0.02);
surfaceHigh = lerp(base.surfaceHigh, accent, 0.02);
answerBackground = lerp(base.answerBackground, accent, 0.02);
outline = lerp(base.outline, accent, 0.06);
answerBorder = lerp(base.answerBorder, accent, 0.06);
heroStart = lerp(base.heroStart, accent, 0.08);
```

Большие карточки и подложки берутся из `theme.colorScheme.surfaceContainerLow`.
Это не фиксированный `hex`, а производный цвет от базовой темы и акцента.

### Как это применяется в UI

- Кнопки: `primary = accent`
- Маленькие плашки / badges: `badgeBackground` + `badgeForeground`
- Большие карточки / панели: `colorScheme.surfaceContainerLow`
- Обводки / акценты: `outline` и `answerBorder`
- Пустые состояния в аналитике: мягкий `surfaceContainerLow`, чтобы не спорить с активным акцентом

## Экраны

### Главное меню

Файл: [lib/screens/home_screen.dart](/home/dmitry/Project/Keeper/lib/screens/home_screen.dart)

Здесь:
- список карточек животных
- сортировка по давности последнего кормления
- кнопка создания новой карточки

Если хочешь изменить:
- внешний вид карточки в списке
- порядок показа карточек
- заголовок вкладки

иди сюда.

### Аналитика

Файл: [lib/screens/analytics_placeholder_screen.dart](/home/dmitry/Project/Keeper/lib/screens/analytics_placeholder_screen.dart)

Здесь:
- grouped-блоки по каждому животному
- графики кормлений
- графики линек
- средние интервалы

### Настройки

Файл: [lib/screens/settings_screen.dart](/home/dmitry/Project/Keeper/lib/screens/settings_screen.dart)

Здесь:
- выбор акцентного цвета
- заглушка бэкапа
- заглушка восстановления
- блок о приложении

### Экран карточки животного

Файл: [lib/screens/spider_detail_screen.dart](/home/dmitry/Project/Keeper/lib/screens/spider_detail_screen.dart)

Здесь:
- фото
- влажность
- редактирование имени, вида и пола
- grouped-блоки кормлений
- grouped-блоки линек
- графики с точками по реальным интервалам между событиями

Если хочешь менять основной сценарий ухода за животным, чаще всего нужный код именно здесь.

## Виджеты

### Карточка в списке

Файл: [lib/widgets/spider_card.dart](/home/dmitry/Project/Keeper/lib/widgets/spider_card.dart)

Здесь находится внешний вид карточки на главном экране:
- аватарка
- имя и вид
- кнопка кормления
- нижние плашки `Кормление` и `Линька`

### Аватарка

Файл: [lib/widgets/spider_avatar.dart](/home/dmitry/Project/Keeper/lib/widgets/spider_avatar.dart)

Здесь рисуется:
- дефолтная пустая аватарка
- превью-аватарка, если стиль уже выбран

### Универсальная панель

Файл: [lib/widgets/keeper_panel.dart](/home/dmitry/Project/Keeper/lib/widgets/keeper_panel.dart)

Это общий контейнер для AMOLED-блоков.
Он нужен, чтобы все крупные панели выглядели в одном стиле.

### Таймлайн-график

Файл: [lib/widgets/timeline_chart.dart](/home/dmitry/Project/Keeper/lib/widgets/timeline_chart.dart)

Здесь находится:
- линия событий
- точки по датам
- расчет среднего интервала

Если хочешь поменять:
- размер кружков
- толщину линии
- подписи дат
- алгоритм среднего интервала

иди сюда.

## Как запустить

Если используешь текущую Nix-обвязку:

```bash
nixdev
flutter run -d linux
```

Проверка кода:

```bash
nix develop -c flutter analyze
```

## Как создать репозиторий на GitHub

Для этого проекта на экране создания репозитория лучше выбрать так:

- `Repository name`: `Keeper`
- `Visibility`: `Private`
- `Add README`: `Off`
- `Add .gitignore`: `No .gitignore`
- `Add license`: по желанию, можно пока `No license`

Почему так:
- `README` у проекта уже есть локально
- `.gitignore` уже создан Flutter'ом локально
- если создать README на GitHub сразу, потом при первом push будет лишний merge/rebase

После создания репозитория нужен SSH URL, примерно такой:

```bash
git@github.com:depo11t1/Keeper.git
```

## Как пушить проект

Когда репозиторий уже создан:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:depo11t1/Keeper.git
git branch -M main
git push -u origin main
```

Если SSH-ключи уже настроены в GitHub, этого достаточно.

## Автосборка APK на GitHub

Если ты не хочешь собирать APK на своем ПК, это можно полностью отдать GitHub Actions.

В проект уже добавлен workflow:

```text
.github/workflows/build-release-artifacts.yml
```

Он делает следующее при каждом `push` в `main` или `master`:

- Android:
  - `arm64-v8a` APK
  - universal APK
- Linux:
  - `tar.gz` bundle
  - `AppImage`
- Windows:
  - `Release.zip`

После пуша артефакты можно скачать на GitHub так:

1. Открой вкладку `Actions` в репозитории.
2. Выбери последний запуск workflow `Build Release Artifacts`.
3. Внизу страницы скачай нужные artifacts:
   - `keeper-android-arm64-v8a-apk`
   - `keeper-android-universal-apk`
   - `keeper-linux-x64-tar-gz`
   - `keeper-linux-x64-appimage`
   - `keeper-windows-release-zip`

Windows-платформа в workflow генерируется автоматически на CI, так что отдельной папки `windows/` в репозитории сейчас не требуется.

В этом проекте папка `android/` уже есть, поэтому workflow можно просто пушить в GitHub.

## Что можно сделать следующим шагом

Когда репозиторий будет создан, можно сделать еще 2 вещи:

- запушить проект в приватный репозиторий по SSH
- при желании добавить GitHub Release-публикацию поверх текущих artifacts

## Что еще можно улучшить

- настоящее хранение данных вместо мокового состояния в памяти
- импорт и экспорт JSON/backup
- фото из галереи
- отдельные типы животных помимо пауков
- более глубокая аналитика и фильтры
