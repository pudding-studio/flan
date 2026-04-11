// Conditional export: native uses io stub (no-op), web overrides databaseFactory.
export 'database_factory_init_io.dart'
    if (dart.library.html) 'database_factory_init_web.dart';
