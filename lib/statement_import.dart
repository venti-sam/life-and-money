import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'categories.dart';
import 'database.dart';
import 'format.dart';
import 'statements/detect.dart';
import 'statements/importer.dart';
import 'statements/models.dart';
import 'statements/pdf_text.dart';

/// Lets the user pick a statement PDF, shows what it contains, and saves it
/// if they confirm. Returns true if anything was saved. The file is read on
/// this device and never uploaded.
Future<bool> importStatement(BuildContext context) async {
  final picked = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (picked == null) return false;
  final bytes = await picked.readAsBytes();
  if (!context.mounted) return false;

  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  ParsedStatement? statement;
  StatementKind kind = StatementKind.unknown;
  try {
    final pages = await readPdf(bytes);
    kind = detectStatement(pages);
    statement = parseStatement(pages);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not read that PDF.')),
    );
    return false;
  }

  if (statement == null) {
    messenger.showSnackBar(SnackBar(
      content: Text(kind == StatementKind.ibkr
          ? 'IBKR statements are coming in the next update.'
          : 'This PDF is not a statement I recognise yet.'),
    ));
    return false;
  }

  final plan = await planImport(statement, AppDatabase.instance);
  final saved = await navigator.push<bool>(
    MaterialPageRoute(builder: (_) => ImportPreviewScreen(plan: plan)),
  );
  if (saved == true) {
    messenger.showSnackBar(
      SnackBar(content: Text('Imported ${plan.newTransactions.length} transactions.')),
    );
  }
  return saved == true;
}

class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({super.key, required this.plan});
  final ImportPlan plan;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  var _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await commitImport(widget.plan, AppDatabase.instance);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final statement = plan.statement;
    final own = statement.accountNumbers;
    return Scaffold(
      appBar: AppBar(title: const Text('Check before saving')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${statement.label}${statement.asOf.isEmpty ? '' : ', ${statement.asOf}'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('${plan.newTransactions.length} new transactions'),
          if (plan.duplicates > 0)
            Text('${plan.duplicates} already imported, skipped'),
          if (plan.ignoredTransactions > 0)
            Text('${plan.ignoredTransactions} skipped from '
                '${plan.ignoredAccounts.join(', ')}'),
          if (plan.balancesToSave.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Balances', style: Theme.of(context).textTheme.titleSmall),
            for (final b in plan.balancesToSave)
              Text('${b.name}: ${money(b.amount)}'),
          ],
          if (statement.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Something did not add up:'),
                    for (final w in statement.warnings) Text('• $w'),
                  ],
                ),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Totals check out against the statement.'),
            ),
          const SizedBox(height: 12),
          Text('First transactions',
              style: Theme.of(context).textTheme.titleSmall),
          for (final r in plan.newTransactions.take(12))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(merchantLabel(r['description'] as String,
                  (r['detail'] as String?) ?? '', r['source'] as String)),
              subtitle: Text('${r['date']} · ${categorize(
                source: r['source'] as String,
                amount: (r['amount'] as num).toDouble(),
                description: r['description'] as String,
                detail: (r['detail'] as String?) ?? '',
                ownAccountNumbers: own,
              )}'),
              trailing: Text(money((r['amount'] as num).toDouble())),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: plan.hasChanges && !_saving ? _save : null,
            child: Text(plan.hasChanges ? 'Save' : 'Nothing new to save'),
          ),
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
