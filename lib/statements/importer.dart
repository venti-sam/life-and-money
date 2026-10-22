import '../database.dart';
import 'models.dart';

/// What importing a statement would do, worked out before anything is saved.
class ImportPlan {
  const ImportPlan({
    required this.statement,
    required this.newTransactions,
    required this.duplicates,
    required this.ignoredTransactions,
    required this.balancesToSave,
    required this.ignoredAccounts,
  });

  final ParsedStatement statement;
  final List<Map<String, Object?>> newTransactions;
  final int duplicates; // already imported earlier
  final int ignoredTransactions; // from ignored accounts
  final List<StatementBalance> balancesToSave;
  final List<String> ignoredAccounts;

  bool get hasChanges => newTransactions.isNotEmpty || balancesToSave.isNotEmpty;
}

/// Identifies a transaction so importing the same statement twice (or two
/// overlapping statements) never creates duplicates. Identical rows on the
/// same day (two 39.00 purchases) are told apart by [occurrence].
String fingerprint(StatementTransaction t, int occurrence) => [
      t.account,
      t.date,
      t.description,
      t.amount.toStringAsFixed(2),
      t.balance?.toStringAsFixed(2) ?? '',
      occurrence,
    ].join('|');

Future<ImportPlan> planImport(ParsedStatement statement, AppDatabase db) async {
  final known = {
    for (final row in await db.all('transactions')) row['fp'] as String,
  };
  final seen = <String, int>{};
  final records = <Map<String, Object?>>[];
  var duplicates = 0;
  var ignored = 0;

  for (final t in statement.transactions) {
    if (isIgnoredAccount(t.account)) {
      ignored++;
      continue;
    }
    final base = fingerprint(t, 0);
    final occurrence = seen.update(base, (n) => n + 1, ifAbsent: () => 0);
    final fp = fingerprint(t, occurrence);
    if (known.contains(fp)) {
      duplicates++;
      continue;
    }
    records.add({
      'date': t.date,
      'account': t.account,
      'description': t.description,
      'detail': t.detail,
      'amount': t.amount,
      'source': t.source,
      'fp': fp,
    });
  }

  final savedBalances = {
    for (final row in await db.all('balances'))
      '${row['account']}|${row['recorded_at']}',
  };
  final balances = [
    for (final b in statement.balances)
      if (!isIgnoredAccount(b.name) &&
          !savedBalances.contains('${b.name}|${b.asOf}'))
        b,
  ];

  return ImportPlan(
    statement: statement,
    newTransactions: records,
    duplicates: duplicates,
    ignoredTransactions: ignored,
    balancesToSave: balances,
    ignoredAccounts: [
      for (final b in statement.balances)
        if (isIgnoredAccount(b.name)) b.name,
    ],
  );
}

Future<void> commitImport(ImportPlan plan, AppDatabase db) async {
  await db.insertAll('transactions', plan.newTransactions);
  // Remember every account number (even ignored ones) so transfers between
  // the user's own accounts can be recognised.
  for (final b in plan.statement.balances) {
    await db.upsert('accounts', 'number', {
      'number': b.number,
      'name': b.name,
      'ignored': isIgnoredAccount(b.name),
    });
  }
  await db.insertAll('balances', [
    for (final b in plan.balancesToSave)
      {
        'recorded_at': b.asOf,
        'account': b.name,
        'kind': 'Savings',
        'amount': b.amount,
      },
  ]);
}
