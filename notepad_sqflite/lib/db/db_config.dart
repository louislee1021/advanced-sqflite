abstract class DbConfig {
  String get database;
  int get kVersion1;
  String get table;

  String get dropSQL;
  String get createSQL;
  String get createIndexSQL;
}
