part of 'workbench_knowledge_page.dart';

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({required this.item, required this.onTap});

  final KnowledgeModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      onTap: onTap,
      minHeight: 156,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.category.isNotEmpty) WorkbenchTag(label: item.category),
              const Spacer(),
              if (item.isPinned) const Icon(FluentIcons.pinned, size: 12),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              item.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: theme.typography.body?.color?.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.onOpen,
  });

  final String query;
  final List<SearchResultModel> results;
  final ValueChanged<SearchResultModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (results.isEmpty) {
      return WorkbenchCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Text(
          '没有找到“$query”相关内容',
          style: TextStyle(
            fontSize: 11.5,
            color: theme.typography.body?.color?.withValues(alpha: 0.56),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkbenchSectionHeader(title: '搜索结果  ${results.length}'),
        const SizedBox(height: 10),
        ...results.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkbenchCard(
              onTap: () => onOpen(result),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkbenchTag(label: _entityLabel(result.entityType)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (result.snippet.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            result.snippet.replaceAll('[', '').replaceAll(']', ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: theme.typography.body?.color?.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(FluentIcons.chevron_right, size: 11),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
