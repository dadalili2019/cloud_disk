///  @author caoqian
/// @since 2024-06-18 13:05
/// @Description: 实体对象工具类

class PropertyUtils<T> {

  //将实体对象中的属性名称取出来，逗号分隔 集合作为返回值
  List<String> getPropertyNames(T obj) {
    var instance = obj;
    var properties = instance.runtimeType.toString(); // 获取对象类型的字符串表示形式
    List<String> propertyNames = properties.split(", ");
    return propertyNames;
  }
}
