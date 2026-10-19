import 'dart:typed_data';

/// Whether [bytes] look like a complete PNG or WebP file. Other formats are
/// not checked here; decoding decides. Returns null when complete, else why not.
String? incompleteReason(Uint8List bytes) {
  if (_startsWith(bytes, _pngSignature)) return _pngProblem(bytes);
  if (bytes.length >= 12 && _ascii(bytes, 0, 4) == 'RIFF' && _ascii(bytes, 8, 4) == 'WEBP') {
    return _webpProblem(bytes);
  }
  return null;
}

const _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// Whether [bytes] start like a PNG file.
bool isPng(Uint8List bytes) => _startsWith(bytes, _pngSignature);

bool _startsWith(Uint8List b, List<int> prefix) {
  if (b.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (b[i] != prefix[i]) return false;
  }
  return true;
}

String _ascii(Uint8List b, int at, int n) => String.fromCharCodes(b.sublist(at, at + n));

String? _pngProblem(Uint8List b) {
  final data = ByteData.sublistView(b);
  if (b.length < 8 + 12 || _ascii(b, 12, 4) != 'IHDR') return 'PNG header is not complete';
  // Walk the chunks; the file is complete when the last one is a valid IEND.
  var at = 8;
  while (at + 12 <= b.length) {
    final length = data.getUint32(at);
    final end = at + 12 + length;
    if (end > b.length) return 'PNG is cut off';
    final type = _ascii(b, at + 4, 4);
    if (type == 'IEND') {
      if (end != b.length) return 'PNG has extra data after the end';
      return _crc32(b, at + 4, 4 + length) == data.getUint32(end - 4) ? null : 'PNG end chunk is damaged';
    }
    at = end;
  }
  return 'PNG has no end chunk yet';
}

String? _webpProblem(Uint8List b) {
  final size = ByteData.sublistView(b).getUint32(4, Endian.little);
  return size + 8 == b.length ? null : 'WebP size does not match the file';
}

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(Uint8List b, int start, int length) {
  var c = 0xFFFFFFFF;
  for (var i = start; i < start + length; i++) {
    c = _crcTable[(c ^ b[i]) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
