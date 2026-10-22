# Life & Money

A web app (installable on your phone) to track diet, workouts, sleep and
finances in one place, with recommendations. Data is stored in your browser on
your device.

**What it does now:** log meals (text, calories, photo), workouts, sleep and
account balances, delete any entry, import DBS/POSB bank and credit card
statements (PDF) to see spending by category, and see simple tips based on your
logs. Importing IBKR, Garmin and Claude-powered recommendations come later.

## Importing statements

Open **Spending** (or **Finances**) and tap the upload icon, then pick a
statement PDF. The app reads it on your phone (nothing is uploaded), shows what
it found, and only saves when you tap **Save**. Importing the same statement
twice does nothing. Tap a category, then a transaction, to change its category;
the app remembers it for that merchant. The DBS Savings Plus account is skipped.

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
flutter pub get
flutter run -d chrome
```

## Project layout

- `lib/main.dart`: home screen with the five sections.
- `lib/database.dart`: on-device storage (IndexedDB in the browser).
- `lib/statements/`: reads bank and card statement PDFs.
- `web/pdf_text.js`: extracts text from PDFs in the browser (PDF.js).
- `test/`: automatic tests.
- `.github/workflows/ci.yml`: checks, tests, builds and deploys the website.
