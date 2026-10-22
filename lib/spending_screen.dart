import 'package:flutter/material.dart';

import 'categories.dart';
import 'database.dart';
import 'format.dart';
import 'spending.dart';
import 'statement_import.dart';

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  late Future<List<Txn>> _txns = loadTransactions(AppDatabase.instance);
  int _monthIndex = 0; // 0 = newest month

  void _reload() {
    setState(() {
      _txns = loadTransactions(AppDatabase.instance);
    });
  }

  Future<void> _import() async {
    if (await importStatement(context)) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import statement',
            onPressed: _import,
          ),
        ],
      ),
      body: FutureBuilder<List<Txn>>(
        future: _txns,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final txns = snap.data!;
          final months = monthsWithData(txns);
          if (months.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No transactions yet. Import a bank or credit card '
                      'statement (PDF) to see where your money goes.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import statement'),
                    ),
                  ],
                ),
              ),
            );
          }
          final index = _monthIndex.clamp(0, months.length - 1);
          final month = months[index];
          final summary = summarize(txns, month);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Earlier month',
                    onPressed: index < months.length - 1
                        ? () => setState(() => _monthIndex = index + 1)
                        : null,
                  ),
                  Text(monthLabel(month),
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Later month',
                    onPressed: index > 0
                        ? () => setState(() => _monthIndex = index - 1)
                        : null,
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spent: ${money(summary.spending)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Income: ${money(summary.income)}'),
                      Text('Left over: ${money(summary.net)}'),
                      const Text(
                        'Transfers between your accounts, card bill payments '
                        'and investing are not counted as spending.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              for (final entry in summary.byCategory)
                _CategoryRow(
                  category: entry.key,
                  amount: entry.value,
                  share: summary.spending <= 0
                      ? 0
                      : (entry.value / summary.spending).clamp(0.0, 1.0),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => CategoryTransactionsScreen(
                        month: month,
                        category: entry.key,
                      ),
                    ));
                    _reload();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.share,
    required this.onTap,
  });

  final String category;
  final double amount;
  final double share;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category),
                Text('${money(amount)}  (${(share * 100).round()}%)'),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: share),
          ],
        ),
      ),
    );
  }
}

/// The transactions of one category in one month. Tap one to move it (and
/// everything from the same merchant) to another category.
class CategoryTransactionsScreen extends StatefulWidget {
  const CategoryTransactionsScreen({
    super.key,
    required this.month,
    required this.category,
  });

  final String month;
  final String category;

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  late Future<List<Txn>> _txns = _load();

  Future<List<Txn>> _load() async => [
        for (final t in await loadTransactions(AppDatabase.instance))
          if (t.month == widget.month && t.category == widget.category) t,
      ]..sort((a, b) => b.date.compareTo(a.date));

  void _reload() {
    setState(() {
      _txns = _load();
    });
  }

  Future<void> _recategorize(Txn txn) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Category for ${txn.merchant}'),
        children: [
          for (final c in categoryChoices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c),
              child: Text(c),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await saveCategoryRule(AppDatabase.instance, txn, chosen);
    if (!mounted) return;
    _reload();
  }

  Future<void> _delete(Txn txn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this transaction?'),
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
    await AppDatabase.instance.deleteById('transactions', txn.id);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category}, ${monthLabel(widget.month)}'),
      ),
      body: FutureBuilder<List<Txn>>(
        future: _txns,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final txns = snap.data!;
          if (txns.isEmpty) {
            return const Center(child: Text('Nothing here any more.'));
          }
          return ListView(
            children: [
              for (final t in txns)
                ListTile(
                  title: Text(t.merchant),
                  subtitle: Text('${t.date} · tap to change category'),
                  onTap: () => _recategorize(t),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(money(t.amount)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _delete(t),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
