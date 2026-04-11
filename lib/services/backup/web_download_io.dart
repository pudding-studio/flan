import 'dart:typed_data';

// Native stub: backups on native go through the existing file/MethodChannel
// flow in backup_screen.dart, so this is never invoked. Provided only so the
// import in backup_screen.dart compiles on every platform.
Future<void> downloadBytesAsFile(Uint8List bytes, String fileName) async {
  throw UnsupportedError('downloadBytesAsFile is web-only');
}
