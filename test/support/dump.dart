import 'package:life_and_money/statements/pdf_text.dart';

/// Builds PDF pages from a compact text form, one row per line, cells
/// separated by " | " and written as "[x]text". Pages split on "--- page".
PdfPages pagesFromDump(String dump) {
  final pages = <List<PdfLine>>[];
  for (final raw in dump.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('--- page')) {
      pages.add([]);
      continue;
    }
    pages.last.add([
      for (final cell in line.split(' | '))
        PdfCell(
          int.parse(RegExp(r'^\[(\d+)\]').firstMatch(cell)!.group(1)!),
          cell.replaceFirst(RegExp(r'^\[\d+\]'), ''),
        ),
    ]);
  }
  return pages;
}
