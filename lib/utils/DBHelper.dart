///  @author caoqian
/// @since 2024-04-30 13:15
/// @Description: 操作SQLlite的工具类

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final Logger _logger = Logger('DBHelper');

  late Database? _db;

// 初始化数据库，接受表名作为参数
  Future<Database> initDb(String tableName, int version, List<String> columns, List<String> columnProperties) async {
    final dir = await getDatabasesPath();
    final path = join(dir, "my_database.db");
    _logger.fine('The storage path for Table $tableName is $path');
    _db = await openDatabase(path, version: version, onCreate: (Database db, int version) async {
      // 使用传入的表名、字段列表和字段属性列表来创建表
      await _onCreate(db, version, tableName, columns, columnProperties);
    });

    // 检查表是否存在，如果不存在则创建
    await _checkAndCreateTable(tableName, columns, columnProperties);

    return _db!;
  }

  Future _onCreate(Database db, int version, String tableName, List<String> columns, List<String> columnProperties) async {
    // 构建 CREATE TABLE 语句
    var createTableStatement = "CREATE TABLE IF NOT EXISTS $tableName ($columns)";

    // 将字段列表和字段属性列表合并为实际的列定义
    List<String> columnDefinitions = [];
    for (int i = 0; i < columns.length; i++) {
      String column = columns[i];
      String property = columnProperties[i];
      columnDefinitions.add("$column $property");
    }

    // 替换占位符为实际的列定义
    createTableStatement = createTableStatement.replaceAll('$columns', columnDefinitions.join(', '));

    // 执行 SQL 语句
    await db.execute(createTableStatement);
  }

  Future<void> _checkAndCreateTable(String tableName, List<String> columns, List<String> columnProperties) async {
    if (_db == null) {
      throw Exception("Database is not initialized");
    }

    // 检查表是否存在
    var result = await _db!.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName';");

    if (result.isEmpty) {
      // 表不存在，创建表
      await _onCreate(_db!, 1, tableName, columns, columnProperties);
    } else {
      _logger.fine('Table $tableName already exists.');
    }
  }

  // 插入数据
  Future<void> insert(String tableName, Map<String, dynamic> row) async {
    final columns = row.keys.join(', ');
    final placeholders = row.keys.map((_) => '?').join(', ');
    final sql = "INSERT INTO $tableName ($columns) VALUES ($placeholders)";
    final values = row.values.toList();
    await _db!.execute(sql, values);
  }

  Future<void> insertOrUpdate(
      String tableName, Map<String, dynamic> row) async {
    // 构建更新语句的列和值
    final updateColumns = row.keys.map((key) => "$key = ?").join(', ');
    final updateSql = "UPDATE $tableName SET $updateColumns WHERE 1=1";

    // 将 row 转换为一个 Map，其中包含更新所需的键值对
    final updateValues =
        Map.fromEntries(row.entries.map((e) => MapEntry(e.key, e.value)));

    // 尝试更新行
    int updatedRows = await _db!.update(updateSql, updateValues);

    if (updatedRows == 0) {
      // 如果没有行被更新，执行插入操作
      final columns = row.keys.join(', ');
      final placeholders = row.keys.map((_) => '?').join(', ');
      final insertSql =
          "INSERT INTO $tableName ($columns) VALUES ($placeholders)";

      // 执行插入操作
      await _db!.execute(insertSql, row.values.toList());
    }
  }

  // 查询所有数据
  Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    return await _db!.query(tableName);
  }

//根据字段排序获取前n个元素
  Future<List<Map<String, dynamic>>> getTopByColum(
      String tableName, String dateColumn, int count, bool ascending) async {
    List<Map<String, dynamic>> allRows = await getAll(tableName);
    // allRows 这是 SQLite 查询的结果类型，而不是 Dart 中的 List 类型。这就是为什么你无法直接对其进行排序的原因。
    // 因此，你需要将 QueryResultSet 转换为 Dart 中的可变列表类型，例如 List<Map<String, dynamic>>，然后再进行排序和其他操作。
    List<Map<String, dynamic>> mutableRows = List.from(allRows);
    mutableRows.sort((a, b) => ascending
        ? a[dateColumn].compareTo(b[dateColumn])
        : b[dateColumn].compareTo(a[dateColumn])); // 根据 ascending 参数决定排序顺序
    return mutableRows.take(count).toList(); // 获取前 count 个元素
  }

  // 根据某个字段查询数据
  Future<List<Map<String, dynamic>>> getByField(
      String tableName, String fieldName, dynamic value) async {
    return await _db!
        .query(tableName, where: '$fieldName = ?', whereArgs: [value]);
  }

  // 根据多个字段查询数据
  Future<List<Map<String, dynamic>>> getByMultipleFields(
      String tableName, Map<String, dynamic> conditions) async {
    // 构建查询条件
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    conditions.forEach((fieldName, value) {
      whereClauses.add('$fieldName = ?');
      whereArgs.add(value);
    });

    // 使用逻辑运算符AND连接多个条件
    String whereClause = whereClauses.join(' AND ');

    return await _db!
        .query(tableName, where: whereClause, whereArgs: whereArgs);
  }

  // 根据ID查询数据
  Future<Map<String, dynamic>?> getById(String tableName, int id) async {
    final List<Map<String, dynamic>> users =
        await _db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    return users.isNotEmpty ? users.first : null;
  }

  // 更新数据
  // Future<int> update(String tableName, Map<String, dynamic> row,
  //     {String? where, List<dynamic>? whereArgs}) async {
  //   final setClause = row.entries.map((e) => "${e.key} = ?").join(', ');
  //   final updateValues = row.values.toList();
  //   String sql = "UPDATE $tableName SET ($setClause)";
  //   if (where != null && whereArgs != null) {
  //     sql += " WHERE $where";
  //     updateValues.addAll(whereArgs);
  //   }
  //   return await _db!
  //       .update(tableName, row, where: where, whereArgs: whereArgs);
  // }

  //根据某个字段更新数据
  Future<int> update(String tableName, Map<String, dynamic> row,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _db!
        .update(tableName, row, where: where, whereArgs: whereArgs);
  }

  // 删除数据
  Future<int> delete(String tableName,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _db!.delete(tableName, where: where, whereArgs: whereArgs);
  }

  // 关闭数据库连接
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
