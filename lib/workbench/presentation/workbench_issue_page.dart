import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';

class WorkbenchIssuePage extends StatefulWidget {
  const WorkbenchIssuePage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchIssuePage> createState() => _WorkbenchIssuePageState();
}

class _WorkbenchIssuePageState extends State<WorkbenchIssuePage> {
  late Future<List<IssueModel>> _issues;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _issues = WorkbenchRuntime.instance.then(
      (runtime) => runtime.issueService.listByWorkspace(widget.workspaceId),
    );
  }

  Future<void> _createIssue() async {
    final title = TextEditingController();
    final impact = TextEditingController();
    final hypothesis = TextEditingController();
    final nextStep = TextEditingController();
    var severity = 'medium';

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => ContentDialog(
            title: const Text('新建问题'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextBox(
                    controller: title,
                    placeholder: '问题名称',
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  ComboBox<String>(
                    value: severity,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(value: 'low', child: Text('低')),
                      ComboBoxItem(value: 'medium', child: Text('中')),
                      ComboBoxItem(value: 'high', child: Text('高')),
                      ComboBoxItem(value: 'critical', child: Text('严重')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => severity = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: impact,
                    placeholder: '影响',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: hypothesis,
                    placeholder: '当前假设',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: nextStep,
                    placeholder: '下一步调查',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('创建'),
              ),
            ],
          ),
        ),
      );

      if (confirmed != true || !mounted) return;

      final runtime = await WorkbenchRuntime.instance;
      await runtime.issueService.create(
        workspaceId: widget.workspaceId,
        title: title.text,
        severity: severity,
        impact: impact.text,
        hypothesis: hypothesis.text,
        nextInvestigationStep: nextStep.text,
      );

      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(error);
    } finally {
      title.dispose();
      impact.dispose();
      hypothesis.dispose();
      nextStep.dispose();
    }
  }

  Future<void> _showError(Object error) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('操作失败'),
        content: Text(error.toString()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'investigating':
        return '调查中';
      case 'resolved':
        return '已解决';
      case 'archived':
        return '已归档';
      default:
        return '待处理';
    }
  }

  String _severityText(String severity) {
    switch (severity) {
      case 'low':
        return '低';
      case 'high':
        return '高';
      case 'critical':
        return '严重';
      default:
        return '中';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('问题'),
        commandBar: FilledButton(
          onPressed: _createIssue,
          child: const Text('新建问题'),
        ),
      ),
      content: FutureBuilder<List<IssueModel>>(
        future: _issues,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final issues = snapshot.data ?? const <IssueModel>[];
          if (issues.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: _createIssue,
                child: const Text('新建第一个问题'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            itemCount: issues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final issue = issues[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: FluentTheme.of(context).inactiveColor.withOpacity(0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _IssueBadge(text: _severityText(issue.severity)),
                        const SizedBox(width: 6),
                        _IssueBadge(text: _statusText(issue.status)),
                      ],
                    ),
                    if (issue.impact.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('影响：${issue.impact}', style: const TextStyle(fontSize: 12)),
                    ],
                    if (issue.hypothesis.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('当前假设：${issue.hypothesis}', style: const TextStyle(fontSize: 12)),
                    ],
                    if (issue.nextInvestigationStep.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '下一步调查：${issue.nextInvestigationStep}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _IssueBadge extends StatelessWidget {
  const _IssueBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).inactiveColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}
