part of 'ai_context_builder.dart';

extension _AIContextFormatter on AIContextBuilder {
  String _taskSummary(TaskModel task) => [
        'Title: ${task.title}',
        if (task.description.trim().isNotEmpty)
          'Description: ${task.description}',
        'Status: ${task.status}',
        'Progress: ${task.progress}%',
        if (task.nextStep.trim().isNotEmpty) 'Next Step: ${task.nextStep}',
      ].join('\n');

  String _issueContent(IssueModel issue) => [
        'Status: ${issue.status}',
        'Severity: ${issue.severity}',
        if (issue.impact.trim().isNotEmpty) 'Impact: ${issue.impact}',
        if (issue.hypothesis.trim().isNotEmpty)
          'Hypothesis: ${issue.hypothesis}',
        if (issue.nextInvestigationStep.trim().isNotEmpty)
          'Next Investigation Step: ${issue.nextInvestigationStep}',
        if (issue.resolution.trim().isNotEmpty)
          'Resolution: ${issue.resolution}',
      ].join('\n');

  String _resourceContent(ResourceModel resource) => [
        'Type: ${resource.resourceType}',
        if (resource.description.trim().isNotEmpty) resource.description,
        if (resource.uri.trim().isNotEmpty) resource.uri,
      ].join('\n');

  String _decisionContent(DecisionModel decision) => [
        if (decision.decisionText.trim().isNotEmpty)
          'Decision: ${decision.decisionText}',
        if (decision.rationale.trim().isNotEmpty)
          'Why: ${decision.rationale}',
        if (decision.revisitCondition.trim().isNotEmpty)
          'Revisit When: ${decision.revisitCondition}',
        'Status: ${decision.status}',
      ].join('\n');

  String _knowledgeContent(KnowledgeModel item, String markdown) => [
        if (item.category.trim().isNotEmpty) 'Category: ${item.category}',
        if (item.summary.trim().isNotEmpty) 'Summary: ${item.summary}',
        if (item.useWhen.trim().isNotEmpty) 'Use When: ${item.useWhen}',
        if (markdown.trim().isNotEmpty) markdown,
      ].join('\n\n');

  String _developerProjectContent(DeveloperProjectModel project) => [
        'Project: ${project.name}',
        if (project.localPath.trim().isNotEmpty)
          'Local Path: ${project.localPath}',
        if (project.repositoryUrl.trim().isNotEmpty)
          'Repository: ${project.repositoryUrl}',
        if (project.branch.trim().isNotEmpty) 'Branch: ${project.branch}',
        if (project.techStack.trim().isNotEmpty)
          'Tech Stack: ${project.techStack}',
        if (project.notes.trim().isNotEmpty) 'Notes: ${project.notes}',
        if (project.isPrimary) 'Primary Project: yes',
      ].join('\n');

  String _developerCommandContent(DeveloperCommandModel command) => [
        'Command: ${command.command}',
        'Category: ${command.category}',
        if (command.workingDirectory?.trim().isNotEmpty == true)
          'Working Directory: ${command.workingDirectory}',
        if (command.notes.trim().isNotEmpty) 'Notes: ${command.notes}',
        if (command.isPinned) 'Pinned: yes',
      ].join('\n');

  String _developerSnippetContent(DeveloperSnippetModel snippet) => [
        if (snippet.language.trim().isNotEmpty)
          'Language: ${snippet.language}',
        snippet.content,
        if (snippet.notes.trim().isNotEmpty) 'Notes: ${snippet.notes}',
        if (snippet.isPinned) 'Pinned: yes',
      ].join('\n');
}
