///  @author caoqian
/// @since 2024-04-30 13:35
/// @Description: 对应DB的实体类对象



class User {
  final int id;
  final String name;
  final int age;

  User({required this.id, required this.name, required this.age});

  @override
  String toString() {
    return 'User{id: $id, name: $name, age: $age}';
  }
}


