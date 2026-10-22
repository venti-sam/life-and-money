# Life & Money

A web app (installable on your phone) to track diet, workouts, sleep and
finances in one place, with recommendations. Data is stored in your browser on
your device.

**Status:** foundation only. The home screen shows five sections (Diet,
Workouts, Sleep, Finances, Recommendations). Logging screens come next.

## Open it on your phone

1. In Chrome on your phone, go to https://venti-sam.github.io/life-and-money/
2. Tap the menu (three dots) and choose **Add to Home screen** / **Install app**.

Use the same icon each time and don't clear the site's data, or your entries
are lost.

## How updates work

Every change goes through a pull request. GitHub automatically checks the code,
runs the tests and builds the website. When a change is merged into `main`, the
website above updates by itself. A red cross on a pull request means something
is broken.

## Run it yourself (optional, for developers)

```
flutter create --platforms=web --project-name life_and_money --org com.samuel .
flutter pub get
flutter run -d chrome
```

## Project layout

- `lib/main.dart`: home screen with the five sections.
- `lib/database.dart`: on-device storage.
- `test/`: automatic tests.
- `.github/workflows/ci.yml`: checks, tests, builds and deploys the website.
