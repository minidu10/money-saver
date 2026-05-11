# Money Saver

A personal-finance Android app built with Flutter + Firebase.
Distributed as a downloadable APK from this repository — **not** published to any app store.

Latest release: **[v0.3.0](https://github.com/minidu10/money-saver/releases/latest)**

## Features

- 💸 **Income & expense tracking** — 11 default categories (Food, Transport, Salary, …), each with its own icon and color
- 🏦 **Savings goals** — set a target with optional deadline, deposit toward it, see progress
- 🎯 **Monthly budgets per category** — over-budget banner appears on the Home dashboard
- 🔁 **Recurring transactions** — daily / weekly / monthly templates (salary, rent, bills). Missed instances auto-generate on app open
- 📊 **Reports** — pie chart of this month's expenses by category, bar chart of income vs expense over the last 6 months
- 🔍 **Search & filter** — full transactions list with text search and filter by type / category / date range
- ✏️ **Edit & delete** — tap any transaction to edit it; swipe left for quick delete with Undo
- 🌗 **Light / dark theme** — follow-system, light, or dark
- 💱 **Multi-currency display** — LKR, USD, EUR, GBP, INR, JPY, AUD, CAD
- 🔐 **Email + password auth** with password reset
- ☁️ **Real-time cloud sync** — all data lives in Firestore, per-user secure
- 🎨 **Native splash screen** for Android + iOS

## Install (end users)

1. Open the **[Releases page](https://github.com/minidu10/money-saver/releases)** on your Android phone.
2. Download `money-saver-v0.3.0.apk` from the latest release.
3. When prompted to install from "Unknown sources", allow your browser / file manager to install apps.
4. Open the downloaded APK → **Install** → open the app.
5. Sign up with any email + password (≥ 6 characters). Your data syncs automatically.

> iOS install requires sideloading via Xcode + a free Apple ID, or AltStore. Not officially supported.

## Screens

| Tab | Description |
| --- | --- |
| **Home** | Monthly balance card, recent transactions, over-budget banner, quick links to recurring & budgets |
| **Goals** | List of savings goals with progress bars; tap to add a deposit or delete |
| **Reports** | Pie chart (this month by category) + bar chart (last 6 months income vs expense) |
| **Settings** | Profile, currency, theme, app version, source link, sign out |

## Build from source

Prerequisites:
- Flutter 3.41+ (`flutter --version`)
- Android SDK / Android Studio
- For iOS builds: macOS + Xcode

Steps:

```bash
git clone https://github.com/minidu10/money-saver.git
cd money-saver
flutter pub get

# Run in debug on a connected device or emulator:
flutter run

# Build release APK:
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

The Firebase config (`lib/firebase_options.dart`, `android/app/google-services.json`) is committed so the build works out of the box. The bundled API key is a public client identifier; data security is enforced by per-user Firestore rules — only the signed-in user can read or write their own data.

## Project structure

```
lib/
  app.dart              # MaterialApp + theme + router
  main.dart             # entry point (Firebase init, prefs load)
  core/
    format.dart         # money & date formatters
    preferences.dart    # SharedPreferences-backed Riverpod state
    router/             # go_router config (StatefulShellRoute, 4 tabs)
    theme/              # Material 3 light + dark themes
  data/
    default_categories.dart   # 11 hardcoded categories with icons + colors
    models/             # AppTransaction, AppCategory, Budget, Goal, RecurringTemplate
    repositories/       # AuthRepository, TransactionRepository, GoalRepository,
                        # BudgetRepository, RecurringRepository
  features/
    auth/               # login, signup
    home/               # dashboard with balance card + over-budget banner
    transactions/       # add / edit / list / search & filter
    goals/              # list + add savings goals
    budgets/            # monthly limits per category
    recurring/          # recurring transaction templates
    reports/            # pie + bar charts
    settings/           # currency, theme, sign-out
```

## Tech stack

| Layer | Choice |
| ----- | ------ |
| UI | Flutter (Material 3) |
| State | Riverpod 3 |
| Routing | go_router (`StatefulShellRoute` for the 4-tab bottom nav) |
| Backend | Firebase Auth + Cloud Firestore + Crashlytics + Analytics |
| Charts | fl_chart |
| Prefs | shared_preferences |
| Notifications | flutter_local_notifications + FCM |
| Splash | flutter_native_splash |

## Firestore data model

```
users/{uid}
  ├─ transactions/{id}          (type, amount, categoryId, date, note, isRecurring)
  ├─ budgets/{year_month_cat}   (categoryId, limit, year, month)
  ├─ goals/{id}                 (title, target, saved, deadline, createdAt)
  └─ recurring_templates/{id}   (type, amount, categoryId, note, interval, nextDue)
```

Security rules: each user can only read or write under their own `uid`.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Release process

Tagging a commit `vX.Y.Z` triggers the [`Build & release APK`](.github/workflows/release.yml) GitHub Action, which:

1. Resolves dependencies and runs `flutter analyze` + `flutter test`
2. Builds a release APK
3. Renames it `money-saver-vX.Y.Z.apk`
4. Creates a GitHub Release with auto-generated notes and attaches the APK

To cut a release locally:

```bash
# Bump version in pubspec.yaml (e.g. 0.3.1+6)
git commit -am "Bump to 0.3.1"
git tag -a v0.3.1 -m "v0.3.1"
git push origin main && git push origin v0.3.1
```

## Roadmap

- [x] Project scaffolding
- [x] Firebase Auth (email + password)
- [x] Transaction CRUD with categories
- [x] Edit transaction screen
- [x] Search & filter transactions
- [x] Savings goals with deposits
- [x] Monthly budgets with over-budget banner
- [x] Recurring transactions (daily / weekly / monthly)
- [x] Reports: pie + bar charts
- [x] Settings: currency, theme, sign out
- [x] Splash screen
- [x] GitHub Actions APK release pipeline
- [ ] Google Sign-In
- [ ] Custom app icon
- [ ] CSV export / import
- [ ] Local notifications for due bills
- [ ] Onboarding screens
- [ ] Offline mode with Hive cache

## License

MIT
