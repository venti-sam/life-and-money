import 'package:flutter/material.dart';

import 'database.dart';
import 'diet_screen.dart';
import 'finances_screen.dart';
import 'recommendations_screen.dart';
import 'sleep_screen.dart';
import 'spending_screen.dart';
import 'workouts_screen.dart';

void main() {
  runApp(const LifeAndMoneyApp());
}

class LifeAndMoneyApp extends StatelessWidget {
  const LifeAndMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life & Money',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class _Section {
  const _Section(this.title, this.subtitle, this.icon, this.table,
      [this.screen]);
  final String title;
  final String subtitle;
  final IconData icon;
  final String? table; // table used to show an entry count, if any
  final Widget Function()? screen; // null = not built yet
}

Widget _spending() => const SpendingScreen();

Widget _recommendations() => const RecommendationsScreen();

const _sections = [
  _Section('Diet', 'Meals by text or photo', Icons.restaurant, 'meals', dietScreen),
  _Section('Workouts', 'Running, gym, tennis', Icons.fitness_center, 'workouts',
      workoutsScreen),
  _Section('Sleep', 'Hours slept each night', Icons.bedtime, 'sleep', sleepScreen),
  _Section('Finances', 'Savings and investments', Icons.savings, 'balances', financesScreen),
  _Section('Spending', 'Where your money goes', Icons.pie_chart, 'transactions',
      _spending),
  _Section('Recommendations', 'Suggestions for you', Icons.lightbulb, null,
      _recommendations),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.countFor});

  /// Returns the entry count for a table. Defaults to the real database;
  /// tests pass their own.
  final Future<int> Function(String table)? countFor;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _refresh = 0; // bumped to reload the entry counts after returning

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Life & Money')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in _sections)
            _SectionCard(
              key: ValueKey('${s.title}$_refresh'),
              section: s,
              countFor: widget.countFor,
              onReturn: () => setState(() => _refresh++),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.section,
    this.countFor,
    required this.onReturn,
  });
  final _Section section;
  final VoidCallback onReturn;
  final Future<int> Function(String table)? countFor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(section.icon, size: 32),
        title: Text(section.title),
        subtitle: Text(section.subtitle),
        trailing: section.table == null
            ? null
            : FutureBuilder<int>(
                future: (countFor ?? AppDatabase.instance.count)(section.table!),
                builder: (context, snap) =>
                    Text(snap.hasData ? '${snap.data} entries' : ''),
              ),
        onTap: () async {
          final screen = section.screen;
          if (screen != null) {
            await Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen()));
            onReturn();
            return;
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${section.title}: coming soon')),
          );
        },
      ),
    );
  }
}
