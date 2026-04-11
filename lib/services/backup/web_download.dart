// Conditional export: native gets a no-op stub, web gets a real Blob downloader.
export 'web_download_io.dart' if (dart.library.html) 'web_download_web.dart';
