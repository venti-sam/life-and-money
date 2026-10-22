import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/statements/bank_statement.dart';
import 'package:life_and_money/statements/card_statement.dart';
import 'package:life_and_money/statements/detect.dart';
import 'package:life_and_money/statements/models.dart';

import 'support/dump.dart';
import 'support/fixtures.dart';

void main() {
  group('bank statement', () {
    final statement = parseBankStatement(pagesFromDump(bankDump));

    test('reads the date and the deposit account balances', () {
      expect(statement.asOf, '2026-09-30');
      expect(statement.balances.map((b) => b.name), [
        'DBS Savings Plus Account',
        'POSB eSavings Account',
        'DBS Multiplier Account',
      ]);
      expect(statement.balances[1].amount, 4490.0);
      expect(statement.accountNumbers, contains('120-900000-4'));
    });

    test('reads transactions with signs taken from the running balance', () {
      final posb = statement.transactions
          .where((t) => t.account == 'POSB eSavings Account')
          .toList();
      expect(posb.map((t) => t.amount), [-10.0, 4000.0, -1000.0]);
      expect(posb[0].date, '2026-09-01');
      expect(posb[0].description, 'Point-of-Sale Transaction');
      expect(posb[0].detail, 'NETS QR PAYMENT 625309325544783 | TO: FAM ROASTED');
      expect(posb[1].detail, contains('ACME RESEARCH PTE LTD'));
    });

    test('reads accounts whose opening balance is written with SGD', () {
      final multiplier = statement.transactions
          .where((t) => t.account == 'DBS Multiplier Account')
          .single;
      expect(multiplier.amount, 1000.0);
    });

    test('skips the CPF section and stray page artefacts', () {
      expect(
        statement.transactions.any((t) => t.description.contains('CPF')),
        isFalse,
      );
      expect(statement.transactions, hasLength(5));
    });

    test('has no warnings when everything adds up', () {
      expect(statement.warnings, isEmpty);
    });

    test('warns when the last balance differs from the summary', () {
      final broken = parseBankStatement(
        pagesFromDump(bankDump.replaceFirst('[444]4,490.00 | [515]4,490.00',
            '[444]9,999.00 | [515]9,999.00')),
      );
      expect(broken.warnings.single, contains('POSB eSavings Account'));
    });

    test('warns when a printed amount does not match the balance change', () {
      final broken = parseBankStatement(
        pagesFromDump(bankDump.replaceFirst('[377]10.00 | [515]1,490.00',
            '[377]12.00 | [515]1,490.00')),
      );
      expect(broken.warnings.any((w) => w.contains('does not match')), isTrue);
    });
  });

  group('card statement', () {
    final statement = parseCardStatement(pagesFromDump(cardDump));

    test('reads the statement date and card', () {
      expect(statement.asOf, '2026-10-12');
      expect(statement.transactions.first.account, 'TEST VISA SIGNATURE …1234');
    });

    test('purchases are negative and CR lines positive', () {
      final byDesc = {for (final t in statement.transactions) t.description: t};
      expect(byDesc['BUS/MRT 926260912']!.amount, -3.64);
      expect(byDesc['BILL PAYMENT - DBS INTERNET/WIRELESS']!.amount, 4100.0);
      expect(byDesc['REFUND SHOP']!.amount, 5.0);
      expect(byDesc['BUS/MRT 926260912']!.date, '2026-09-09');
      expect(byDesc['SOME NEW PLACE']!.date, '2026-10-05');
    });

    test('keeps identical purchases on the same day', () {
      expect(
        statement.transactions
            .where((t) => t.description == 'AVID SPORTS SINGAPORE'),
        hasLength(2),
      );
    });

    test('keeps the foreign currency line as detail', () {
      final airbnb = statement.transactions
          .singleWhere((t) => t.description.startsWith('AIRBNB'));
      expect(airbnb.amount, -1095.29);
      expect(airbnb.detail, 'U. S. DOLLAR 828.24');
    });

    test('purchases add up to the printed sub-total', () {
      expect(statement.warnings, isEmpty);
    });

    test('warns when purchases do not match the sub-total', () {
      final broken = parseCardStatement(
        pagesFromDump(cardDump.replaceFirst('1,191.88', '1,200.00')),
      );
      expect(broken.warnings.single, contains('1200.0'));
    });

    test('December purchases on a January statement are last year', () {
      final jan = parseCardStatement(pagesFromDump('''
--- page 1
[82]STATEMENT DATE | [220]CREDIT LIMIT
[96]12 Jan 2027 | [226]\$10,000.00
[57]TEST CARD NO.: 4111 1111 1111 1234
[54]28 DEC | [95]SHOP | [529]5.00
[54]02 JAN | [95]SHOP | [529]6.00
[575]SUB-TOTAL: | [640]11.00
'''));
      expect(jan.transactions.map((t) => t.date), ['2026-12-28', '2027-01-02']);
    });
  });

  group('detecting statements', () {
    test('recognises each kind', () {
      expect(detectStatement(pagesFromDump('--- page 1\n[1]Consolidated Statement\n[2]Account Summary as at 30 Sep 2026')),
          StatementKind.bank);
      expect(detectStatement(pagesFromDump(cardDump)), StatementKind.card);
      expect(detectStatement(pagesFromDump('--- page 1\n[1]Interactive Brokers Singapore\n[2]Activity Statement')),
          StatementKind.ibkr);
      expect(detectStatement(pagesFromDump('--- page 1\n[1]Hello')),
          StatementKind.unknown);
    });

    test('parseStatement returns null for unsupported files', () {
      expect(parseStatement(pagesFromDump('--- page 1\n[1]Hello')), isNull);
    });
  });
}
