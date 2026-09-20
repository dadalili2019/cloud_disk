part of 'settings_page.dart';

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({
    required this.settings,
    required this.workspaces,
    required this.onChanged,
  });

  final GeneralSettings settings;
  final List<WorkspaceModel> workspaces;
  final ValueChanged<GeneralSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final defaultWorkspaceValid = settings.defaultWorkspaceId != null &&
        workspaces.any((item) => item.id == settings.defaultWorkspaceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: '常规',
          children: [
            _SettingRow(
              title: '默认工作区',
              control: SizedBox(
                width: 250,
                child: ComboBox<String>(
                  value: defaultWorkspaceValid
                      ? settings.defaultWorkspaceId
                      : '__none__',
                  isExpanded: true,
                  items: [
                    const ComboBoxItem(
                      value: '__none__',
                      child: Text('不指定'),
                    ),
                    ...workspaces.map(
                      (workspace) => ComboBoxItem(
                        value: workspace.id,
                        child: Text(workspace.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    if (value == '__none__') {
                      onChanged(settings.copyWith(clearDefaultWorkspace: true));
                    } else {
                      onChanged(settings.copyWith(defaultWorkspaceId: value));
                    }
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '启动页面',
              control: SizedBox(
                width: 250,
                child: ComboBox<WorkbenchStartupPage>(
                  value: settings.startupPage,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: WorkbenchStartupPage.home,
                      child: Text('首页'),
                    ),
                    ComboBoxItem(
                      value: WorkbenchStartupPage.workspace,
                      child: Text('工作台'),
                    ),
                    ComboBoxItem(
                      value: WorkbenchStartupPage.knowledge,
                      child: Text('知识'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(settings.copyWith(startupPage: value));
                    }
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '快速记录关联当前任务',
              control: ToggleSwitch(
                checked: settings.quickCaptureToCurrentTask,
                onChanged: (value) => onChanged(
                  settings.copyWith(quickCaptureToCurrentTask: value),
                ),
              ),
            ),
            _SettingRow(
              title: '恢复上次工作上下文',
              control: ToggleSwitch(
                checked: settings.restoreLastActiveContext,
                onChanged: (value) => onChanged(
                  settings.copyWith(restoreLastActiveContext: value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.settings,
    required this.notesPath,
    required this.onChanged,
  });

  final NotesSettings settings;
  final String notesPath;
  final ValueChanged<NotesSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: 'Markdown 笔记',
          children: [
            const _SettingRow(
              title: '存储格式',
              control: _ValueBadge('.md'),
            ),
            _SettingRow(
              title: '默认视图',
              control: SizedBox(
                width: 250,
                child: ComboBox<NoteDefaultView>(
                  value: settings.defaultView,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: NoteDefaultView.edit,
                      child: Text('编辑'),
                    ),
                    ComboBoxItem(
                      value: NoteDefaultView.preview,
                      child: Text('预览'),
                    ),
                    ComboBoxItem(
                      value: NoteDefaultView.split,
                      child: Text('分栏'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(settings.copyWith(defaultView: value));
                    }
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '自动保存',
              control: ToggleSwitch(
                checked: settings.autoSave,
                onChanged: (value) =>
                    onChanged(settings.copyWith(autoSave: value)),
              ),
            ),
            _SettingRow(
              title: '笔记目录',
              control: SizedBox(
                width: 320,
                child: SelectableText(
                  notesPath,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: '快捷键',
          children: [
            _SettingRow(
              title: '保存笔记',
              control: _ValueBadge('Ctrl + S'),
            ),
            _SettingRow(
              title: '发送 AI 消息',
              control: _ValueBadge('Ctrl + Enter'),
            ),
            _SettingRow(
              title: '关闭 AI 助手',
              control: _ValueBadge('Esc'),
            ),
            _SettingRow(
              title: '全局搜索',
              control: _ValueBadge('未绑定'),
            ),
            _SettingRow(
              title: '快速记录',
              control: _ValueBadge('未绑定'),
            ),
            _SettingRow(
              title: '打开 AI',
              control: _ValueBadge('未绑定'),
            ),
          ],
        ),
      ],
    );
  }
}
