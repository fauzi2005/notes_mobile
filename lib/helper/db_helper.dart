import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../model/note_model.dart';

class DBHelper {
  DBHelper._();
  static final DBHelper db = DBHelper._();
  static Database? _database;

  static const SECRET_KEY = "2021_PRIVATE_KEY_ENCRYPT_2021";
  static const DATABASE_VERSION = 1;
  static const DB_NAME = "db_notes.db";
  static const TABLE_NAME = "notes";

  List<String> tables =[

  ];

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  static Future<Database> openOpen() async {
    final database = await openDatabase(
        join(await getDatabasesPath(), DB_NAME),
    );
    return database;
  }

  static initDB() async {
    String path = join(await getDatabasesPath(), DB_NAME);
    return await openDatabase(path, version: DATABASE_VERSION, onOpen: (db) {},
        onCreate: (Database db, int version) async {
          await db.execute("CREATE TABLE $TABLE_NAME ("
              "notes_id INTEGER PRIMARY KEY,"
              "notes_title TEXT,"
              "notes_body TEXT,"
              "created_at TEXT,"
              "updated_at TEXT"
              ")");
        });
  }

  addNewNote(NoteModel note) async {
    final db = await database;
    db.insert(TABLE_NAME, note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(TABLE_NAME);
    return List.generate(maps.length, (i) {
      return NoteModel(
        notesId: maps[i]['notes_id'],
        notesTitle: maps[i]['notes_title'],
        notesBody: maps[i]['notes_body'],
        createdAt: maps[i]['created_at'],
        updatedAt: maps[i]['updated_at'],
      );
    });
  }

  Future<int> deleteNote(int notesId) async {
    final db = await database;
    return db.delete(TABLE_NAME, where: 'notes_id = ?', whereArgs: [notesId]);
  }

  Future<int> updateNote(NoteModel note) async {
    final db = await database;
    return db.update(TABLE_NAME, note.toMap(),
        where: "notes_id = ?", whereArgs: [note.notesId]);
  }

  Future<int> deleteAllNotes() async {
    final db = await database;
    return db.delete(TABLE_NAME);
  }

  static Future<dynamic> exportDb() async {
    final database = await openDatabase(
      join(await getDatabasesPath(), DB_NAME),
      version: DATABASE_VERSION,
    );
    final rows = await database.query(TABLE_NAME);

    await Permission.manageExternalStorage.request();
    Directory directory = Directory("storage/emulated/0/backup-notes");
    if ((await directory.exists())) {
      print("Path exist");
      var status = await Permission.storage.status;

      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final people = rows.map((row) => NoteModel.fromMap(row)).toList();
      // await database.close();

      final peopleJson = jsonEncode(
          people.map((person) => person.toMap()).toList());
      final backupFile = File(join(directory.path, 'my_db_backup.json'));
      await backupFile.writeAsString(peopleJson);

      print('FILE BACKUP $backupFile');
    } else {
      print("not exist");
      if (await Permission.storage
          .request()
          .isGranted || await Permission.manageExternalStorage
          .request()
          .isGranted) {
        // Either the permission was already granted before or the user just granted it.
        await directory.create();
      } else {
        print('Please give permission');
      }
    }
  }

  static Future<dynamic> importDb() async {
    const status = Permission.manageExternalStorage;
    await status.request();
    await Permission.storage.request();

    Directory directory = Directory("storage/emulated/0/backup-notes");
    if(await status.isGranted) {
      if (await directory.exists()) {
        print("Path exist");
        var status = await Permission.storage.status;

        if (!status.isGranted) {
          await Permission.storage.request();
        }

        FilePickerResult? get = await FilePicker.platform.pickFiles(initialDirectory: directory.path);
        final backupFile = File(join(get!.files.single.path!));
        final content = await backupFile.readAsString();
        final notes = (jsonDecode(content) as List<dynamic>)
            .map((person) => NoteModel.fromMap(person as Map<String, dynamic>))
            .toList();
        final database = await openDatabase(
          join(await getDatabasesPath(), DB_NAME),
          version: DATABASE_VERSION,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE IF NOT EXISTS $TABLE_NAME (note_id INTEGER PRIMARY KEY, notes_title TEXT, notes_title TEXT, created_at TEXT, updated_at TEXT)',
            );
          },
        );

        try {
          await database.transaction((txn) async {
            for (final note in notes) {
              await txn.insert(TABLE_NAME, note.toMap());
            }
          });
          return 'success';
        } catch(e) {
          return 'failed';
        }
      } else {
        print("not exist");
        if (await Permission.storage.request().isGranted) {
          // Either the permission was already granted before or the user just granted it.
          await directory.create();
        } else {
          print('Please give permission');
        }
      }
    } else {
      print('permission denied');
    }

  }

}