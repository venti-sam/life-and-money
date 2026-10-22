import 'models.dart';
import 'parse_utils.dart';
import 'pdf_text.dart';

final _cardDateRe = RegExp(r'^(\d{2}) ([A-Z]{3})$');
final _creditRe = RegExp(r'^([\d,]+\.\d{2}) CR$');

/// Parses a DBS credit card statement: one transaction per purchase (money
/// out, negative) or payment/refund ("CR", positive).
ParsedStatement parseCardStatement(PdfPages pages) {
  final rows = [for (final page in pages) ...page];
  final warnings = <String>[];
  final transactions = <StatementTransaction>[];

  // "STATEMENT DATE" heading, then the date on the next row.
  String asOf = '';
  for (var i = 0; i < rows.length - 1; i++) {
    if (rows[i].isNotEmpty && rows[i].first.text == 'STATEMENT DATE') {
      asOf = parseLongDate(rows[i + 1].first.text) ?? '';
      break;
    }
  }
  final statementYear = asOf.isEmpty ? DateTime.now().year : int.parse(asOf.substring(0, 4));
  final statementMonth = asOf.isEmpty ? 12 : int.parse(asOf.substring(5, 7));

  String account = 'Credit card';
  int descriptionX = 0;
  var chargesTotal = 0.0;
  double? printedSubtotal;
  var open = false;
  var openIndex = -1;

  for (final row in rows) {
    if (row.isEmpty) continue;
    final first = row.first.text;
    final text = lineText(row);

    final card = RegExp(r'^(.*?)\s*CARD NO\.:?\s*([\d ]+)$').firstMatch(text);
    if (card != null && row.length == 1) {
      final digits = card.group(2)!.replaceAll(' ', '');
      final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
      final name = card.group(1)!.trim();
      account = '$name …$last4';
      open = false;
      continue;
    }

    if (first.startsWith('SUB-TOTAL')) {
      printedSubtotal = parseAmount(row.last.text);
      open = false;
      continue;
    }

    final dateMatch = _cardDateRe.firstMatch(first);
    if (dateMatch != null && row.length >= 3) {
      final amountText = row.last.text;
      final credit = _creditRe.firstMatch(amountText);
      final value = credit != null
          ? parseAmount(credit.group(1)!)
          : parseAmount(amountText);
      if (value == null) {
        open = false;
        continue;
      }
      final month = monthNumber(dateMatch.group(2)!);
      if (month == null) continue;
      // A December purchase on a January statement belongs to last year.
      final year = month > statementMonth ? statementYear - 1 : statementYear;
      final amount = credit != null ? value : -value;
      if (credit == null) chargesTotal += value;
      descriptionX = row[1].x;
      transactions.add(StatementTransaction(
        date: isoDate(year, month, int.parse(dateMatch.group(1)!)),
        account: account,
        description: row[1].text,
        amount: amount,
        source: 'card',
      ));
      open = true;
      openIndex = transactions.length - 1;
      continue;
    }

    // Foreign-currency or reference line under a transaction.
    if (open && row.length == 1 && (row.first.x - descriptionX).abs() <= 3) {
      final t = transactions[openIndex];
      transactions[openIndex] = StatementTransaction(
        date: t.date,
        account: t.account,
        description: t.description,
        detail: t.detail.isEmpty ? first : '${t.detail} | $first',
        amount: t.amount,
        source: t.source,
      );
      continue;
    }
    open = false;
  }

  if (printedSubtotal != null && (round2(chargesTotal) - printedSubtotal).abs() > 0.005) {
    warnings.add('Purchases add up to ${round2(chargesTotal)} but the '
        'statement says $printedSubtotal.');
  }
  if (transactions.isEmpty) warnings.add('No transactions found.');

  return ParsedStatement(
    kind: StatementKind.card,
    label: 'Credit card statement',
    asOf: asOf,
    transactions: transactions,
    warnings: warnings,
  );
}
