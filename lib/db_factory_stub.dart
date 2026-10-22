import 'package:sembast/sembast_memory.dart';

// Anything that isn't the web (tests, and the Android app for now) keeps its
// data in memory only. Web is the primary target; see README.
DatabaseFactory get platformDatabaseFactory => databaseFactoryMemory;
