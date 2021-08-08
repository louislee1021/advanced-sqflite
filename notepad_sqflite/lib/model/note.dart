import 'package:tekartik_notepad_sqflite_app/db/db.dart';
import 'package:tekartik_notepad_sqflite_app/db/db_config.dart';

class DbNote extends DbRecord {
  final title = stringField(DbNoteConfig.instance.columnTitle);
  final content = stringField(DbNoteConfig.instance.columnContent);
  final date = intField(DbNoteConfig.instance.columnUpdated);

  @override
  List<Field> get fields => [id, title, content, date];
}

class DbNoteConfig implements DbConfig {
  String columnTitle = 'title';
  String columnId = '_id';
  String columnContent = 'content';
  String columnUpdated = 'updated';

  // Singleton
  static DbNoteConfig? _instance;
  static DbNoteConfig get instance => _instance ??= DbNoteConfig();
  // /Singleton

  @override
  String get table => 'Notes';

  @override
  String get createIndexSQL => 'CREATE INDEX NotesUpdated ON $table ($columnUpdated)';

  @override
  String get createSQL =>
      'CREATE TABLE $table($columnId INTEGER PRIMARY KEY, $columnTitle TEXT, $columnContent TEXT, $columnUpdated INTEGER)';

  @override
  String get database => 'note.db';

  @override
  String get dropSQL => 'DROP TABLE If EXISTS $table';

  @override
  int get kVersion1 => 1;
}
