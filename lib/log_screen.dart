import 'package:flutter/material.dart';

import 'database.dart';

/// How one record is shown in the list.
class LogRow {
  const LogRow({required this.title, this.subtitle, this.leading});
  final String title;
  final String? subtitle;
  final Widget? leading;
}

/// A list of logged entries for one table, with an Add button and a delete
/// button on every entry.
///
/// [formBuilder] shows the form to fill in and returns the new record, or
/// null if cancelled. [describe] turns a record into a list row. [header]
/// optionally shows something above the list (e.g. totals).
class LogScreen extends StatefulWidget {
  const LogScreen({
    super.key,
    required this.title,
    required this.table,
    required this.addLabel,
    required this.formBuilder,
    required this.describe,
    this.header,
  });

  final String title;
  final String table;
  final String addLabel;
  final Future<Map<String, Object?>?> Function(BuildContext context)
      formBuilder;
  final LogRow Function(Map<String, Object?> row) describe;
  final Widget Function(List<Map<String, Object?>> rows)? header;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late Future<List<Map<String, Object?>>> _rows = _load();

  Future<List<Map<String, Object?>>> _load() =>
      AppDatabase.instance.all(widget.table);

  void _reload() {
    setState(() {
      _rows = _load();
    });
  }

  Future<void> _add() async {
    final record = await widget.formBuilder(context);
    if (record == null) return;
    await AppDatabase.instance.insert(widget.table, record);
    if (!mounted) return;
    _reload();
  }

  Future<void> _delete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppDatabase.instance.deleteAt(widget.table, index);
    if (!mounted) return;
    _reload();
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
          return Column(
            children: [
              if (widget.header != null) widget.header!(rows),
              Expanded(
                child: rows.isEmpty
                    ? const Center(child: Text('Nothing logged yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          // Newest first; `index` is the stored position.
                          final index = rows.length - 1 - i;
                          final row = widget.describe(rows[index]);
                          return ListTile(
                            leading: row.leading,
                            title: Text(row.title),
                            subtitle:
                                row.subtitle == null ? null : Text(row.subtitle!),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () => _delete(index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String today() => DateTime.now().toIso8601String().substring(0, 10);
