part of 'workbench_developer_page.dart';

String _commandCategoryLabel(String category) {
  return switch (category) {
    'run' => '运行',
    'build' => '构建',
    'test' => '测试',
    'database' => '数据库',
    'docker' => 'Docker',
    'git' => 'Git',
    _ => '其他',
  };
}
