import 'categories.dart';
import 'database.dart';

/// A transaction with its category worked out.
class Txn {
  const Txn({
    required this.id,
    required this.date,
    required this.account,
    required this.description,
    required this.detail,
    required this.amount,
    required this.source,
    required this.category,
  });

  final int id;
  final String date; // yyyy-MM-dd
  final String account;
  final String description;
  final String detail;
  final double amount; // negative = money out
  final String source;
  final String category;

  String get merchant => merchantLabel(description, detail, source);

  /// The key a category rule is saved under for this merchant.
  String get ruleKey {
    final key = merchantKey(merchant);
    return key.isNotEmpty ? key : merchantKey(description);
  }

  String get month => date.substring(0, 7);
}

Future<List<Txn>> loadTransactions(AppDatabase db) async {
  final own = {
    for (final a in await db.all('accounts')) a['number'] as String,
  };
  final rules = {
    for (final r in await db.all('category_rules'))
      r['key'] as String: r['category'] as String,
  };
  return [
    for (final r in await db.all('transactions'))
      Txn(
        id: r['_id'] as int,
        date: r['date'] as String,
        account: r['account'] as String,
        description: r['description'] as String,
        detail: (r['detail'] as String?) ?? '',
        amount: (r['amount'] as num).toDouble(),
        source: r['source'] as String,
        category: categorize(
          source: r['source'] as String,
          amount: (r['amount'] as num).toDouble(),
          description: r['description'] as String,
          detail: (r['detail'] as String?) ?? '',
          ownAccountNumbers: own,
          userRules: rules,
        ),
      ),
  ];
}

/// Remembers that this merchant belongs to [category], for all its
/// transactions, past and future.
Future<void> saveCategoryRule(AppDatabase db, Txn txn, String category) =>
    db.upsert('category_rules', 'key', {'key': txn.ruleKey, 'category': category});

class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.spending,
    required this.byCategory,
  });

  final double income;

  /// Spending, with refunds taken off.
  final double spending;

  /// Spending per category, largest first. Only categories counted as
  /// spending.
  final List<MapEntry<String, double>> byCategory;

  double get net => income - spending;
}

/// Months (yyyy-MM) that have transactions, newest first.
List<String> monthsWithData(List<Txn> txns) =>
    (txns.map((t) => t.month).toSet().toList()..sort()).reversed.toList();

MonthSummary summarize(List<Txn> txns, String month) {
  var income = 0.0;
  final byCategory = <String, double>{};
  for (final t in txns.where((t) => t.month == month)) {
    if (t.category == 'Income') {
      income += t.amount;
    } else if (!nonSpendingCategories.contains(t.category)) {
      byCategory.update(t.category, (v) => v - t.amount,
          ifAbsent: () => -t.amount);
    }
  }
  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return MonthSummary(
    income: income,
    spending: entries.fold(0.0, (sum, e) => sum + e.value),
    byCategory: entries,
  );
}
