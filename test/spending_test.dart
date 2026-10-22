import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/categories.dart';
import 'package:life_and_money/database.dart';
import 'package:life_and_money/spending.dart';
import 'package:life_and_money/spending_screen.dart';
import 'package:life_and_money/statement_import.dart';
import 'package:life_and_money/statements/bank_statement.dart';
import 'package:life_and_money/statements/card_statement.dart';
import 'package:life_and_money/statements/importer.dart';

import 'support/dump.dart';
import 'support/fixtures.dart';

void main() {
  final db = AppDatabase.instance;
  setUp(db.resetForTesting);

  Future<void> importBoth() async {
    for (final s in [
      parseBankStatement(pagesFromDump(bankDump)),
      parseCardStatement(pagesFromDump(cardDump)),
    ]) {
      await commitImport(await planImport(s, db), db);
    }
  }

  group('categories', () {
    String cat(String desc, {String detail = '', double amount = -5, String source = 'card', Set<String> own = const {}, Map<String, String> rules = const {}}) =>
        categorize(source: source, amount: amount, description: desc, detail: detail, ownAccountNumbers: own, userRules: rules);

    test('card merchants', () {
      expect(cat('BUS/MRT 926260912'), 'Transport');
      expect(cat('NTUC FP - SHAW PLAZA'), 'Groceries');
      expect(cat('NETFLIX.COM'), 'Subscriptions');
      expect(cat('AIRBNB * HMFP54BT9A'), 'Travel');
      expect(cat('SOME NEW PLACE'), 'Uncategorised');
    });

    test('bank rows: salary, transfers, card payments, investing', () {
      expect(cat('Salary', detail: 'ACME PTE LTD', amount: 4000, source: 'bank'), 'Income');
      expect(cat('Funds Transfer', detail: 'FT1 | 120-900000-4:IB', amount: -1000, source: 'bank', own: {'120-900000-4'}), 'Transfer');
      expect(cat('Bill Payment', detail: 'DBSC-4119110096102428 : I-BANK', amount: -2500, source: 'bank'), 'Card payment');
      expect(cat('FAST Payment / Receipt', detail: 'TO: INTERACTIVE BR SG- REC TRUST AC', amount: -2500, source: 'bank'), 'Investing');
      expect(cat('Funds Transfer', detail: 'TOP-UP TO PAYLAH! : | 97869228', amount: -16, source: 'bank'), 'Wallet top-up');
      expect(cat('Funds Transfer', detail: 'FT2 | IB:SOMEONE | GIFT', amount: 1000, source: 'bank'), 'Transfer');
    });

    test('card payments and refunds', () {
      expect(cat('BILL PAYMENT - DBS INTERNET/WIRELESS', amount: 4100), 'Card payment');
      expect(cat('REFUND SHOP', amount: 5), 'Refund');
    });

    test('a rule set by the user wins and covers reference numbers', () {
      final rules = {merchantKey('BUS/MRT 111111111'): 'Fitness & sports'};
      expect(cat('BUS/MRT 926260912', rules: rules), 'Fitness & sports');
      expect(merchantKey('BUS/MRT 926260912'), merchantKey('BUS/MRT 927510051'));
    });
  });

  group('importing', () {
    test('saves transactions, balances and accounts; skips the ignored account', () async {
      final plan = await planImport(parseBankStatement(pagesFromDump(bankDump)), db);
      expect(plan.newTransactions, hasLength(4)); // 3 POSB + 1 Multiplier
      expect(plan.ignoredTransactions, 1);
      expect(plan.balancesToSave.map((b) => b.name),
          ['POSB eSavings Account', 'DBS Multiplier Account']);
      await commitImport(plan, db);
      expect(await db.count('transactions'), 4);
      expect(await db.count('balances'), 2);
      expect(await db.count('accounts'), 3); // the ignored one too
    });

    test('importing the same statement again changes nothing', () async {
      final statement = parseCardStatement(pagesFromDump(cardDump));
      await commitImport(await planImport(statement, db), db);
      final again = await planImport(statement, db);
      expect(again.newTransactions, isEmpty);
      expect(again.duplicates, statement.transactions.length);
      expect(again.hasChanges, isFalse);
    });

    test('identical purchases on one day are both kept', () async {
      final statement = parseCardStatement(pagesFromDump(cardDump));
      await commitImport(await planImport(statement, db), db);
      final rows = await db.all('transactions');
      expect(rows.where((r) => r['description'] == 'AVID SPORTS SINGAPORE'), hasLength(2));
    });
  });

  group('spending summary', () {
    test('counts spending by category and leaves out transfers and card bill payments', () async {
      await importBoth();
      final txns = await loadTransactions(db);
      expect(monthsWithData(txns), ['2026-10', '2026-09']);
      final sept = summarize(txns, '2026-09');
      expect(sept.income, 4000.0);
      final byCat = {for (final e in sept.byCategory) e.key: e.value};
      expect(byCat['Transport'], 3.64);
      expect(byCat['Travel'], 1095.29);
      expect(byCat['Fitness & sports'], 78.0);
      expect(byCat.containsKey('Transfer'), isFalse);
      expect(byCat.containsKey('Card payment'), isFalse);
      expect(sept.byCategory.first.key, 'Travel'); // largest first
      expect(sept.spending, closeTo(sept.byCategory.fold(0.0, (s, e) => s + e.value), 0.001));
    });

    test('refunds reduce spending', () async {
      await importBoth();
      final oct = summarize(await loadTransactions(db), '2026-10');
      // 10.00 at SOME NEW PLACE minus 5.00 refund; the 4,100 payment is ignored.
      expect(oct.spending, 5.0);
    });

    test('a category rule applies to every transaction from that merchant', () async {
      await importBoth();
      var txns = await loadTransactions(db);
      final place = txns.firstWhere((t) => t.description == 'SOME NEW PLACE');
      expect(place.category, 'Uncategorised');
      await saveCategoryRule(db, place, 'Food & drink');
      txns = await loadTransactions(db);
      expect(txns.firstWhere((t) => t.description == 'SOME NEW PLACE').category, 'Food & drink');
    });
  });

  group('screens', () {
    testWidgets('spending shows an invitation to import when empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SpendingScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Import statement'), findsWidgets);
      expect(find.textContaining('No transactions yet'), findsOneWidget);
    });

    testWidgets('spending shows the month, totals and categories', (tester) async {
      await importBoth();
      await tester.pumpWidget(const MaterialApp(home: SpendingScreen()));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Earlier month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.textContaining('Travel'), findsOneWidget);
      expect(find.textContaining('Income: 4,000.00'), findsOneWidget);
    });

    testWidgets('tapping a transaction lets you change its category', (tester) async {
      await importBoth();
      await tester.pumpWidget(const MaterialApp(home: SpendingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uncategorised'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SOME NEW PLACE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & drink'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing here any more.'), findsOneWidget);
      expect(await db.count('category_rules'), 1);
    });

    testWidgets('a transaction can be deleted', (tester) async {
      await importBoth();
      await tester.pumpWidget(const MaterialApp(home: SpendingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uncategorised'));
      await tester.pumpAndSettle();
      final before = await db.count('transactions');
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await db.count('transactions'), before - 1);
    });

    testWidgets('the import preview shows what will be saved and saves it', (tester) async {
      final plan = await planImport(parseCardStatement(pagesFromDump(cardDump)), db);
      await tester.pumpWidget(MaterialApp(home: ImportPreviewScreen(plan: plan)));
      await tester.pumpAndSettle();
      expect(find.text('8 new transactions'), findsOneWidget);
      expect(find.text('Totals check out against the statement.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Save'), 200);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(await db.count('transactions'), 8);
    });
  });
}
