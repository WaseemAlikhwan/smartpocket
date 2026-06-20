# SmartPocket

تطبيق **SmartPocket** لتتبع المصاريف الشخصية — يعمل **محلياً بالكامل** (offline-first) دون اعتماد على خادم خارجي. بياناتك تبقى على جهازك في قاعدة SQLite.

**SmartPocket** is a personal expense tracker — fully **local-first** and **offline-ready**. Your data stays on your device in SQLite.

## Features

- Dashboard with monthly balance, income, expenses, and savings overview
- Expenses and incomes by category
- Per-category monthly budgets with overrun alerts
- Debts and payment tracking
- Recurring entries
- Savings goals with contributions
- Daily, monthly, and yearly reports with charts
- Export reports (PDF / Excel)
- Local notifications for reminders
- Onboarding for initial setup (currency, opening balance, etc.)

For the full feature list and architecture notes, see [FEATURES.md](FEATURES.md) (Arabic).

## Tech stack

| Layer | Technology |
|-------|------------|
| UI | Flutter |
| State | Riverpod |
| Navigation | GoRouter |
| Database | SQLite (`sqflite`, FFI on desktop) |
| Charts | fl_chart |

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.7.2)
- Android Studio / Xcode (for mobile), or a desktop target enabled in Flutter

## Getting started

```bash
cd smartpocket
flutter pub get
flutter run
```

> Run commands from the **`smartpocket`** folder (where `pubspec.yaml` lives), not the parent `SmartPocket2` directory.

### Build APK (Android)

```bash
flutter build apk --release
```

The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

## Project structure

```
lib/
├── core/           # Database, router, constants, services
├── data/           # Repositories, datasources, models
├── domain/         # Entities, repository interfaces
└── presentation/   # Screens, widgets, Riverpod providers
docs/               # Architecture diagrams
```

## Documentation

- [FEATURES.md](FEATURES.md) — detailed feature documentation (Arabic)
- [docs/](docs/) — architecture diagrams (draw.io)

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE).
  <img width="300" alt="Home Screen" src="https://github.com/user-attachments/assets/c9e2993d-9d81-402f-9fb9-ac07bce382f0" />
