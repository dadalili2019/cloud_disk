import '../core/models.dart';
import '../data/markdown_store.dart';
import '../domain/decision_repository.dart';
import '../domain/issue_repository.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';
import 'knowledge_service.dart';

class KnowledgeDistillCandidate {
  const KnowledgeDistillCandidate({
    required this.sourceType,
    required this.sourceId,
    required this.workspaceId,
    required this.title,
    required this.preview,
    required this.suggestedCategory,
    required this.suggestedSummary,
    required this.suggestedMarkdown,
  });

  final String sourceType;
  final String sourceId;
  final String workspaceId;
  final String title;
  final String preview;
  final String suggestedCategory;
  final String suggestedSummary;
  final String suggestedMarkdown;
}

class KnowledgeSourceContext {
  const KnowledgeSourceContext({
    required this.entityType,
    required this.entityId,
    required this.title,
    this.workspaceId,
  });

  final String entityType;
  final String entityId;
  final String title;
  final String? workspaceId;
}

class KnowledgeDistillService {
  const KnowledgeDistillService({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.issues,
    required this.resources,
    required this.decisions,
    required this.store,
    required this.knowledge,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final IssueRepository issues;
  final ResourceRepository resources;
  final DecisionRepository decisions;
  final MarkdownStore store;
  final KnowledgeService knowledge;

  Future<List<WorkspaceModel>> listWorkspaces() => workspaces.listActive();

  Future<List<KnowledgeDistillCandidate>> listCandidates(
    String workspaceId,
  ) async {
    final taskItems = await tasks.listByWorkspace(workspaceId);
    final noteItems = await notes.listByWorkspace(workspaceId);
    final issueItems = await issues.listByWorkspace(workspaceId);
    final resourceItems = await resources.listByWorkspace(workspaceId);
    final decisionItems = await decisions.listByWorkspace(workspaceId);

    final result = <KnowledgeDistillCandidate>[];

    for (final task in taskItems) {
      final summary = _firstNonEmpty([
        task.description,
        task.nextStep,
      ]);
      result.add(
        KnowledgeDistillCandidate(
          sourceType: 'task',
          sourceId: task.id,
          workspaceId: task.workspaceId,
          title: task.title,
          preview: task.nextStep.isEmpty ? task.description : task.nextStep,
          suggestedCategory: 'Workflow',
          suggestedSummary: _shorten(summary),
          suggestedMarkdown: [
            '# ${task.title}',
            if (task.description.trim().isNotEmpty) '\n${task.description.trim()}',
            if (task.nextStep.trim().isNotEmpty) '\n## Next Step\n${task.nextStep.trim()}',
          ].join('\n'),
        ),
      );
    }

    for (final note in noteItems) {
      final content = await store.read(note.filePath);
      final plain = _plainMarkdown(content);
      result.add(
        KnowledgeDistillCandidate(
          sourceType: 'note',
          sourceId: note.id,
          workspaceId: note.workspaceId,
          title: note.title,
          preview: _shorten(plain, max: 120),
          suggestedCategory: '',
          suggestedSummary: _shorten(plain),
          suggestedMarkdown: content.trim(),
        ),
      );
    }

    for (final issue in issueItems) {
      final summary = _firstNonEmpty([
        issue.resolution,
        issue.hypothesis,
        issue.impact,
        issue.nextInvestigationStep,
      ]);
      result.add(
        KnowledgeDistillCandidate(
          sourceType: 'issue',
          sourceId: issue.id,
          workspaceId: issue.workspaceId,
          title: issue.title,
          preview: _shorten(summary, max: 120),
          suggestedCategory: 'Problem Solving',
          suggestedSummary: _shorten(summary),
          suggestedMarkdown: [
            '# ${issue.title}',
            if (issue.impact.trim().isNotEmpty) '\n## Impact\n${issue.impact.trim()}',
            if (issue.hypothesis.trim().isNotEmpty) '\n## Hypothesis\n${issue.hypothesis.trim()}',
            if (issue.nextInvestigationStep.trim().isNotEmpty)
              '\n## Next Investigation\n${issue.nextInvestigationStep.trim()}',
            if (issue.resolution.trim().isNotEmpty) '\n## Resolution\n${issue.resolution.trim()}',
          ].join('\n'),
        ),
      );
    }

    for (final resource in resourceItems) {
      final summary = _firstNonEmpty([resource.description, resource.uri]);
      result.add(
        KnowledgeDistillCandidate(
          sourceType: 'resource',
          sourceId: resource.id,
          workspaceId: resource.workspaceId,
          title: resource.name,
          preview: _shorten(summary, max: 120),
          suggestedCategory: 'Reference',
          suggestedSummary: _shorten(summary),
          suggestedMarkdown: [
            '# ${resource.name}',
            '\nType: ${resource.resourceType}',
            if (resource.uri.trim().isNotEmpty) '\nURI: ${resource.uri.trim()}',
            if (resource.description.trim().isNotEmpty)
              '\n## Notes\n${resource.description.trim()}',
          ].join('\n'),
        ),
      );
    }

    for (final decision in decisionItems) {
      final summary = _firstNonEmpty([
        decision.rationale,
        decision.decisionText,
        decision.revisitCondition,
      ]);
      result.add(
        KnowledgeDistillCandidate(
          sourceType: 'decision',
          sourceId: decision.id,
          workspaceId: decision.workspaceId,
          title: decision.title,
          preview: _shorten(summary, max: 120),
          suggestedCategory: 'Decision',
          suggestedSummary: _shorten(summary),
          suggestedMarkdown: [
            '# ${decision.title}',
            if (decision.decisionText.trim().isNotEmpty)
              '\n## Decision\n${decision.decisionText.trim()}',
            if (decision.rationale.trim().isNotEmpty)
              '\n## Why\n${decision.rationale.trim()}',
            if (decision.revisitCondition.trim().isNotEmpty)
              '\n## Revisit When\n${decision.revisitCondition.trim()}',
          ].join('\n'),
        ),
      );
    }

    return result;
  }

  Future<List<KnowledgeSourceContext>> sourceContexts(
    KnowledgeModel item,
  ) async {
    final refs = await knowledge.sources(item);
    final result = <KnowledgeSourceContext>[];

    for (final ref in refs) {
      switch (ref.entityType) {
        case 'task':
          final value = await tasks.getById(ref.entityId);
          if (value != null) {
            result.add(KnowledgeSourceContext(
              entityType: ref.entityType,
              entityId: ref.entityId,
              title: value.title,
              workspaceId: value.workspaceId,
            ));
          }
          break;
        case 'note':
          final value = await notes.getById(ref.entityId);
          if (value != null) {
            result.add(KnowledgeSourceContext(
              entityType: ref.entityType,
              entityId: ref.entityId,
              title: value.title,
              workspaceId: value.workspaceId,
            ));
          }
          break;
        case 'issue':
          final value = await issues.getById(ref.entityId);
          if (value != null) {
            result.add(KnowledgeSourceContext(
              entityType: ref.entityType,
              entityId: ref.entityId,
              title: value.title,
              workspaceId: value.workspaceId,
            ));
          }
          break;
        case 'resource':
          final value = await resources.getById(ref.entityId);
          if (value != null) {
            result.add(KnowledgeSourceContext(
              entityType: ref.entityType,
              entityId: ref.entityId,
              title: value.name,
              workspaceId: value.workspaceId,
            ));
          }
          break;
        case 'decision':
          final value = await decisions.getById(ref.entityId);
          if (value != null) {
            result.add(KnowledgeSourceContext(
              entityType: ref.entityType,
              entityId: ref.entityId,
              title: value.title,
              workspaceId: value.workspaceId,
            ));
          }
          break;
      }
    }

    return result;
  }

  Future<KnowledgeModel> distill({
    required KnowledgeDistillCandidate source,
    required String title,
    required String category,
    required String summary,
    required String useWhen,
    required String markdown,
    bool isPinned = false,
  }) {
    return knowledge.create(
      title: title,
      category: category,
      summary: summary,
      useWhen: useWhen,
      markdown: markdown,
      isPinned: isPinned,
      sources: [
        KnowledgeSourceRef(
          entityType: source.sourceType,
          entityId: source.sourceId,
        ),
      ],
    );
  }
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String _shorten(String value, {int max = 220}) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= max) return normalized;
  return '${normalized.substring(0, max).trim()}…';
}

String _plainMarkdown(String value) {
  return value
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'[#>*_`~-]+'), ' ')
      .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
