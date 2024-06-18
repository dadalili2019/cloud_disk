///  @author caoqian
/// @since 2024-06-18 12:58
/// @Description: todoList 对象

class TodoList {
  String? title;
  String? details;
  String? category;
  int? createDate;
  int? id;

  TodoList({
    this.title,
    this.details,
    this.category,
    this.createDate,
    this.id,
  });

  static const columns = [
    'title',
    'details',
    'category',
    'createDate',
    'id',
  ];

  static const tableName = 'ToDolist';

  static const columnsType = [
    'TEXT',
    'TEXT',
    'TEXT',
    'INTEGER',
    'INTEGER',
  ];

  // 将对象属性名转换为字符串集合
  List<String> getPropertyNames() {
    return [
      'title',
      'details',
      'category',
      'createDate',
      'id',
    ];
  }

  // 将数据库中的行转换为 ToDoItem 对象
  factory TodoList.fromMap(Map<String, dynamic> map) {
    return TodoList(
      title: map['title'],
      details: map['details'],
      category: map['category'],
      createDate: map['create_date'],
      id: map['id'],
    );
  }

  // 将 ToDoItem 对象转换为 Map，便于插入数据库
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'details': details,
      'category': category,
      'create_date': createDate,
      'id': id,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details': details,
      'category': category,
      'create_date': createDate,
      'id': id,
    };
  }
}
