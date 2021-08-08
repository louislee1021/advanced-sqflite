import 'package:flutter/foundation.dart';
import 'package:tekartik_app_flutter_sqflite/sqflite.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_notepad_sqflite_app/db/db_config.dart';
import 'package:tekartik_notepad_sqflite_app/db/db_provider.dart';
import 'package:tekartik_notepad_sqflite_app/model/note.dart';
import 'package:tekartik_notepad_sqflite_app/model/model_constant.dart';

DbNote snapshotToNote(Map<String, Object?> snapshot) {
  return DbNote()..fromMap(snapshot);
}

class DbNotes extends ListBase<DbNote> {
  final List<Map<String, Object?>> list;
  late List<DbNote?> _cacheNotes;

  DbNotes(this.list) {
    _cacheNotes = List.generate(list.length, (index) => null);
  }

  @override
  DbNote operator [](int index) {
    return _cacheNotes[index] ??= snapshotToNote(list[index]);
  }

  @override
  int get length => list.length;

  @override
  void operator []=(int index, DbNote? value) => throw 'read-only';

  @override
  set length(int newLength) => throw 'read-only';
}

class DbNoteProvider extends DbProvider {
  DbNoteProvider(DatabaseFactory dbFactory, DbConfig dbConfig)
      : super(dbFactory, dbConfig);

  @override
  Future initialDBInsert(Database db) async {
    await saveDBRecord(
        db,
        DbNote()
          ..title.v = 'Simple title'
          ..content.v = 'Simple content'
          ..date.v = 1);
    await saveDBRecord(
        db,
        DbNote()
          ..title.v = 'Welcome to NotePad'
          ..content.v =
              'Enter your notes\n\nThis is a content. Just tap anywhere to edit the note.\n'
                  '${kIsWeb ? '\nYou can open multiple tabs or windows and see that the content is the same in all tabs' : ''}'
          ..date.v = 2);
  }
}
