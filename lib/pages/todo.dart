///  @author caoqian
/// @since 2024-04-25 13:51
/// @Description: 待办事项页面

import 'dart:math';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../dto/todoList/todoList.dart';
import '../utils/DBHelper.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, String>> tasks = [];
  Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _fetchTasksFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('清单列表'),
        commandBar: CommandBar(primaryItems: [
          CommandBarButton(
            icon: const Icon(FluentIcons.add),
            label: const Text('新增'),
            onPressed: _showCommandBarDialog,
          ),
        ]),
      ),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: _expandedItems.keys.map((category) {
          final filtered =
              tasks.where((t) => t['category'] == category).toList();
          return _buildCategoryCard(theme, category, filtered);
        }).toList(),
      ),
    );
  }

  // 分类卡片 + 折叠列表
  Widget _buildCategoryCard(
      FluentThemeData theme, String category, List<Map<String, String>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.resources.cardBackgroundFillColorDefault,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                blurRadius: 14, offset: Offset(0, 6), color: Color(0x12000000))
          ],
        ),
        child: Expander(
          initiallyExpanded: _expandedItems[category] ?? false,
          onStateChanged: (v) => setState(() => _expandedItems[category] = v),

          // 头部更瘦
          header: SizedBox(
            height: 37, // ← 想更瘦可改成 32
            child: Row(
              children: [
                Text(category,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(FluentIcons.add_to, size: 14),
                  onPressed: () => _showAddTaskDialog(category),
                ),
              ],
            ),
          ),

          // 4.8.x 有 contentPadding 就设为最小；没有该参数就删掉这一行也行
          contentPadding: EdgeInsets.zero,

          // 列表内容更瘦
          content: items.isEmpty
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child:
                      InfoLabel(label: '暂无任务', child: const SizedBox.shrink()),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                  child: Column(
                    children: items.map((task) {
                      return Container(
                        // 薄一点的卡片
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              theme.resources.cardBackgroundFillColorSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // 用 SizedBox + Button 自定义行高，比 ListTile 更好控
                        child: SizedBox(
                          height: 32,
                          width: double.infinity, // 铺满整行
                          child: Button(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10)),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            onPressed: () => _showDetails(task['title']!, task['details']!),
                            child: Row(
                              children: [
                                Expanded( // 占满左侧空间
                                  child: Align(
                                    alignment: Alignment.centerLeft, // 文本靠左
                                    child: Text(
                                      task['title'] ?? '',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const Icon(FluentIcons.chevron_right, size: 14), // 右侧箭头
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  // 详情对话框（纯白卡片）
  void _showDetails(String title, String details) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 460),
        title: Text(title),
        content: SizedBox(
          height: 280,
          child: SingleChildScrollView(child: Text(details)),
        ),
        actions: [
          Button(
              child: const Text('关闭'), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  // 在指定分组下新增
  void _showAddTaskDialog(String category) {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 460),
        title: const Text('新增任务'),
        content: SizedBox(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('标题'),
              const SizedBox(height: 6),
              TextBox(controller: titleController, placeholder: '例如：写周报'),
              const SizedBox(height: 16),
              const Text('详情'),
              const SizedBox(height: 6),
              Expanded(
                child: TextBox(
                  controller: detailsController,
                  minLines: 4,
                  maxLines: null,
                  placeholder: '补充说明（可选）',
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(label: '类别', child: Text(category)),
            ],
          ),
        ),
        actions: [
          Button(
              child: const Text('取消'), onPressed: () => Navigator.pop(context)),
          FilledButton(
            child: const Text('提交'),
            onPressed: () async {
              await _addTaskToDatabase(
                  titleController.text, detailsController.text, category);
              if (context.mounted) Navigator.pop(context);
              _fetchTasksFromDatabase();
            },
          ),
        ],
      ),
    );
  }

  // 顶部「新增」按钮弹窗（可选类别）
  void _showCommandBarDialog() {
    final title = TextEditingController();
    final details = TextEditingController();
    String category = '待办';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => ContentDialog(
          constraints: const BoxConstraints(maxWidth: 460),
          title: const Text('新增任务'),
          content: SizedBox(
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('标题'),
                const SizedBox(height: 6),
                TextBox(controller: title, placeholder: '例如：写周报'),
                const SizedBox(height: 16),
                const Text('详情'),
                const SizedBox(height: 6),
                Expanded(
                  child: TextBox(
                    controller: details,
                    minLines: 4,
                    maxLines: null,
                    placeholder: '补充说明（可选）',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('类别'),
                const SizedBox(height: 6),
                ComboBox<String>(
                  value: category,
                  items: const ['待办', '待整理', '已完成']
                      .map(
                          (e) => ComboBoxItem<String>(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setS(() => category = v!),
                ),
              ],
            ),
          ),
          actions: [
            Button(
                child: const Text('取消'),
                onPressed: () => Navigator.pop(context)),
            FilledButton(
              child: const Text('提交'),
              onPressed: () async {
                await _addTaskToDatabase(title.text, details.text, category);
                if (context.mounted) Navigator.pop(context);
                _fetchTasksFromDatabase();
              },
            ),
          ],
        ),
      ),
    );
  }

  // =================== 数据层（保持不变） ===================

  Future<void> _fetchTasksFromDatabase() async {
    // FFI 初始化（多次调用也安全）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    const tableName = TodoList.tableName;
    const columns = TodoList.columns;
    const columnProperties = TodoList.columnsType;

    final dbHelper = DBHelper();
    final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

    final allRows = await dbHelper.getAll(tableName);

    final categories = <String>{};
    final fetched = <Map<String, String>>[];

    for (final row in allRows) {
      fetched.add({
        'title': row['title'].toString(),
        'category': row['category'].toString(),
        'details': row['details'].toString(),
      });
      categories.add(row['category'].toString());
    }

    setState(() {
      tasks = fetched;
      _expandedItems = {for (final c in categories) c: false};
    });

    await db.close();
  }

  Future<void> _addTaskToDatabase(
      String title, String details, String category) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    const tableName = TodoList.tableName;
    const columns = TodoList.columns;
    const columnProperties = TodoList.columnsType;

    final dbHelper = DBHelper();
    final db = await dbHelper.initDb(tableName, 1, columns, columnProperties);

    final randomId = Random().nextInt(1000000000);

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
    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
