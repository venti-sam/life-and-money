import 'package:flutter/material.dart';

import 'database.dart';

/// A simple list of logged entries for one table, with an Add button.
///
/// [formBuilder] shows the form to fill in and returns the new record, or
/// null if cancelled. [describe] turns a record into the list row text.
class LogScreen extends StatefulWidget {
  const LogScreen({
    super.key,
    required this.title,
    required this.table,
    required this.addLabel,
    required this.formBuilder,
    required this.describe,
  });

  final String title;
  final String table;
  final String addLabel;
  final Future<Map<String, Object?>?> Function(BuildContext context)
      formBuilder;
  final ({String title, String subtitle}) Function(Map<String, Object?> row)
      describe;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Future<List<Map<String, Object?>>> _rows = _load();

  Future<List<Map<String, Object?>>> _load() async =>
      (await AppDatabase.instance.all(widget.table)).reversed.toList();

  Future<void> _add() async {
    final record = await widget.formBuilder(context);
    if (record == null) return;
    await AppDatabase.instance.insert(widget.table, record);
    if (!mounted) return;
    setState(() => _rows = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(widget.addLabel),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _rows,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('Nothing logged yet.'));
          }
          return ListView(
            children: [
              for (final row in rows)
                ListTile(
                  title: Text(widget.describe(row).title),
                  subtitle: Text(widget.describe(row).subtitle),
                ),
            ],
          );
        },
      ),
    );
  }
}

String today() => DateTime.now().toIso8601String().substring(0, 10);
