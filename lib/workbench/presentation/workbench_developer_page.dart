import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
import '../application/developer_command_service.dart';
import '../core/developer_models.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class WorkbenchDeveloperPage extends StatefulWidget {
  const WorkbenchDeveloperPage({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  State<WorkbenchDeveloperPage> createState() => _WorkbenchDeveloperPageState();
}

class _WorkbenchDeveloperPageState extends State<WorkbenchDeveloperPage> {
  late Future<DeveloperContextModel> _context;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _context = WorkbenchRuntime.instance.then(
      (runtime) => runtime.developerContextService.load(widget.workspaceId),
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _context;
  }

  Future<void> _copy(String value, String label) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    await displayInfoBar(
      context,
      builder: (_, close) => InfoBar(
        title: Text('已复制$label'),
        severity: InfoBarSeverity.success,
        onClose: close,
      ),
    );
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

  Future<void> _editProject({DeveloperProjectModel? project}) async {
    final name = TextEditingController(text: project?.name ?? '');
    final path = TextEditingController(text: project?.localPath ?? '');
    final repository = TextEditingController(text: project?.repositoryUrl ?? '');
    final branch = TextEditingController(text: project?.branch ?? '');
    final techStack = TextEditingController(text: project?.techStack ?? '');
    final notes = TextEditingController(text: project?.notes ?? '');
    var primary = project?.isPrimary ?? false;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => ContentDialog(
            title: Text(project == null ? '新建项目' : '编辑项目'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextBox(controller: name, placeholder: '项目名称', autofocus: true),
                    const SizedBox(height: 10),
                    TextBox(controller: path, placeholder: '本地目录，例如 D:\\workspace\\project'),
                    const SizedBox(height: 10),
                    TextBox(controller: repository, placeholder: 'Repository URL'),
                    const SizedBox(height: 10),
                    TextBox(controller: branch, placeholder: '常用分支，例如 main'),
                    const SizedBox(height: 10),
                    TextBox(controller: techStack, placeholder: '技术栈，例如 Flutter · Dart · SQLite'),
                    const SizedBox(height: 10),
                    TextBox(controller: notes, placeholder: '说明（可选）', maxLines: 4),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Checkbox(
                        checked: primary,
                        onChanged: (value) =>
                            setDialogState(() => primary = value ?? false),
                        content: const Text('设为主项目'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(project == null ? '创建' : '保存'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      if (project == null) {
        await runtime.developerProjectService.create(
          workspaceId: widget.workspaceId,
          name: name.text,
          localPath: path.text,
          repositoryUrl: repository.text,
          branch: branch.text,
          techStack: techStack.text,
          notes: notes.text,
          isPrimary: primary,
        );
      } else {
        await runtime.developerProjectService.update(
          project: project,
          name: name.text,
          localPath: path.text,
          repositoryUrl: repository.text,
          branch: branch.text,
          techStack: techStack.text,
          notes: notes.text,
          isPrimary: primary,
        );
      }
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    } finally {
      name.dispose();
      path.dispose();
      repository.dispose();
      branch.dispose();
      techStack.dispose();
      notes.dispose();
    }
  }

  Future<void> _archiveProject(DeveloperProjectModel project) async {
    final confirmed = await _confirmArchive('项目', project.name);
    if (!confirmed || !mounted) return;
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.developerProjectService.archive(project);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    }
  }

  Future<void> _setPrimary(DeveloperProjectModel project) async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.developerProjectService.setPrimary(project);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    }
  }

  Future<void> _editCommand({
    DeveloperCommandModel? command,
    required List<DeveloperProjectModel> projects,
  }) async {
    final name = TextEditingController(text: command?.name ?? '');
    final value = TextEditingController(text: command?.command ?? '');
    final workingDirectory =
        TextEditingController(text: command?.workingDirectory ?? '');
    final notes = TextEditingController(text: command?.notes ?? '');
    var projectId = command?.projectId;
    var category = command?.category ?? 'other';
    var pinned = command?.isPinned ?? false;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => ContentDialog(
            title: Text(command == null ? '新建命令' : '编辑命令'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextBox(controller: name, placeholder: '命令名称', autofocus: true),
                    const SizedBox(height: 10),
                    TextBox(controller: value, placeholder: '命令内容', maxLines: 3),
                    const SizedBox(height: 10),
                    ComboBox<String?>(
                      value: projectId,
                      isExpanded: true,
                      placeholder: const Text('关联项目（可选）'),
                      items: [
                        const ComboBoxItem<String?>(value: null, child: Text('不关联项目')),
                        ...projects.map(
                          (item) => ComboBoxItem<String?>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        ),
                      ],
                      onChanged: (selected) =>
                          setDialogState(() => projectId = selected),
                    ),
                    const SizedBox(height: 10),
                    ComboBox<String>(
                      value: category,
                      isExpanded: true,
                      items: DeveloperCommandService.allowedCategories
                          .map(
                            (item) => ComboBoxItem(
                              value: item,
                              child: Text(_commandCategoryLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          setDialogState(() => category = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextBox(
                      controller: workingDirectory,
                      placeholder: 'Working Directory（可选）',
                    ),
                    const SizedBox(height: 10),
                    TextBox(controller: notes, placeholder: '说明（可选）', maxLines: 3),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Checkbox(
                        checked: pinned,
                        onChanged: (selected) =>
                            setDialogState(() => pinned = selected ?? false),
                        content: const Text('置顶'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(command == null ? '创建' : '保存'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      if (command == null) {
        await runtime.developerCommandService.create(
          workspaceId: widget.workspaceId,
          name: name.text,
          command: value.text,
          projectId: projectId,
          workingDirectory: workingDirectory.text,
          category: category,
          notes: notes.text,
          isPinned: pinned,
        );
      } else {
        await runtime.developerCommandService.update(
          commandModel: command,
          name: name.text,
          command: value.text,
          projectId: projectId,
          workingDirectory: workingDirectory.text,
          category: category,
          notes: notes.text,
          isPinned: pinned,
        );
      }
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    } finally {
      name.dispose();
      value.dispose();
      workingDirectory.dispose();
      notes.dispose();
    }
  }

  Future<void> _archiveCommand(DeveloperCommandModel command) async {
    final confirmed = await _confirmArchive('命令', command.name);
    if (!confirmed || !mounted) return;
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.developerCommandService.archive(command);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    }
  }

  Future<void> _editSnippet({
    DeveloperSnippetModel? snippet,
    required List<DeveloperProjectModel> projects,
  }) async {
    final title = TextEditingController(text: snippet?.title ?? '');
    final language = TextEditingController(text: snippet?.language ?? '');
    final content = TextEditingController(text: snippet?.content ?? '');
    final notes = TextEditingController(text: snippet?.notes ?? '');
    var projectId = snippet?.projectId;
    var pinned = snippet?.isPinned ?? false;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => ContentDialog(
            title: Text(snippet == null ? '新建代码片段' : '编辑代码片段'),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextBox(controller: title, placeholder: '标题', autofocus: true),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextBox(controller: language, placeholder: '语言，例如 Dart / SQL'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ComboBox<String?>(
                            value: projectId,
                            isExpanded: true,
                            placeholder: const Text('关联项目（可选）'),
                            items: [
                              const ComboBoxItem<String?>(value: null, child: Text('不关联项目')),
                              ...projects.map(
                                (item) => ComboBoxItem<String?>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              ),
                            ],
                            onChanged: (selected) =>
                                setDialogState(() => projectId = selected),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextBox(
                      controller: content,
                      placeholder: '代码片段',
                      minLines: 7,
                      maxLines: 12,
                    ),
                    const SizedBox(height: 10),
                    TextBox(controller: notes, placeholder: '说明（可选）', maxLines: 3),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Checkbox(
                        checked: pinned,
                        onChanged: (selected) =>
                            setDialogState(() => pinned = selected ?? false),
                        content: const Text('置顶'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(snippet == null ? '创建' : '保存'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      if (snippet == null) {
        await runtime.developerSnippetService.create(
          workspaceId: widget.workspaceId,
          title: title.text,
          content: content.text,
          projectId: projectId,
          language: language.text,
          notes: notes.text,
          isPinned: pinned,
        );
      } else {
        await runtime.developerSnippetService.update(
          snippet: snippet,
          title: title.text,
          content: content.text,
          projectId: projectId,
          language: language.text,
          notes: notes.text,
          isPinned: pinned,
        );
      }
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    } finally {
      title.dispose();
      language.dispose();
      content.dispose();
      notes.dispose();
    }
  }

  Future<void> _archiveSnippet(DeveloperSnippetModel snippet) async {
    final confirmed = await _confirmArchive('代码片段', snippet.title);
    if (!confirmed || !mounted) return;
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.developerSnippetService.archive(snippet);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) await _showError(error);
    }
  }

  Future<bool> _confirmArchive(String type, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => ContentDialog(
            title: Text('归档$type'),
            content: Text('确认归档「$title」？数据不会被物理删除。'),
            actions: [
              Button(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('归档'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchSectionPage(
      title: '开发',
      subtitle: '集中维护项目位置、常用命令、代码片段和开发资源。',
      actions: [
        Button(onPressed: _refresh, child: const Text('刷新')),
      ],
      child: FutureBuilder<DeveloperContextModel>(
        future: _context,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 14, 12),
            children: [
              _projectsSection(data),
              const SizedBox(height: 14),
              _commandsSection(data),
              const SizedBox(height: 14),
              _snippetsSection(data),
              const SizedBox(height: 14),
              _resourcesSection(data.devResources),
            ],
          );
        },
      ),
    );
  }

  Widget _projectsSection(DeveloperContextModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchSectionHeader(
          title: '项目',
          trailing: FilledButton(
            onPressed: () => _editProject(),
            child: const Text('新建项目'),
          ),
        ),
        const SizedBox(height: 10),
        if (data.projects.isEmpty)
          _emptyCard('还没有开发项目，先记录项目目录、仓库和技术栈。')
        else
          ...data.projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _projectCard(project),
            ),
          ),
      ],
    );
  }

  Widget _projectCard(DeveloperProjectModel project) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (project.isPrimary) ...[
                const WorkbenchTag(label: '主项目', selected: true),
                const SizedBox(width: 6),
              ],
              Button(onPressed: () => _editProject(project: project), child: const Text('编辑')),
              const SizedBox(width: 6),
              Button(onPressed: () => _archiveProject(project), child: const Text('归档')),
            ],
          ),
          if (project.localPath.isNotEmpty) ...[
            const SizedBox(height: 10),
            _copyRow('本地目录', project.localPath, () => _copy(project.localPath, '路径')),
          ],
          if (project.repositoryUrl.isNotEmpty) ...[
            const SizedBox(height: 6),
            _copyRow('仓库', project.repositoryUrl, () => _copy(project.repositoryUrl, '仓库地址')),
          ],
          if (project.branch.isNotEmpty || project.techStack.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (project.branch.isNotEmpty) WorkbenchTag(label: '分支 · ${project.branch}'),
                if (project.techStack.isNotEmpty) WorkbenchTag(label: project.techStack),
              ],
            ),
          ],
          if (project.notes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              project.notes,
              style: TextStyle(
                fontSize: 11,
                color: theme.typography.body?.color?.withOpacity(0.60),
              ),
            ),
          ],
          if (!project.isPrimary) ...[
            const SizedBox(height: 10),
            Button(onPressed: () => _setPrimary(project), child: const Text('设为主项目')),
          ],
        ],
      ),
    );
  }

  Widget _commandsSection(DeveloperContextModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchSectionHeader(
          title: '常用命令',
          trailing: FilledButton(
            onPressed: () => _editCommand(projects: data.projects),
            child: const Text('新建命令'),
          ),
        ),
        const SizedBox(height: 10),
        if (data.commands.isEmpty)
          _emptyCard('暂无常用命令。这里适合保存启动、构建、测试、数据库和 Docker 命令。')
        else
          ...data.commands.map(
            (command) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _commandCard(command, data.projects),
            ),
          ),
      ],
    );
  }

  Widget _commandCard(
    DeveloperCommandModel command,
    List<DeveloperProjectModel> projects,
  ) {
    final palette = ThemeScope.of(context).palette;
    return WorkbenchCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (command.isPinned) ...[
                      const Icon(FluentIcons.pinned, size: 11),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        command.name,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    WorkbenchTag(label: _commandCategoryLabel(command.category)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: SelectableText(
                    command.command,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
                if (command.workingDirectory?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    '目录 · ${command.workingDirectory}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Button(onPressed: () => _copy(command.command, '命令'), child: const Text('复制')),
              const SizedBox(height: 6),
              Button(
                onPressed: () => _editCommand(command: command, projects: projects),
                child: const Text('编辑'),
              ),
              const SizedBox(height: 6),
              Button(onPressed: () => _archiveCommand(command), child: const Text('归档')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _snippetsSection(DeveloperContextModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchSectionHeader(
          title: '代码片段',
          trailing: FilledButton(
            onPressed: () => _editSnippet(projects: data.projects),
            child: const Text('新建片段'),
          ),
        ),
        const SizedBox(height: 10),
        if (data.snippets.isEmpty)
          _emptyCard('暂无代码片段。可以保存 SQL、Dart、Shell 等重复使用的片段。')
        else
          ...data.snippets.map(
            (snippet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _snippetCard(snippet, data.projects),
            ),
          ),
      ],
    );
  }

  Widget _snippetCard(
    DeveloperSnippetModel snippet,
    List<DeveloperProjectModel> projects,
  ) {
    final palette = ThemeScope.of(context).palette;
    return WorkbenchCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (snippet.isPinned) ...[
                const Icon(FluentIcons.pinned, size: 11),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  snippet.title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (snippet.language.isNotEmpty) WorkbenchTag(label: snippet.language),
              const SizedBox(width: 8),
              Button(onPressed: () => _copy(snippet.content, '代码片段'), child: const Text('复制')),
              const SizedBox(width: 6),
              Button(
                onPressed: () => _editSnippet(snippet: snippet, projects: projects),
                child: const Text('编辑'),
              ),
              const SizedBox(width: 6),
              Button(onPressed: () => _archiveSnippet(snippet), child: const Text('归档')),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(7),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                snippet.content,
                style: const TextStyle(fontSize: 11, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourcesSection(List<ResourceModel> resources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WorkbenchSectionHeader(title: '开发资源'),
        const SizedBox(height: 10),
        if (resources.isEmpty)
          _emptyCard('暂无开发资源。可在“资源”页维护 Repository、文档、服务地址等。')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resources
                .map(
                  (resource) => SizedBox(
                    width: 330,
                    child: WorkbenchCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.link, size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (resource.uri.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    resource.uri,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 9.5),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (resource.uri.isNotEmpty)
                            Button(
                              onPressed: () => _copy(resource.uri, '资源地址'),
                              child: const Text('复制'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: theme.typography.body?.color?.withOpacity(0.52),
        ),
      ),
    );
  }

  Widget _copyRow(String label, String value, VoidCallback onCopy) {
    final theme = FluentTheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.typography.body?.color?.withOpacity(0.50),
            ),
          ),
        ),
        Expanded(
          child: SelectableText(value, style: const TextStyle(fontSize: 11.5)),
        ),
        const SizedBox(width: 8),
        Button(onPressed: onCopy, child: const Text('复制')),
      ],
    );
  }
}

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
