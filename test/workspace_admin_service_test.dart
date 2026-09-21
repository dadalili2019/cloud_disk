import 'package:cloud_disk/workbench/application/workspace_admin_service.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/domain/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceAdminService', () {
    test('rename trims name, preserves identity and records activity', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceAdminService(
        workspaces: workspaces,
        activities: activities,
      );
      final original = _workspace();

      final updated = await service.rename(
        workspace: original,
        name: '  Renamed Workspace  ',
      );

      expect(updated.id, original.id);
      expect(updated.slug, original.slug);
      expect(updated.status, original.status);
      expect(updated.name, 'Renamed Workspace');
      expect(workspaces.updated, [updated]);

      expect(activities.inserted, hasLength(1));
      expect(activities.inserted.single.eventType, 'workspace_renamed');
      expect(activities.inserted.single.summary, 'Renamed Workspace');
    });

    test('rename rejects empty name before repository write', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceAdminService(
        workspaces: workspaces,
        activities: activities,
      );

      await expectLater(
        service.rename(workspace: _workspace(), name: '   '),
        throwsArgumentError,
      );

      expect(workspaces.updated, isEmpty);
      expect(activities.inserted, isEmpty);
    });

    test('archive marks workspace archived and records activity', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceAdminService(
        workspaces: workspaces,
        activities: activities,
      );
      final original = _workspace();

      final archived = await service.archive(original);

      expect(archived.status, 'archived');
      expect(archived.archivedAt, isNotNull);
      expect(archived.id, original.id);
      expect(workspaces.updated, [archived]);
      expect(activities.inserted.single.eventType, 'workspace_archived');
      expect(activities.inserted.single.summary, original.name);
    });

    test('restore marks workspace active and clears archivedAt', () async {
      final workspaces = _WorkspaceRepository();
      final activities = _ActivityRepository();
      final service = WorkspaceAdminService(
        workspaces: workspaces,
        activities: activities,
      );
      final original = _workspace(
        status: 'archived',
        archivedAt: DateTime.utc(2026, 9, 20),
      );

      final restored = await service.restore(original);

      expect(restored.status, 'active');
      expect(restored.archivedAt, isNull);
      expect(restored.id, original.id);
      expect(workspaces.updated, [restored]);
      expect(activities.inserted.single.eventType, 'workspace_restored');
      expect(activities.inserted.single.summary, original.name);
    });
  });
}

WorkspaceModel _workspace({
  String status = 'active',
  DateTime? archivedAt,
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return WorkspaceModel(
    id: 'workspace-1',
    name: 'Workbench',
    slug: 'workbench',
    status: status,
    createdAt: now,
    updatedAt: now,
    archivedAt: archivedAt,
  );
}

class _WorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceModel> inserted = [];
  final List<WorkspaceModel> updated = [];

  @override
  Future<List<WorkspaceModel>> listActive() async => const [];

  @override
  Future<List<WorkspaceModel>> listArchived() async => const [];

  @override
  Future<WorkspaceModel?> getById(String id) async => null;

  @override
  Future<WorkspaceModel?> getBySlug(String slug) async => null;

  @override
  Future<void> insert(WorkspaceModel workspace) async {
    inserted.add(workspace);
  }

  @override
  Future<void> update(WorkspaceModel workspace) async {
    updated.add(workspace);
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
