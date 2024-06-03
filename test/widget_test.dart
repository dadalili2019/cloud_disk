import 'package:cloud_disk/dto/home/weather.dart';
import 'package:cloud_disk/utils/DBHelper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // 初始化 sqflite_common_ffi
  sqfliteFfiInit();
  // 设置 databaseFactoryFfi 作为默认的 databaseFactory
  databaseFactory = databaseFactoryFfi;

  // 数据库配置
  const tableName = 'weather';
  const columns = ['location', 'temp', 'text', 'humidity', 'date'];
  const columnProperties = ['TEXT', 'TEXT', 'TEXT', 'TEXT', 'TEXT'];

  // 创建 DBHelper 实例
  final dbHelper = DBHelper();

  // 初始化数据库和表
  final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

  // 获取当前日期和时间
  DateTime now = DateTime.now();

  // 创建一个 DateFormat 对象来指定日期格式
  DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  // 使用 DateFormat 对象来格式化日期
  String desiredDateValue = dateFormat.format(now);

  Map<String, dynamic> conditions = {
    'location': '101200304',
    'date': desiredDateValue,
  };

  List<Map<String, dynamic>> allRows =
  await dbHelper.getByMultipleFields(tableName, conditions);

  List<Weather> weatherList = [];
  for (var map in allRows) {
    Weather weather = Weather.fromJson(map);
    weatherList.add(weather);
  }


  var length = weatherList.length;

  await db.close();
}
