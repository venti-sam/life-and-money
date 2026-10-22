# Life & Money

An Android app to track diet, workouts, sleep and finances in one place, with
recommendations. Everything is stored on your phone.

**Status:** foundation only. The home screen shows five sections (Diet,
Workouts, Sleep, Finances, Recommendations) and the on-phone database is set
up. Logging screens come next.

## Open it on your phone (web app, recommended)

The app is a website that works like an app:

1. On your phone, open Chrome and go to
   https://venti-sam.github.io/life-and-money/
2. Tap the menu (three dots) and choose **Add to Home screen** (or **Install
   app**). It now has an icon like any other app.

Your data is saved in the browser on that phone. Use the same browser/icon
each time, and don't clear the site's data.

## Android app (optional)

Open the repo's **Releases** page on your phone, download
**life-and-money.apk** from the newest release, open it and tap **Install**
(allow "Install unknown apps" if asked).

## How the automatic checks work

Every time code is pushed or a pull request is opened, GitHub automatically:
checks the code for mistakes, runs the tests, and builds the website and a test Android
version. When changes reach `main`, the website is updated automatically. A red cross on a pull request means something is broken, so it
should not be merged. A green tick means it passed.

To publish a new version for your phone, add a version tag such as `v0.1.0`.
GitHub then builds the app and attaches it to a Release.

## Run it yourself (optional, for developers)

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and Android
   Studio.
2. Enable Developer options and USB debugging on the phone, plug it in.
3. From this folder:
   ```
   flutter create --platforms=android,web --project-name life_and_money --org com.samuel .
   flutter pub get
   flutter run -d chrome   # or your phone
   ```
   (`flutter create .` generates the `android/` and `web/` folders, which is not stored in
   the repo. It keeps the existing `lib/` code.)

## Project layout

- `lib/main.dart`: home screen with the five sections.
- `lib/database.dart`: on-phone SQLite database (meals, workouts, sleep,
  balances tables).
- `test/`: automatic tests for the database and home screen.
- `.github/workflows/ci.yml`: checks, tests, builds, and publishes releases.
