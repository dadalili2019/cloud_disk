import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import 'workbench_ui.dart';

class WorkbenchToolsPage extends StatelessWidget {
  const WorkbenchToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const general = <_ToolEntry>[
      _ToolEntry('JSON 格式化', FluentIcons.format_painter, '/jsonformat'),
      _ToolEntry('文字比对', FluentIcons.branch_compare, '/comparison'),
      _ToolEntry('网络测速', FluentIcons.my_network, '/speedtestpage'),
      _ToolEntry('RAG 知识库', FluentIcons.library, '/ragknowledge'),
    ];

    const images = <_ToolEntry>[
      _ToolEntry('批量图片转换', FluentIcons.switch_widget, '/imagetools/convert'),
      _ToolEntry('图片水印', FluentIcons.text_box, '/imagetools/watermark'),
      _ToolEntry('裁剪与尺寸', FluentIcons.crop, '/imagetools/crop'),
      _ToolEntry('滤镜增强', FluentIcons.color, '/imagetools/filter'),
      _ToolEntry('拼图九宫格', FluentIcons.grid_view_medium, '/imagetools/collage'),
      _ToolEntry('图片去重', FluentIcons.search_and_apps, '/imagetools/dedupe'),
    ];

    const others = <_ToolEntry>[
      _ToolEntry('GAME', FluentIcons.game, '/game'),
    ];

    return const WorkbenchPage(
      title: '工具',
      children: [
        _ToolSection(title: '通用', tools: general),
        SizedBox(height: 24),
        _ToolSection(title: '图片', tools: images),
        SizedBox(height: 24),
        _ToolSection(title: '其他', tools: others),
      ],
    );
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.tools,
  });

  final String title;
  final List<_ToolEntry> tools;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchSectionHeader(title: title),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 580
                    ? 2
                    : 1;
            const gap = 16.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: tools
                  .map(
                    (tool) => SizedBox(
                      width: width,
                      child: _ToolCard(tool: tool),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final _ToolEntry tool;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final secondary =
        theme.typography.body?.color?.withValues(alpha: 0.58);

    return WorkbenchCard(
      onTap: () => context.go(tool.route),
      minHeight: 62,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: Icon(
                tool.icon,
                size: 17,
                color: theme.typography.body?.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tool.title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            FluentIcons.chevron_right,
            size: 9,
            color: secondary,
          ),
        ],
      ),
    );
  }
}

class _ToolEntry {
  const _ToolEntry(this.title, this.icon, this.route);

  final String title;
  final IconData icon;
  final String route;
}
