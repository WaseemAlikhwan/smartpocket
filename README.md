<img width="562" height="1280" alt="image" src="https://github.com/user-attachments/assets/78ed657d-923a-4d56-b75d-acf9a1e1c014" /><img width="562" height="1280" alt="image" src="https://github.com/user-attachments/assets/f0a15d38-c800-44d7-a087-f31fee29b67f" /># SmartPocket

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
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/48aeca28-4128-4625-872f-09171f69a8dc" />
  <img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/2e41a07c-9208-45d7-87b5-f3b49dcfaef3" />

<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/7d75d6ce-950f-4e6c-880e-d1aa9c596615" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/a90ed315-cf19-41f6-af2d-c044cbee4b27" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/6d28570c-a192-4d53-b1ba-d631efb1e666" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/06620895-90fc-47b7-aa76-be705d7260c5" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/46f2c385-90e6-4b42-b120-516c9b9ed05c" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/df1f4a5c-7851-40c8-a9db-144f7f3f3554" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/6132d657-bd31-4d99-8705-59dddc610617" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/665cfdc0-bae7-4007-97af-3885b8459c5b" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/33128e1b-bc75-43de-a041-1468cf08c2e0" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/d07bb52b-35d6-4c39-ba8c-5af859eb9bd0" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/b6894d1c-5b11-4924-809f-4f85e7386b47" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/6a7fdc8a-72e1-46ff-bb7c-729c166705e8" />

<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/fbec2b5a-7d8f-4571-81af-97f85aa38297" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/66f454c4-074e-42a5-b0ea-258af72c71b4" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/f5793ebd-2925-42d1-b2e4-f6371046db9e" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/bc0555e7-dc83-409c-a8ef-616be1e88e19" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/e922e3ae-8c04-47e5-ace9-25dd39e16665" />

<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/8e07c28d-215a-43ec-8d8a-1874e2e46c82" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/31a1aab7-9fb1-47f1-a017-f7ead1c010b9" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/50a8b086-de93-48fd-a526-f232ce83327a" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/6e9f65c3-f387-4806-b414-329861e2319a" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/81d62b85-7e70-4b47-ba65-3083cf8ff105" />
<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/be4be606-3e76-4e56-a940-b2bd349bdc3c" />

<img width="300" height="1280" alt="image" src="https://github.com/user-attachments/assets/b81ebcbf-abb5-4a63-980d-7cf2aeb0be2e" />

