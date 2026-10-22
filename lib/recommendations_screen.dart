import 'package:flutter/material.dart';

import 'database.dart';
import 'finances_screen.dart';

typedef Rows = List<Map<String, Object?>>;

bool _within7Days(Map<String, Object?> row, String key, DateTime now) {
  final date = DateTime.tryParse(row[key] as String? ?? '');
  if (date == null) return false;
  final days = DateTime(now.year, now.month, now.day).difference(date).inDays;
  return days >= 0 && days < 7;
}

/// Simple rule-based tips from the user's own logs.
List<String> buildTips({
  required Rows sleep,
  required Rows workouts,
  required Rows meals,
  required Rows balances,
  required DateTime now,
}) {
  if (sleep.isEmpty && workouts.isEmpty && meals.isEmpty && balances.isEmpty) {
    return ['Start by logging your sleep, meals, workouts and balances. '
        'Tips will appear here as you add entries.'];
  }
  final tips = <String>[];

  final recentSleep =
      sleep.where((r) => _within7Days(r, 'night', now)).toList();
  if (recentSleep.isNotEmpty) {
    final avg = recentSleep
            .map((r) => (r['hours'] as num).toDouble())
            .reduce((a, b) => a + b) /
        recentSleep.length;
    tips.add(avg < 7
        ? 'You averaged ${avg.toStringAsFixed(1)} hours of sleep recently. '
            'Aim for 7 to 9: try a consistent, earlier bedtime.'
        : 'Sleep looks good: ${avg.toStringAsFixed(1)} hours on average '
            'recently.');
  }

  final recentWorkouts =
      workouts.where((r) => _within7Days(r, 'logged_at', now)).length;
  if (workouts.isNotEmpty || sleep.isNotEmpty || meals.isNotEmpty) {
    if (recentWorkouts == 0) {
      tips.add('No workouts logged in the last 7 days. Even a 20 minute run '
          'or gym session helps.');
    } else if (recentWorkouts < 3) {
      tips.add('$recentWorkouts workout${recentWorkouts == 1 ? '' : 's'} in '
          'the last 7 days. Try for 3 or more.');
    } else {
      tips.add('$recentWorkouts workouts in the last 7 days. Great '
          'consistency.');
    }
  }

  final todayMeals = meals.where((r) {
    final date = DateTime.tryParse(r['logged_at'] as String? ?? '');
    return date != null &&
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  });
  if (todayMeals.isEmpty) {
    tips.add('No meals logged today. Logging as you eat is easiest.');
  }

  if (balances.isNotEmpty) {
    final totals = latestTotals(balances);
    if (totals['Savings']! > 0 && totals['Investment']! == 0) {
      tips.add('You have savings but no investments logged. A common rule of '
          'thumb is to keep 3 to 6 months of expenses in savings before '
          'investing more. This is general information, not financial advice.');
    }
  }
  return tips;
}

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key, DateTime? now}) : _now = now;
  final DateTime? _now;

  Future<List<String>> _load() async {
    final db = AppDatabase.instance;
    return buildTips(
      sleep: await db.all('sleep'),
      workouts: await db.all('workouts'),
      meals: await db.all('meals'),
      balances: await db.all('balances'),
      now: _now ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: FutureBuilder<List<String>>(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Simple tips based on your own logs. Smarter, Claude-powered '
                'recommendations will come later.',
              ),
              const SizedBox(height: 8),
              for (final tip in snap.data!)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(tip),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
