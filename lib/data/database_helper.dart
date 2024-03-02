import 'dart:async';
import 'dart:io';

import 'package:bluetooth/models/schedule.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Services {
  static final Services _instance = Services.internal();
  factory Services() => _instance;
  Services.internal();

  var _db;
  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  initDb() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, 'schedule.db');
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);

    return db;
  }

  _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE Schedule(id INTEGER PRIMARY KEY, device_name TEXT, day TEXT, time TEXT, pin_no TEXT, action TEXT, is_uploaded TEXT, status TEXT, created_at TEXT, updated_at TEXT, created_by TEXT, updated_by TEXT)');
  }

//insertion
  Future<int> insertSchedule(Schedule schedule) async {
    var dbClient = await db;
    int res = await dbClient.insert(
      "Schedule",
      schedule.toMap(),
      // conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Schedule $res Added Successfully");
    return res;
  }

  dynamic getSchedule(String day, String time) async {
    var dbClient = await db;
    List<Map<String, dynamic>> res = await dbClient.query("Schedule",
        where: '"day" = ? and "time"=?', whereArgs: [day, time]);
    print(res);

    if (res.length > 0) {
      return res.first['id'];
    } else {
      return null;
    }
  }

  Future<List<Schedule>> getAllSchedule() async {
    var dbClient = await db;
    List<Schedule> Schedules = [];
    List<Map<String, dynamic>> res = await dbClient.query("Schedule");
    for (var row in res) {
      //print(row['id']);
      Schedules.add(Schedule.map(row));
    }
    print("Schedule Get Success");
    return Future<List<Schedule>>.value(Schedules);
  }

  Future<Future<int>> deleteSingleSchedule(int id) async {
    var dbClient = await db;
    Future<int> res =
        dbClient.delete("Schedule", where: '"id" = ?', whereArgs: [id]);
    print("Record deleted Successfully");
    return res;
  }

  Future<Future<int>> deleteAllSchedule() async {
    var dbClient = await db;
    Future<int> res = dbClient.delete("Schedule");
    return res;
  }

  Future<void> updateSchedule(Schedule Schedule, int id) async {
    var dbclient = await db;
    await dbclient.update(
      'Schedule',
      Schedule.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    print("Schedule Updated");
  }

  Future<void> updateAllSchedule(String deviceName) async {
    var dbclient = await db;

    // Update schedules with the given device name
    try {
      await dbclient.update(
        'Schedule',
        {'is_uploaded': "true"},
        where: 'device_name = ?', // Condition for the device name
        whereArgs: [deviceName],
      );

      print("Schedules Updated where device_name is $deviceName");
    } on Exception catch (e) {
      print("Error updating schedules: $e");
      // TODO
    }
  }
}
