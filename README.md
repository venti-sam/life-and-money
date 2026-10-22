# Life & Money

An Android app to track diet, workouts, sleep and finances in one place, with
recommendations. Everything is stored on your phone.

**Status:** foundation only. The home screen shows five sections (Diet,
Workouts, Sleep, Finances, Recommendations) and the on-phone database is set
up. Logging screens come next.

## Install on your phone (no coding needed)

GitHub builds the app for you and publishes it as a download.

1. On your phone, open the repo's **Releases** page:
   https://github.com/venti-sam/life-and-money/releases
2. Under the newest release, tap **life-and-money.apk** to download it.
3. Open the downloaded file. If asked, allow "Install unknown apps" for the
   app you opened it from (Chrome, Files...). Tap **Install**.

## How the automatic checks work

Every time code is pushed or a pull request is opened, GitHub automatically:
checks the code for mistakes, runs the tests, and builds a test version of
the app. A red cross on a pull request means something is broken, so it
should not be merged. A green tick means it passed.

To publish a new version for your phone, add a version tag such as `v0.1.0`.
GitHub then builds the app and attaches it to a Release.

## Run it yourself (optional, for developers)

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and Android
   Studio.
2. Enable Developer options and USB debugging on the phone, plug it in.
3. From this folder:
   ```
   flutter create --platforms=android --project-name life_and_money --org com.samuel .
   flutter pub get
   flutter run
   ```
   (`flutter create .` generates the `android/` folder, which is not stored in
   the repo. It keeps the existing `lib/` code.)

## Project layout

- `lib/main.dart`: home screen with the five sections.
- `lib/database.dart`: on-phone SQLite database (meals, workouts, sleep,
  balances tables).
- `test/`: automatic tests for the database and home screen.
- `.github/workflows/ci.yml`: checks, tests, builds, and publishes releases.
