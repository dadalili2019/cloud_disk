part of 'workbench_knowledge_page.dart';

String _entityLabel(String type) {
  return switch (type) {
    'task' => '任务',
    'note' => '笔记',
    'issue' => '问题',
    'resource' => '资源',
    'decision' => '决策',
    'knowledge' => '知识',
    'developer_project' => '项目',
    'developer_command' => '命令',
    'developer_snippet' => '代码片段',
    _ => type,
  };
}
