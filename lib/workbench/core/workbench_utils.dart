import 'dart:math';

final Random _secureRandom = Random.secure();

String newWorkbenchId() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final value = bytes.map(hex).join();
  return '${value.substring(0, 8)}-'
      '${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-'
      '${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

String utcNowIso() => DateTime.now().toUtc().toIso8601String();

DateTime parseUtc(String value) => DateTime.parse(value).toUtc();

DateTime? parseNullableUtc(Object? value) {
  final raw = value as String?;
  return raw == null ? null : DateTime.parse(raw).toUtc();
}

String slugifyWorkspace(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'workspace-${DateTime.now().millisecondsSinceEpoch}' : normalized;
}

String markdownFileName(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final stem = normalized.isEmpty ? 'note-${DateTime.now().millisecondsSinceEpoch}' : normalized;
  return '$stem.md';
}
