import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import 'workbench_ui.dart';

class WorkbenchToolsPage extends StatelessWidget {
  const WorkbenchToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <_ToolEntry>[
      const _ToolEntry('JSON 格式化', FluentIcons.format_painter, '/jsonformat'),
      const _ToolEntry('文字比对', FluentIcons.branch_compare, '/comparison'),
      const _ToolEntry('网络测速', FluentIcons.my_network, '/speedtestpage'),
      const _ToolEntry('批量图片转换', FluentIcons.switch_widget, '/imagetools/convert'),
      const _ToolEntry('图片水印', FluentIcons.text_box, '/imagetools/watermark'),
      const _ToolEntry('裁剪与尺寸', FluentIcons.crop, '/imagetools/crop'),
      const _ToolEntry('滤镜增强', FluentIcons.color, '/imagetools/filter'),
      const _ToolEntry('拼图九宫格', FluentIcons.grid_view_medium, '/imagetools/collage'),
      const _ToolEntry('图片去重', FluentIcons.search_and_apps, '/imagetools/dedupe'),
      const _ToolEntry('RAG 知识库', FluentIcons.library, '/ragknowledge'),
      const _ToolEntry('GAME', FluentIcons.game, '/game'),
    ];

    return WorkbenchPage(
      title: '工具',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 580
                    ? 2
                    : 1;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: tools
                  .map(
                    (tool) => SizedBox(
                      width: width,
                      child: WorkbenchCard(
                        onTap: () => context.go(tool.route),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(tool.icon, size: 18),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                tool.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(FluentIcons.chevron_right, size: 10),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ToolEntry {
  const _ToolEntry(this.title, this.icon, this.route);

  final String title;
  final IconData icon;
  final String route;
}
