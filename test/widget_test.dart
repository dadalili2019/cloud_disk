import 'package:cloud_disk/utils/DBHelper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // // WidgetsFlutterBinding.ensureInitialized();
  // // 初始化 sqflite_common_ffi
  // sqfliteFfiInit();
  // // 设置 databaseFactoryFfi 作为默认的 databaseFactory
  // databaseFactory = databaseFactoryFfi;
  //
  // // 数据库配置
  // const tableName = 'ToDolist';
  // const columns = ['title', 'details', 'category', 'create_date'];
  // const columnProperties = ['TEXT', 'TEXT', 'TEXT', 'INTEGER'];
  //
  // // 创建 DBHelper 实例
  // final dbHelper = DBHelper();
  //
  // // 初始化数据库和表
  // final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);
  //
  // await dbHelper.insert(tableName, {
  //   'title': 'Test Title',
  //   'details': 'Test Details',
  //   'category': 'Test Category',
  //   'createDate': DateTime.now().millisecondsSinceEpoch,
  // });
  //
  // await db.close();
  var millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;
  print(millisecondsSinceEpoch);
}
