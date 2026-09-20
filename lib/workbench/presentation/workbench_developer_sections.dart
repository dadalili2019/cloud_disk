part of 'workbench_developer_page.dart';

extension _WorkbenchDeveloperSections on _WorkbenchDeveloperPageState {
  Widget _projectsSection(DeveloperContextModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchSectionHeader(
          title: '项目',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button(
                onPressed: _refresh,
                child: const Text('刷新'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _editProject(),
                child: const Text('新建项目'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (data.projects.isEmpty)
          _emptyCard('暂无项目')
        else
          ...data.projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _projectCard(project),
            ),
          ),
      ],
    );
  }

  Widget _projectCard(DeveloperProjectModel project) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      padding: const EdgeInsets.all(18),
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
                color: theme.typography.body?.color?.withValues(alpha: 0.60),
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
        const SizedBox(height: 14),
        if (data.commands.isEmpty)
          _emptyCard('暂无常用命令')
        else
          ...data.commands.map(
            (command) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 14),
        if (data.snippets.isEmpty)
          _emptyCard('暂无代码片段')
        else
          ...data.snippets.map(
            (snippet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 14),
        if (resources.isEmpty)
          _emptyCard('暂无开发资源')
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: resources
                .map(
                  (resource) => SizedBox(
                    width: 330,
                    child: WorkbenchCard(
                      padding: const EdgeInsets.all(16),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: theme.typography.body?.color?.withValues(alpha: 0.48),
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
              color: theme.typography.body?.color?.withValues(alpha: 0.50),
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
}
