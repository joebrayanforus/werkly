import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Opens Android/iOS/Desktop's system save/share surface with the verified
/// bytes. The user can save the exact PDF in Downloads or send it by email.
Future<void> downloadPdf(Uint8List bytes, String filename) async {
  final completed = await Printing.sharePdf(bytes: bytes, filename: filename);
  if (!completed) {
    throw StateError('The PDF export was cancelled or could not be started.');
  }
}
