import 'bank_statement.dart';
import 'card_statement.dart';
import 'models.dart';
import 'pdf_text.dart';

StatementKind detectStatement(PdfPages pages) {
  final text = [
    for (final page in pages.take(2)) ...page.map(lineText),
  ].join('\n').toUpperCase();
  if (text.contains('INTERACTIVE BROKERS') && text.contains('ACTIVITY STATEMENT')) {
    return StatementKind.ibkr;
  }
  if (text.contains('CONSOLIDATED STATEMENT') && text.contains('ACCOUNT SUMMARY')) {
    return StatementKind.bank;
  }
  if (text.contains('STATEMENT OF ACCOUNT') && text.contains('STATEMENT DATE')) {
    return StatementKind.card;
  }
  return StatementKind.unknown;
}

/// Detects the statement type and parses it. Returns null for unsupported
/// files (and for IBKR, which isn't supported yet).
ParsedStatement? parseStatement(PdfPages pages) {
  switch (detectStatement(pages)) {
    case StatementKind.bank:
      return parseBankStatement(pages);
    case StatementKind.card:
      return parseCardStatement(pages);
    case StatementKind.ibkr:
    case StatementKind.unknown:
      return null;
  }
}
