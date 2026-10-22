import 'dart:convert';
import 'dart:typed_data';

import 'pdf_reader_stub.dart'
    if (dart.library.js_interop) 'pdf_reader_web.dart' as impl;

/// A piece of text in one column of a PDF table row. [x] is its left edge.
class PdfCell {
  const PdfCell(this.x, this.text);
  final int x;
  final String text;
}

/// One visual row of text on a PDF page, left to right.
typedef PdfLine = List<PdfCell>;

/// pages > lines > cells.
typedef PdfPages = List<List<PdfLine>>;

/// Reads the text of a PDF, in the browser. Nothing is uploaded.
Future<PdfPages> readPdf(Uint8List bytes) async =>
    pdfPagesFromJson(await impl.extractPdfJson(bytes));

PdfPages pdfPagesFromJson(String json) => [
      for (final page in jsonDecode(json) as List)
        [
          for (final line in page as List)
            [
              for (final cell in line as List)
                PdfCell((cell['x'] as num).toInt(), cell['t'] as String),
            ],
        ],
    ];

String lineText(PdfLine line) => line.map((c) => c.text).join(' ');
