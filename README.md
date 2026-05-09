# Money Saver

A personal-finance Android app built with Flutter + Firebase.
Distributed as a downloadable APK from this repository — **not** published to any app store.

## Features (planned)

- Income & expense tracking with categories
- Monthly budgets per category
- Savings goals with deadline + progress
- Charts and reports (pie, bar, monthly trends)
- Recurring transactions and reminders
- Cloud sync via Firebase (optional account)
- Works offline (Hive cache)

## Install (end users)

1. Go to the [Releases](https://github.com/minidu10/money-saver/releases) page.
2. Download the latest `app-release.apk`.
3. On your Android phone: **Settings → Apps → Special app access → Install unknown apps** and allow your file manager / browser.
4. Open the downloaded APK and install.

> iOS install requires sideloading via Xcode + a free Apple ID, or AltStore. Not officially supported.

## Build from source

Prerequisites:
- Flutter 3.41+ (`flutter --version`)
- Android SDK / Android Studio
- A Firebase project (free) with Android app registered to package `com.minidu.moneysaver.money_saver`

Steps:
```bash
git clone https://github.com/minidu10/money-saver.git
cd money-saver
flutter pub get

# Wire up Firebase config (one-time):
dart pub global activate flutterfire_cli
flutterfire configure

# Run in debug:
flutter run

# Build release APK:
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Project structure

```
lib/
  app.dart            # MaterialApp + theme + router
  main.dart           # entry point
  core/
    theme/            # color schemes, typography
    router/           # go_router config
  data/
    models/           # Transaction, Category, Budget, Goal
    repositories/     # Firestore + local cache wrappers
  features/
    auth/             # login, signup
    home/             # dashboard
    transactions/     # add/list/edit
    budgets/          # monthly limits
    goals/            # savings goals
    reports/          # charts
    settings/         # currency, theme, export
```

## Tech stack

| Layer        | Choice                                   |
| ------------ | ---------------------------------------- |
| UI           | Flutter (Material 3)                     |
| State        | Riverpod                                 |
| Routing      | go_router                                |
| Backend      | Firebase Auth + Firestore + FCM          |
| Local cache  | Hive                                     |
| Charts       | fl_chart                                 |
| Notifications| flutter_local_notifications              |

## Roadmap

- [x] Project scaffolding
- [ ] Firebase Auth (email + Google)
- [ ] Transaction CRUD
- [ ] Category management
- [ ] Budgets
- [ ] Savings goals
- [ ] Charts & reports
- [ ] Recurring transactions
- [ ] Local notifications
- [ ] CSV export
- [ ] Onboarding & polish

## License

MIT
