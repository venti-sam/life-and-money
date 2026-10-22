import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/finances_screen.dart';

void main() {
  test('totals use the latest balance per account', () {
    final totals = latestTotals([
      {'account': 'POSB', 'kind': 'Savings', 'amount': 1000.0},
      {'account': 'IBKR', 'kind': 'Investment', 'amount': 5000.0},
      {'account': 'posb', 'kind': 'Savings', 'amount': 1200.0},
    ]);
    expect(totals['Savings'], 1200.0);
    expect(totals['Investment'], 5000.0);
  });

  test('no entries gives zero totals', () {
    expect(latestTotals([]), {'Savings': 0.0, 'Investment': 0.0});
  });

  test('a newer statement date wins even if it was logged earlier', () {
    final totals = latestTotals([
      {'account': 'POSB', 'kind': 'Savings', 'amount': 1200.0, 'recorded_at': '2026-09-30'},
      {'account': 'POSB', 'kind': 'Savings', 'amount': 900.0, 'recorded_at': '2026-08-31'},
    ]);
    expect(totals['Savings'], 1200.0);
  });
}
