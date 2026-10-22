import 'dart:js_interop';
import 'dart:typed_data';

// Defined in web/pdf_text.js.
@JS('extractPdfLines')
external JSPromise<JSString> _extractPdfLines(JSUint8Array bytes);

Future<String> extractPdfJson(Uint8List bytes) async =>
    (await _extractPdfLines(bytes.toJS).toDart).toDart;
