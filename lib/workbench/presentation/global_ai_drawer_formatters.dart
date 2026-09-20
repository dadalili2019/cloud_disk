part of 'global_ai_drawer.dart';

String _scopeLabel(AIContextScope scope) {
  return switch (scope) {
    AIContextScope.task => '任务',
    AIContextScope.workspace => '工作区',
    AIContextScope.knowledge => '知识',
    AIContextScope.global => '全局',
  };
}

String _scopeShortLabel(AIContextScope scope) {
  return switch (scope) {
    AIContextScope.task => '任务',
    AIContextScope.workspace => '工作区',
    AIContextScope.knowledge => '知识',
    AIContextScope.global => '全局',
  };
}

String _entityLabel(String type) {
  return switch (type) {
    'task' => '任务',
    'note' => '笔记',
    'issue' => '问题',
    'resource' => '资源',
    'decision' => '决策',
    'knowledge' => '知识',
    'workspace' => '工作区',
    'activity' => '活动',
    'developer_project' => '项目',
    'developer_command' => '命令',
    'developer_snippet' => '代码片段',
    _ => type,
  };
}

String _shortProviderName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return 'AI';
  if (normalized.length <= 16) return normalized;
  return '${normalized.substring(0, 16)}…';
}

String _formatCharacters(int value) {
  if (value < 1000) return '$value 字符';
  return '${(value / 1000).toStringAsFixed(1)}k 字符';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

String _readableError(Object error) {
  var value = error.toString().trim();
  value = value.replaceFirst(RegExp(r'^(StateError|Exception):\s*'), '');
  if (value.length > 280) value = '${value.substring(0, 280)}…';
  return value;
}
