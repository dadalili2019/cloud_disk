///  @author caoqian
/// @since 2024-06-18 13:33
/// @Description: DDL快速生成实体对象

class DDLToDart {
  static String generateClass(
      String tableName, List<Map<String, String>> columns) {
    StringBuffer classBuffer = StringBuffer();

    // 生成类定义
    classBuffer.writeln('class ${_capitalize(tableName)} {');

    // 生成属性定义
    for (var column in columns) {
      classBuffer.writeln(
          '  ${_mapSqlTypeToDartType(column['type']!)}? ${column['name']};');
    }
    classBuffer.writeln('');

    // 生成构造函数
    classBuffer.write('  ${_capitalize(tableName)}({');
    for (var column in columns) {
      classBuffer.write('this.${column['name']}, ');
    }
    classBuffer.writeln('});\n');

    // 生成静态字段
    classBuffer.writeln('  static const columns = [');
    for (var column in columns) {
      classBuffer.writeln("    '${column['name']}',");
    }
    classBuffer.writeln('  ];\n');

    classBuffer.writeln('  static const columnsType = [');
    for (var column in columns) {
      classBuffer.writeln("    '${column['type']}',");
    }
    classBuffer.writeln('  ];\n');

    classBuffer.writeln("  static const tableName = '$tableName';\n");

    // 生成 getPropertyNames 方法
    classBuffer.writeln('  List<String> getPropertyNames() {');
    classBuffer.writeln('    return [');
    for (var column in columns) {
      classBuffer.writeln("      '${column['name']}',");
    }
    classBuffer.writeln('    ];');
    classBuffer.writeln('  }\n');

    // 生成 fromMap 工厂构造函数
    classBuffer.writeln(
        '  factory ${_capitalize(tableName)}.fromMap(Map<String, dynamic> map) {');
    classBuffer.writeln('    return ${_capitalize(tableName)}(');
    for (var column in columns) {
      classBuffer.writeln("      ${column['name']}: map['${column['name']}'],");
    }
    classBuffer.writeln('    );');
    classBuffer.writeln('  }\n');

    // 生成 toMap 方法
    classBuffer.writeln('  Map<String, dynamic> toMap() {');
    classBuffer.writeln('    return {');
    for (var column in columns) {
      classBuffer.writeln("      '${column['name']}']: ${column['name']},");
    }
    classBuffer.writeln('    };');
    classBuffer.writeln('  }\n');

    // 生成 toJson 方法
    classBuffer.writeln('  Map<String, dynamic> toJson() {');
    classBuffer.writeln('    return {');
    for (var column in columns) {
      classBuffer.writeln("      '${column['name']}']: ${column['name']},");
    }
    classBuffer.writeln('    };');
    classBuffer.writeln('  }\n');

    classBuffer.writeln('}');

    return classBuffer.toString();
  }

  // 辅助方法：将 SQL 类型映射到 Dart 类型
  static String _mapSqlTypeToDartType(String sqlType) {
    switch (sqlType.toLowerCase()) {
      case 'text':
        return 'String';
      case 'integer':
        return 'int';
      case 'real':
        return 'double';
      case 'blob':
        return 'Uint8List';
      default:
        return 'String';
    }
  }

  // 辅助方法：将字符串的首字母大写
  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

//example
void main() {
  String tableName = 'todoList';
  List<Map<String, String>> columns = [
    {'name': 'title', 'type': 'TEXT'},
    {'name': 'details', 'type': 'TEXT'},
    {'name': 'category', 'type': 'TEXT'},
    {'name': 'create_date', 'type': 'INTEGER'},
  ];

  String dartClass = DDLToDart.generateClass(tableName, columns);
  print(dartClass);
}
