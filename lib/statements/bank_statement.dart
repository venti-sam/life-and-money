import 'models.dart';
import 'parse_utils.dart';
import 'pdf_text.dart';

final _txDateRe = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
final _accountNumberRe = RegExp(r'^\d[\d-]{5,}$');

/// Parses a DBS/POSB consolidated statement: the deposit account balances and
/// the transactions of each account.
///
/// The sign of each transaction comes from the change in the running balance,
/// which is more reliable than the column it was printed in.
ParsedStatement parseBankStatement(PdfPages pages) {
  final rows = [for (final page in pages) ...page];
  final warnings = <String>[];
  final balances = <StatementBalance>[];
  final transactions = <StatementTransaction>[];
  final accountNumbers = <String>{};
  final closing = <String, double>{}; // account number -> last running balance

  String asOf = '';
  for (final row in rows) {
    final m = RegExp(r'Account Summary as at (.+)$').firstMatch(lineText(row));
    if (m != null) {
      asOf = parseLongDate(m.group(1)!) ?? '';
      break;
    }
  }

  var inSummaryDeposits = false;
  var inTransactions = false;
  var inDeposits = false; // CPF and SRS sections are skipped
  String account = '';
  String accountNumber = '';
  double? previous; // running balance before the next row
  _Pending? open; // transaction still collecting description lines

  void finish() {
    final p = open;
    if (p != null) transactions.add(p.build());
    open = null;
  }

  for (final row in rows) {
    final text = lineText(row);
    final first = row.isEmpty ? '' : row.first.text;

    if (!inTransactions) {
      if (text == 'Deposits') inSummaryDeposits = true;
      if (text.startsWith('CPF Investment Scheme') ||
          text.startsWith('Supplementary Retirement')) {
        inSummaryDeposits = false;
      }
      if (text.startsWith('Transaction Details as at')) {
        inTransactions = true;
        inSummaryDeposits = false;
        continue;
      }
      if (inSummaryDeposits &&
          row.length >= 4 &&
          _accountNumberRe.hasMatch(row[1].text) &&
          isAmount(row.last.text)) {
        accountNumbers.add(row[1].text);
        balances.add(StatementBalance(
          name: first,
          number: row[1].text,
          amount: parseAmount(row.last.text)!,
          asOf: asOf,
        ));
      }
      continue;
    }

    if (text == 'Deposits') {
      inDeposits = true;
      continue;
    }
    if (text.startsWith('CPF Investment Scheme') ||
        text.startsWith('Supplementary Retirement')) {
      finish();
      inDeposits = false;
      account = '';
      continue;
    }
    if (!inDeposits) continue;

    // Account heading: "<name>   Account No. <number>"
    if (row.length == 2 && row[1].text.startsWith('Account No.')) {
      finish();
      account = first;
      accountNumber = row[1].text.substring('Account No.'.length).trim();
      accountNumbers.add(accountNumber);
      previous = null;
      continue;
    }
    if (first == 'Date') continue;
    if (first.startsWith('Balance Brought Forward')) {
      finish();
      previous = _balance(row.last.text);
      continue;
    }
    if (first.startsWith('Balance Carried Forward') ||
        first.startsWith('Total Balance Carried')) {
      finish();
      final b = _balance(row.last.text);
      if (b != null) closing[accountNumber] = b;
      continue;
    }

    final dateMatch = _txDateRe.firstMatch(first);
    if (dateMatch != null && account.isNotEmpty) {
      finish();
      final numbers = [
        for (final c in row.skip(2))
          if (isAmount(c.text)) c,
      ];
      if (numbers.isEmpty) continue;
      final balance = parseAmount(numbers.last.text)!;
      final printed =
          numbers.length >= 2 ? parseAmount(numbers[numbers.length - 2].text) : null;

      double amount;
      if (previous != null) {
        amount = round2(balance - previous);
        if (printed != null && (amount.abs() - printed).abs() > 0.005) {
          warnings.add('$account $first: amount $printed does not match the '
              'balance change ${amount.abs()}');
          amount = amount.isNegative ? -printed : printed;
        }
      } else {
        // No opening balance to compare with: go by the column instead.
        warnings.add('$account $first: no opening balance; sign guessed');
        final isDeposit = numbers.length >= 2 && numbers[numbers.length - 2].x > 410;
        amount = isDeposit ? (printed ?? 0) : -(printed ?? 0);
      }
      previous = balance;
      open = _Pending(
        date: isoDate(int.parse(dateMatch.group(3)!),
            int.parse(dateMatch.group(2)!), int.parse(dateMatch.group(1)!)),
        account: account,
        description: row.length > 1 ? row[1].text : '',
        amount: amount,
        balance: balance,
      );
      continue;
    }

    // Further lines of the description (counterparty, reference, ...).
    if (open != null && row.length == 1) {
      open!.detail.add(first);
    }
  }
  finish();

  // Check each account's last running balance against the summary.
  for (final b in balances) {
    final last = closing[b.number];
    if (last != null && (last - b.amount).abs() > 0.005) {
      warnings.add('${b.name}: transactions end at $last but the summary says '
          '${b.amount}');
    }
  }
  if (balances.isEmpty) warnings.add('No account balances found.');

  return ParsedStatement(
    kind: StatementKind.bank,
    label: 'DBS/POSB statement',
    asOf: asOf,
    balances: balances,
    transactions: transactions,
    accountNumbers: accountNumbers,
    warnings: warnings,
  );
}

/// "5,356.08" or "SGD 16,274.56" -> number.
double? _balance(String s) =>
    parseAmount(s.replaceFirst(RegExp(r'^SGD\s*'), ''));

class _Pending {
  _Pending({
    required this.date,
    required this.account,
    required this.description,
    required this.amount,
    required this.balance,
  });

  final String date;
  final String account;
  final String description;
  final double amount;
  final double balance;
  final List<String> detail = [];

  StatementTransaction build() => StatementTransaction(
        date: date,
        account: account,
        description: description,
        detail: detail.join(' | '),
        amount: amount,
        source: 'bank',
        balance: balance,
      );
}
