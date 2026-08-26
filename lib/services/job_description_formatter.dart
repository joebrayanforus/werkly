/// Converts partner-provided HTML job descriptions into readable plain text.
///
/// Job feeds do not consistently declare whether `description` contains HTML.
/// Keeping the conversion at the data boundary prevents raw tags from leaking
/// into the offer sheet, AI context, compatibility scoring and moderation UI.
String formatJobDescription(String source) {
  if (source.trim().isEmpty) return '';

  var value = source
      .replaceAll(
        RegExp(r'<script\b[^>]*>[\s\S]*?</script>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<\s*li\b[^>]*>', caseSensitive: false), '\n• ')
      .replaceAll(
        RegExp(
          r'<\s*/\s*(?:p|div|li|h[1-6]|section|article|tr|ul|ol)\s*>',
          caseSensitive: false,
        ),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]*>'), '');

  value = _decodeHtmlEntities(value)
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n[ \t]+'), '\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'\n{2,}(?=• )'), '\n');

  return value.trim();
}

/// Normalizes a short value supplied by a partner feed, such as a title,
/// company, location or skill, while keeping it on one line.
String formatExternalText(String source) =>
    formatJobDescription(source).replaceAll(RegExp(r'\s+'), ' ').trim();

String _decodeHtmlEntities(String source) {
  const named = <String, String>{
    'nbsp': ' ',
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    '#39': "'",
    'ndash': '–',
    'mdash': '—',
    'hellip': '…',
    'bull': '•',
    'middot': '·',
    'laquo': '«',
    'raquo': '»',
    'auml': 'ä',
    'ouml': 'ö',
    'uuml': 'ü',
    'Auml': 'Ä',
    'Ouml': 'Ö',
    'Uuml': 'Ü',
    'szlig': 'ß',
    'eacute': 'é',
    'Eacute': 'É',
  };

  return source.replaceAllMapped(
    RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]+);'),
    (match) {
      final entity = match.group(1)!;
      final replacement = named[entity];
      if (replacement != null) return replacement;

      if (entity.startsWith('#x') || entity.startsWith('#X')) {
        final codePoint = int.tryParse(entity.substring(2), radix: 16);
        if (codePoint != null && _validCodePoint(codePoint)) {
          return String.fromCharCode(codePoint);
        }
      } else if (entity.startsWith('#')) {
        final codePoint = int.tryParse(entity.substring(1));
        if (codePoint != null && _validCodePoint(codePoint)) {
          return String.fromCharCode(codePoint);
        }
      }
      return match.group(0)!;
    },
  );
}

bool _validCodePoint(int value) =>
    value > 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff);
