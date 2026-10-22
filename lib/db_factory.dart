import 'package:sembast/sembast.dart';

import 'db_factory_stub.dart'
    if (dart.library.js_interop) 'db_factory_web.dart' as impl;

/// The database factory for the current platform: IndexedDB in the browser.
DatabaseFactory get platformDatabaseFactory => impl.platformDatabaseFactory;
