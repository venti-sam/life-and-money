import 'package:flutter/material.dart';

import 'database.dart';

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
  const _Section(this.title, this.subtitle, this.icon, this.table);
  final String title;
  final String subtitle;
  final IconData icon;
  final String? table; // table used to show an entry count, if any
}

const _sections = [
  _Section('Diet', 'Meals by text or photo', Icons.restaurant, 'meals'),
  _Section('Workouts', 'Running, gym, tennis', Icons.fitness_center, 'workouts'),
  _Section('Sleep', 'Hours slept each night', Icons.bedtime, 'sleep'),
  _Section('Finances', 'Savings and investments', Icons.savings, 'balances'),
  _Section('Recommendations', 'Suggestions for you', Icons.lightbulb, null),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Life & Money')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in _sections) _SectionCard(section: s),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _Section section;

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
                future: AppDatabase.instance.count(section.table!),
                builder: (context, snap) =>
                    Text(snap.hasData ? '${snap.data} entries' : ''),
              ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${section.title}: coming soon')),
          );
        },
      ),
    );
  }
}
