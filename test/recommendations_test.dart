import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/recommendations_screen.dart';

void main() {
  final now = DateTime(2026, 10, 22);

  List<String> tips({
    Rows sleep = const [],
    Rows workouts = const [],
    Rows meals = const [],
    Rows balances = const [],
  }) =>
      buildTips(
        sleep: sleep,
        workouts: workouts,
        meals: meals,
        balances: balances,
        now: now,
      );

  test('no data gives a single getting-started tip', () {
    final result = tips();
    expect(result, hasLength(1));
    expect(result.first, contains('Start by logging'));
  });

  test('low sleep average gets a sleep tip', () {
    final result = tips(sleep: [
      {'night': '2026-10-21', 'hours': 5.0},
      {'night': '2026-10-20', 'hours': 6.0},
    ]);
    expect(result.any((t) => t.contains('5.5 hours')), isTrue);
  });

  test('no recent workouts gets a workout tip', () {
    final result = tips(sleep: [
      {'night': '2026-10-21', 'hours': 8.0},
    ]);
    expect(result.any((t) => t.contains('No workouts')), isTrue);
  });

  test('three workouts this week is praised', () {
    final result = tips(workouts: [
      for (final d in ['2026-10-20', '2026-10-21', '2026-10-22'])
        {'logged_at': d, 'type': 'Gym', 'duration_minutes': 30},
    ]);
    expect(result.any((t) => t.contains('Great consistency')), isTrue);
  });

  test('savings without investments gets a general note', () {
    final result = tips(balances: [
      {'account': 'POSB', 'kind': 'Savings', 'amount': 1000.0},
    ]);
    expect(result.any((t) => t.contains('not financial advice')), isTrue);
  });
}
