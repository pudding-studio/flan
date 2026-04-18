import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Android/iOS use the default sqflite databaseFactory.
// Desktop (Windows/Linux/macOS) must route through sqflite_common_ffi.
void initDatabaseFactoryForPlatform() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
