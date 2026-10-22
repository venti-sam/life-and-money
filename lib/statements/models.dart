enum StatementKind { bank, card, ibkr, unknown }

/// One transaction read from a statement. [amount] is negative for money out.
class StatementTransaction {
  const StatementTransaction({
    required this.date,
    required this.account,
    required this.description,
    required this.amount,
    required this.source,
    this.detail = '',
    this.balance,
  });

  final String date; // yyyy-MM-dd
  final String account;
  final String description;
  final String detail; // extra lines, joined with " | "
  final double amount;
  final String source; // 'bank' or 'card'
  final double? balance; // running balance after this row (bank only)
}

class StatementBalance {
  const StatementBalance({
    required this.name,
    required this.number,
    required this.amount,
    required this.asOf,
  });

  final String name;
  final String number;
  final double amount;
  final String asOf; // yyyy-MM-dd
}

class ParsedStatement {
  const ParsedStatement({
    required this.kind,
    required this.label,
    required this.asOf,
    this.balances = const [],
    this.transactions = const [],
    this.accountNumbers = const {},
    this.warnings = const [],
  });

  final StatementKind kind;
  final String label;
  final String asOf; // yyyy-MM-dd, or '' if unknown
  final List<StatementBalance> balances;
  final List<StatementTransaction> transactions;

  /// Numbers of the user's own accounts (used to spot transfers).
  final Set<String> accountNumbers;

  /// Things that didn't add up; shown to the user before they save.
  final List<String> warnings;
}

/// Accounts that are never imported (their transactions and balances).
const ignoredAccountNames = ['DBS Savings Plus'];

bool isIgnoredAccount(String name) => ignoredAccountNames
    .any((ignored) => name.toLowerCase().startsWith(ignored.toLowerCase()));
