# Life & Money

An Android app to track diet, workouts, sleep and finances in one place, with
recommendations. Everything is stored on your phone.

**Status:** foundation only. The home screen shows five sections (Diet,
Workouts, Sleep, Finances, Recommendations) and the on-phone database is set
up. Logging screens come next.

## Install on your phone (no coding needed)

GitHub builds the app for you.

1. On your computer, open this repo on GitHub and click the **Actions** tab.
2. Click the latest **Build Android APK** run (green tick = success).
3. Scroll to **Artifacts** and download **life-and-money-apk** (a zip).
4. Unzip it to get `app-release.apk` and send it to your phone (Google Drive,
   email, USB cable, etc.).
5. On your vivo X300, open the file. If asked, allow "Install unknown apps"
   for the app you opened it from (Files, Drive, Chrome...). Tap **Install**.

If no run exists yet, click **Build Android APK** in the left list, then
**Run workflow**. It takes about 5-10 minutes.

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
- `.github/workflows/build-apk.yml`: builds the installable APK.
