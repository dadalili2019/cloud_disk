part of 'workbench_developer_page.dart';

extension _WorkbenchDeveloperActions on _WorkbenchDeveloperPageState {
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
                    const SizedBox(height: 24),
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
      _reloadState();
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
      _reloadState();
    } catch (error) {
      if (mounted) await _showError(error);
    }
  }

  Future<void> _setPrimary(DeveloperProjectModel project) async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.developerProjectService.setPrimary(project);
      _reloadState();
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
                    const SizedBox(height: 24),
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
      _reloadState();
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
      _reloadState();
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
                    const SizedBox(height: 24),
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
      _reloadState();
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
      _reloadState();
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

}
