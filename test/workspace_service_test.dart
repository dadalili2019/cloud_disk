import 'dart:io';

import 'package:cloud_disk/workbench/application/workbench_services.dart';
import 'package:cloud_disk/workbench/core/app_paths.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/domain/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('WorkspaceService', () {
    late Directory tempDirectory;
    late AppPaths paths;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'personal_workbench_workspace_service_',
      );
      paths = await AppPaths.createAt(
        Directory(p.join(tempDirectory.path, 'app')),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('create normalizes name and slug, creates folders and activity', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceService(
        paths: paths,
        workspaces: workspaces,
        activities: activities,
      );

      final workspace = await service.create(
        name: '  我的 Demo 项目  ',
      );

      expect(workspace.name, '我的 Demo 项目');
      expect(workspace.slug, '我的-demo-项目');
      expect(workspace.status, 'active');

      expect(workspaces.inserted, [workspace]);
      expect(activities.inserted, hasLength(1));
      expect(activities.inserted.single.eventType, 'workspace_created');
      expect(activities.inserted.single.entityId, workspace.id);

      final notesDirectory = Directory(
        p.join(paths.workspacesDirectory.path, workspace.slug, 'notes'),
      );
      expect(await notesDirectory.exists(), isTrue);
    });

    test('create uses explicit slug after normalization', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceService(
        paths: paths,
        workspaces: workspaces,
        activities: activities,
      );

      final workspace = await service.create(
        name: 'Workbench',
        slug: '  My Workspace  ',
      );

      expect(workspace.slug, 'my-workspace');
    });

    test('create rejects empty name without writing data', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceService(
        paths: paths,
        workspaces: workspaces,
        activities: activities,
      );

      await expectLater(
        service.create(name: '   '),
        throwsArgumentError,
      );

      expect(workspaces.inserted, isEmpty);
      expect(activities.inserted, isEmpty);
    });

    test('create rejects duplicate slug before creating a second workspace', () async {
      final existing = _workspace(slug: 'workbench');
      final workspaces = _WorkspaceRepository()
        ..bySlug[existing.slug] = existing;
      final activities = _ActivityRepository();
      final service = WorkspaceService(
        paths: paths,
        workspaces: workspaces,
        activities: activities,
      );

      await expectLater(
        service.create(name: 'Workbench'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Workspace slug already exists'),
          ),
        ),
      );

      expect(workspaces.inserted, isEmpty);
      expect(activities.inserted, isEmpty);
    });
  });
}

WorkspaceModel _workspace({
  String slug = 'workbench',
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return WorkspaceModel(
    id: 'workspace-existing',
    name: 'Existing',
    slug: slug,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

class _WorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceModel> inserted = [];
  final Map<String, WorkspaceModel> bySlug = {};

  @override
  Future<List<WorkspaceModel>> listActive() async => inserted;

  @override
  Future<List<WorkspaceModel>> listArchived() async => const [];

  @override
  Future<WorkspaceModel?> getById(String id) async {
    for (final workspace in inserted) {
      if (workspace.id == id) return workspace;
    }
    return null;
  }

  @override
  Future<WorkspaceModel?> getBySlug(String slug) async => bySlug[slug];

  @override
  Future<void> insert(WorkspaceModel workspace) async {
    inserted.add(workspace);
    bySlug[workspace.slug] = workspace;
  }

  @override
  Future<void> update(WorkspaceModel workspace) async {
    throw StateError('update is not expected in WorkspaceService.create tests');
  }
}

class _ActivityRepository implements ActivityRepository {
  final List<ActivityEventModel> inserted = [];

  @override
  Future<void> insert(ActivityEventModel event) async {
    inserted.add(event);
  }

  @override
  Future<List<ActivityEventModel>> listRecent(
    String workspaceId, {
    int limit = 10,
  }) async => const [];
}
