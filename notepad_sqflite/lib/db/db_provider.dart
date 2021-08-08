import 'package:flutter/foundation.dart';
import 'package:tekartik_app_flutter_sqflite/sqflite.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_notepad_sqflite_app/db/db_config.dart';
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

abstract class DbProvider {
  final lock = Lock(reentrant: true);
  final DatabaseFactory dbFactory;
  final DbConfig dbConfig;
  final _updateTriggerController = StreamController<bool>.broadcast();
  Database? db;

  DbProvider(this.dbFactory, this.dbConfig);

  Future openPath(String path) async {
    db = await dbFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: kVersion1,
            onCreate: (db, version) async {
              await _createDb(db);
            },
            onUpgrade: (db, oldVersion, newVersion) async {
              if (oldVersion < kVersion1) {
                await _createDb(db);
              }
            }));
  }

  void _triggerUpdate() {
    _updateTriggerController.sink.add(true);
  }

  Future<Database?> get ready async => db ??= await lock.synchronized(() async {
        if (db == null) {
          await open();
        }
        return db;
      });

  Future<DbNote?> getNote(int? id) async {
    var list = (await db!.query(tableNotes,
        columns: [columnId, columnTitle, columnContent, columnUpdated],
        where: '$columnId = ?',
        whereArgs: <Object?>[id]));
    if (list.isNotEmpty) {
      return DbNote()..fromMap(list.first);
    }
    return null;
  }

  Future _createDb(Database db) async {
    await db.execute(dbConfig.dropSQL);
    await db.execute(dbConfig.createSQL);
    await db.execute(dbConfig.createIndexSQL);
    await initialDBInsert(db);
    _triggerUpdate();
  }

  Future initialDBInsert(Database db);

  Future open() async {
    await openPath(await fixPath(dbConfig.database));
  }

  Future<String> fixPath(String path) async => path;

  /// Add or update a note
  Future saveDBRecord(DatabaseExecutor? db, DbNote updatedNote) async {
    if (updatedNote.id.v != null) {
      await db!.update(tableNotes, updatedNote.toMap(),
          where: '$columnId = ?', whereArgs: <Object?>[updatedNote.id.v]);
    } else {
      updatedNote.id.v = await db!.insert(tableNotes, updatedNote.toMap());
    }
  }

  Future saveNote(DbNote updatedNote) async {
    await saveDBRecord(db, updatedNote);
    _triggerUpdate();
  }

  Future<void> deleteNote(int? id) async {
    await db!
        .delete(tableNotes, where: '$columnId = ?', whereArgs: <Object?>[id]);
    _triggerUpdate();
  }

  var notesTransformer =
      StreamTransformer<List<Map<String, Object?>>, List<DbNote>>.fromHandlers(
          handleData: (snapshotList, sink) {
    sink.add(DbNotes(snapshotList));
  });

  var noteTransformer =
      StreamTransformer<Map<String, Object?>, DbNote?>.fromHandlers(
          handleData: (snapshot, sink) {
    sink.add(snapshotToNote(snapshot));
  });

  /// Listen for changes on any note
  Stream<List<DbNote?>> onNotes() {
    late StreamController<DbNotes> ctlr;
    StreamSubscription? _triggerSubscription;

    Future<void> sendUpdate() async {
      var notes = await getListNotes();
      if (!ctlr.isClosed) {
        ctlr.add(notes);
      }
    }

    ctlr = StreamController<DbNotes>(onListen: () {
      sendUpdate();

      /// Listen for trigger
      _triggerSubscription = _updateTriggerController.stream.listen((_) {
        sendUpdate();
      });
    }, onCancel: () {
      _triggerSubscription?.cancel();
    });
    return ctlr.stream;
  }

  /// Listed for changes on a given note
  Stream<DbNote?> onNote(int? id) {
    late StreamController<DbNote?> ctlr;
    StreamSubscription? _triggerSubscription;

    Future<void> sendUpdate() async {
      var note = await getNote(id);
      if (!ctlr.isClosed) {
        ctlr.add(note);
      }
    }

    ctlr = StreamController<DbNote?>(onListen: () {
      sendUpdate();

      /// Listen for trigger
      _triggerSubscription = _updateTriggerController.stream.listen((_) {
        sendUpdate();
      });
    }, onCancel: () {
      _triggerSubscription?.cancel();
    });
    return ctlr.stream;
  }

  /// Don't read all fields
  Future<DbNotes> getListNotes(
      {int? offset, int? limit, bool? descending}) async {
    // devPrint('fetching $offset $limit');
    var list = (await db!.query(tableNotes,
        columns: [columnId, columnTitle, columnContent],
        orderBy: '$columnUpdated ${(descending ?? false) ? 'ASC' : 'DESC'}',
        limit: limit,
        offset: offset));
    return DbNotes(list);
  }

  Future clearAllNotes() async {
    await db!.delete(tableNotes);
    _triggerUpdate();
  }

  Future close() async {
    await db!.close();
  }

  Future deleteDb() async {
    await dbFactory.deleteDatabase(await fixPath(dbName));
  }
}
