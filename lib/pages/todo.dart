///  @author caoqian
/// @since 2024-04-25 13:51
/// @Description: 待办事项页面

import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../dto/todoList/todoList.dart';
import '../utils/DBHelper.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  @override
  void initState() {
    super.initState();
    // 在页面加载时执行数据库查询，并更新任务列表和展开项状态
    _fetchTasksFromDatabase();
  }

  // final List<Map<String, String>> tasks = [
  //   {'title': '任务6', 'category': '待整理', 'details': '任务6的详情'},
  //   {'title': '任务7', 'category': '已完成', 'details': '任务7的详情'},
  //   {'title': '任务8', 'category': '已完成', 'details': '任务8的详情'},
  //   {'title': '任务9', 'category': '待办', 'details': '任务9的详情'},
  // ];
  //
  // final Map<String, bool> _expandedItems = {
  //   '待办': false,
  //   '待整理': false,
  //   '已完成': false,
  // };

  List<Map<String, String>> tasks = [];
  Map<String, bool> _expandedItems = {};

  @override
  Widget build(BuildContext context) {
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: const Text('任务清单'),
        commandBar: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 250), // 调整左侧间距
              child: material.IconButton(
                icon: const Icon(fluent.FluentIcons.add),
                onPressed: () {
                  _showCommandBarDialog();
                },
              ),
            ),
          ],
        ),
      ),
      content: ListView(
        children: _expandedItems.keys.map((category) {
          List<Map<String, String>> filteredTasks =
              tasks.where((task) => task['category'] == category).toList();
          return _buildExpansionPanelList(category, filteredTasks);
        }).toList(),
      ),
    );
  }

  Widget _buildExpansionPanelList(
      String category, List<Map<String, String>> tasks) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: material.ExpansionPanelList(
        expandedHeaderPadding: EdgeInsets.zero,
        children: [
          material.ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return material.ListTile(
                title: Text(category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    material.IconButton(
                      icon: const Icon(fluent.FluentIcons.add_to),
                      onPressed: () {
                        _showAddTaskDialog(category);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _expandedItems[category] = !_expandedItems[category]!;
                  });
                },
              );
            },
            body: Column(
              children: tasks
                  .map((task) => material.ListTile(
                        title: Text(task['title']!),
                        onTap: () {
                          _showDetails(task['title']!, task['details']!);
                        },
                      ))
                  .toList(),
            ),
            isExpanded: _expandedItems[category]!,
          ),
        ],
      ),
    );
  }

  void _showDetails(String title, String details) {
    material.showDialog(
      context: context,
      builder: (BuildContext context) {
        return material.AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 400,  // 设置对话框的宽度
            height: 300, // 设置对话框的高度
            child: SingleChildScrollView(
              child: Text(details),
            ),
          ),
          actions: [
            material.TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }


  void _showAddTaskDialog(String category) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    material.showDialog(
      context: context,
      builder: (BuildContext context) {
        return material.AlertDialog(
          title: const Text('新增任务'),
          content: SizedBox(
            width: 400,  // 设置对话框的宽度
            height: 300, // 设置对话框的高度
            child: Column(
              children: [
                material.TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '标题'),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: material.TextField(
                    controller: detailsController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: '详情',
                      border: material.OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            material.TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            material.TextButton(
              onPressed: () async {
                await _addTaskToDatabase(
                  titleController.text,
                  detailsController.text,
                  category,
                );
                Navigator.of(context).pop();
                _fetchTasksFromDatabase();
              },
              child: const Text('提交'),
            ),
          ],
        );
      },
    );
  }


  void _fetchTasksFromDatabase() async {
    // 初始化 sqflite_common_ffi
    sqfliteFfiInit();
    // 设置 databaseFactoryFfi 作为默认的 databaseFactory
    databaseFactory = databaseFactoryFfi;

    // 数据库配置
    const tableName = TodoList.tableName;
    const columns = TodoList.columns;
    const columnProperties = TodoList.columnsType;

    // 创建 DBHelper 实例
    final dbHelper = DBHelper();

    // 初始化数据库和表
    final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

    List<Map<String, dynamic>> allRows = await dbHelper.getAll(tableName);

    Set<String> categories = {};
    List<Map<String, String>> fetchedTasks = [];

    for (Map<String, dynamic> row in allRows) {
      Map<String, String> task = {
        'title': row['title'].toString(),
        'category': row['category'].toString(),
        'details': row['details'].toString(),
      };
      fetchedTasks.add(task);
      categories.add(row['category'].toString());
    }

    setState(() {
      tasks = fetchedTasks;
      _expandedItems = {for (var category in categories) category: false};
    });

    await db.close();
  }

  _addTaskToDatabase(String title, String details, String category) async {
    // 初始化 sqflite_common_ffi
    sqfliteFfiInit();
    // 设置 databaseFactoryFfi 作为默认的 databaseFactory
    databaseFactory = databaseFactoryFfi;

    // 数据库配置
    const tableName = TodoList.tableName;
    const columns = TodoList.columns;
    const columnProperties = TodoList.columnsType;

    // 创建 DBHelper 实例
    final dbHelper = DBHelper();
    // 初始化数据库和表
    final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

    Random random = Random();
    int randomId = random.nextInt(1000000000); // 生成一个9位数的随机ID

    // 插入任务到数据库
    await dbHelper.insert(tableName, {
      'title': title,
      'details': details,
      'category': category,
      'create_date': DateTime.now().millisecondsSinceEpoch,
      'id': randomId,
    });

    await db.close();
  }

  String generateRandomId(int length) {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }


  void _showCommandBarDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    String selectedCategory = '待办'; // 默认类别

    material.showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return material.AlertDialog(
              title: const Text('新增任务'),
              content: SizedBox(
                width: 400, // 设置对话框的宽度
                height: 300, // 设置对话框的高度
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 左对齐所有子元素
                  children: [
                    material.TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: '标题'),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: material.TextField(
                        controller: detailsController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: '详情',
                          border: material.OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft, // 下拉框左对齐
                      child: material.DropdownButton<String>(
                        value: selectedCategory,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue!;
                          });
                        },
                        items: <String>['待办', '待整理', '已完成']
                            .map<material.DropdownMenuItem<String>>((String value) {
                          return material.DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                material.TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                material.TextButton(
                  onPressed: () async {
                    await _addTaskToDatabase(
                      titleController.text,
                      detailsController.text,
                      selectedCategory,
                    );
                    Navigator.of(context).pop();
                    _fetchTasksFromDatabase();
                  },
                  child: const Text('提交'),
                ),
              ],
            );
          },
        );
      },
    );
  }



}
