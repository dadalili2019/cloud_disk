part of 'navigation_page.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.compact,
    required this.currentWork,
    required this.contextLoading,
    required this.onWorkspacePressed,
    required this.location,
    required this.isActive,
    required this.onHome,
    required this.onWorkspace,
    required this.onTime,
    required this.onKnowledge,
    required this.onDeveloper,
    required this.onTools,
    required this.onSettings,
  });

  final bool compact;
  final ContinueItem? currentWork;
  final bool contextLoading;
  final VoidCallback onWorkspacePressed;
  final String location;
  final bool Function(_NavTarget, String) isActive;
  final VoidCallback onHome;
  final VoidCallback onWorkspace;
  final VoidCallback onTime;
  final VoidCallback onKnowledge;
  final VoidCallback onDeveloper;
  final VoidCallback onTools;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    final workspace =
        contextLoading ? '加载中…' : currentWork?.workspace.name ?? '选择工作区';
    return SizedBox(
      width: compact ? 68 : _shellSidebarWidth,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(compact ? 10 : 12, 10, compact ? 10 : 12, 14),
        child: Column(children: [
          Tooltip(
              message: '切换工作区 · $workspace',
              child: _ShellButton(
                label: '切换工作区',
                height: compact ? 44 : 60,
                padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
                background: colors.surface,
                onPressed: onWorkspacePressed,
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(FluentIcons.open_folder_horizontal,
                        size: 18, color: colors.accent),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('当前工作区',
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: colors.secondary)),
                          const SizedBox(height: 2),
                          Text(workspace,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.text)),
                        ],
                      )),
                      Icon(FluentIcons.chevron_down,
                          size: 9, color: colors.secondary),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Expanded(
              child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (!compact) const _SidebarSectionLabel('日常'),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.home,
                  label: '首页',
                  active: isActive(_NavTarget.home, location),
                  onPressed: onHome),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.open_folder_horizontal,
                  label: '工作区',
                  active: isActive(_NavTarget.workspace, location),
                  onPressed: onWorkspace),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.clock,
                  label: '时间',
                  active: isActive(_NavTarget.time, location),
                  onPressed: onTime),
              const SizedBox(height: 20),
              if (!compact) const _SidebarSectionLabel('资料与工具'),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.doc_library,
                  label: '知识',
                  active: isActive(_NavTarget.knowledge, location),
                  onPressed: onKnowledge),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.developer_tools,
                  label: '开发者',
                  active: isActive(_NavTarget.developer, location),
                  onPressed: onDeveloper),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.toolbox,
                  label: '工具',
                  active: isActive(_NavTarget.tools, location),
                  onPressed: onTools),
            ],
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Container(height: 1, color: colors.border),
          ),
          _NavItem(
              compact: compact,
              icon: FluentIcons.settings,
              label: '设置',
              active: isActive(_NavTarget.settings, location),
              onPressed: onSettings),
        ]),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: _ShellColors.of(context).secondary,
          )),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.compact,
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    final foreground = active ? colors.text : colors.secondary;
    final button = Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: _ShellButton(
        label: label,
        onPressed: onPressed,
        selected: active,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
        child: Row(
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: active ? colors.accent : foreground),
            if (!compact) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                label,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: foreground),
              )),
              if (active)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: colors.accent, shape: BoxShape.circle),
                ),
            ],
          ],
        ),
      ),
    );
    return compact ? Tooltip(message: label, child: button) : button;
  }
}

/// 路由只用于外框标题，内部页面仍保留原有布局与滚动区域。
class _ContentFrame extends StatelessWidget {
  const _ContentFrame(
      {required this.location, required this.compact, required this.child});

  final String location;
  final bool compact;
  final Widget child;

  (String, String) get _breadcrumb {
    final path = Uri.parse(location).path;
    if (path.startsWith('/workspace/')) {
      final section = path.split('/').last;
      const sections = {
        'overview': '概览',
        'tasks': '任务',
        'notes': '笔记',
        'issues': '问题',
        'resources': '资源',
        'decisions': '决策',
        'developer': '开发',
      };
      return ('工作区', sections[section] ?? '概览');
    }
    const pages = {
      '/home': ('个人空间', '首页'),
      '/workspace': ('个人空间', '工作区'),
      '/time': ('个人空间', '时间'),
      '/knowledge': ('资料与工具', '知识'),
      '/developer': ('资料与工具', '开发者'),
      '/tools': ('资料与工具', '工具'),
      '/jsonformat': ('工具', 'JSON 格式化'),
      '/comparison': ('工具', '文字比对'),
      '/speedtestpage': ('工具', '网络测速'),
      '/ragknowledge': ('工具', 'RAG 知识库'),
      '/game': ('工具', '游戏'),
    };
    if (path.startsWith('/setting')) return ('个人空间', '设置');
    if (path.startsWith('/imagetools')) return ('工具', '图片工具');
    return pages[path] ?? ('个人空间', '工作台');
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    final palette = ThemeScope.of(context).palette;
    final (section, title) = _breadcrumb;
    return Padding(
      padding: EdgeInsets.only(right: compact ? 8 : 14, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: palette.appBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: palette.appBackground,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(children: [
                Text(section,
                    style: TextStyle(fontSize: 12, color: colors.secondary)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(FluentIcons.chevron_right,
                      size: 8, color: colors.secondary),
                ),
                Expanded(
                    child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.text),
                        ))),
              ]),
            ),
            Expanded(child: child),
          ]),
        ),
      ),
    );
  }
}
