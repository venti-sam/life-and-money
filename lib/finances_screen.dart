import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_screen.dart';

const accountKinds = ['Savings', 'Investment'];

final _amountPattern = RegExp(r'^\d{0,12}([.,]\d{0,2})?$');

double _amount(Map<String, Object?> row) => (row['amount'] as num).toDouble();

/// Total per kind (Savings / Investment), counting only the latest entry for
/// each account name. Rows are in the order they were logged.
Map<String, double> latestTotals(List<Map<String, Object?>> rows) {
  final latest = <String, Map<String, Object?>>{};
  for (final row in rows) {
    final name = (row['account'] as String? ?? '').toLowerCase();
    latest['${row['kind']}|$name'] = row;
  }
  final totals = {for (final k in accountKinds) k: 0.0};
  for (final row in latest.values) {
    final kind = row['kind'] as String;
    totals[kind] = (totals[kind] ?? 0) + _amount(row);
  }
  return totals;
}

Widget financesScreen() => LogScreen(
      title: 'Finances',
      table: 'balances',
      addLabel: 'Log balance',
      formBuilder: (context) => showDialog<Map<String, Object?>>(
        context: context,
        builder: (context) => const _BalanceDialog(),
      ),
      header: (rows) {
        final totals = latestTotals(rows);
        final savings = totals['Savings']!;
        final investments = totals['Investment']!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total: ${(savings + investments).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Savings: ${savings.toStringAsFixed(2)}'),
                Text('Investments: ${investments.toStringAsFixed(2)}'),
                const Text(
                  'Uses the latest balance logged for each account.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
      describe: (row) => LogRow(
        title: '${row['account']}: ${_amount(row).toStringAsFixed(2)}',
        subtitle: '${row['kind']} · ${row['recorded_at']}',
      ),
    );

class _BalanceDialog extends StatefulWidget {
  const _BalanceDialog();

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  final _account = TextEditingController();
  final _amountController = TextEditingController();
  String _kind = accountKinds.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _account,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Account name',
              hintText: 'e.g. POSB savings, IBKR',
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            items: [
              for (final k in accountKinds)
                DropdownMenuItem(value: k, child: Text(k)),
            ],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              TextInputFormatter.withFunction((old, value) =>
                  _amountPattern.hasMatch(value.text) ? value : old),
            ],
            decoration: const InputDecoration(labelText: 'Balance'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final account = _account.text.trim();
            final amount = double.tryParse(
                _amountController.text.trim().replaceAll(',', '.'));
            if (account.isEmpty || amount == null) return;
            Navigator.pop(context, {
              'recorded_at': today(),
              'account': account,
              'kind': _kind,
              'amount': double.parse(amount.toStringAsFixed(2)),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
