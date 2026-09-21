import 'dart:io';

import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:cloud_disk/workbench/data/sqlite_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('SqliteTaskRepository current constraint', () {
    late Directory tempDirectory;
    late WorkbenchDatabase database;
    late SqliteWorkspaceRepository workspaces;
    late SqliteTaskRepository tasks;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'personal_workbench_task_repository_',
      );
      database = await WorkbenchDatabase.open(
        p.join(tempDirectory.path, 'workbench.db'),
      );
      workspaces = SqliteWorkspaceRepository(database);
      tasks = SqliteTaskRepository(database);
      await workspaces.insert(_workspace());
    });

    tearDown(() async {
      await database.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('database unique index rejects two current tasks in one workspace', () async {
      final first = _task(id: 'task-1', isCurrent: true, status: 'doing');
      final second = _task(id: 'task-2', isCurrent: true, status: 'doing');

      await tasks.insert(first);

      await expectLater(
        tasks.insert(second),
        throwsA(anything),
      );

      final current = await tasks.getCurrent('workspace-1');
      expect(current?.id, first.id);
    });

    test('different workspaces can each have one current task', () async {
      await workspaces.insert(
        _workspace(id: 'workspace-2', slug: 'workspace-2'),
      );

      await tasks.insert(
        _task(id: 'task-1', isCurrent: true, status: 'doing'),
      );
      await tasks.insert(
        _task(
          id: 'task-2',
          workspaceId: 'workspace-2',
          isCurrent: true,
          status: 'doing',
        ),
      );

      expect((await tasks.getCurrent('workspace-1'))?.id, 'task-1');
      expect((await tasks.getCurrent('workspace-2'))?.id, 'task-2');
    });

    test('setCurrent switches atomically and promotes todo to doing', () async {
      await tasks.insert(
        _task(id: 'task-1', isCurrent: true, status: 'doing'),
      );
      await tasks.insert(
        _task(id: 'task-2', isCurrent: false, status: 'todo'),
      );

      await tasks.setCurrent('workspace-1', 'task-2');

      final first = await tasks.getById('task-1');
      final second = await tasks.getById('task-2');
      expect(first?.isCurrent, isFalse);
      expect(second?.isCurrent, isTrue);
      expect(second?.status, 'doing');
      expect((await tasks.getCurrent('workspace-1'))?.id, 'task-2');
    });

    test('failed setCurrent rolls transaction back to previous current task', () async {
      await tasks.insert(
        _task(id: 'task-1', isCurrent: true, status: 'doing'),
      );

      await expectLater(
        tasks.setCurrent('workspace-1', 'missing'),
        throwsA(isA<StateError>()),
      );

      final current = await tasks.getCurrent('workspace-1');
      expect(current?.id, 'task-1');
      expect((await tasks.getById('task-1'))?.isCurrent, isTrue);
    });

    test('completed task cannot become current and previous current remains', () async {
      await tasks.insert(
        _task(id: 'task-1', isCurrent: true, status: 'doing'),
      );
      await tasks.insert(
        _task(id: 'task-2', isCurrent: false, status: 'done', progress: 100),
      );

      await expectLater(
        tasks.setCurrent('workspace-1', 'task-2'),
        throwsA(isA<StateError>()),
      );

      expect((await tasks.getCurrent('workspace-1'))?.id, 'task-1');
      expect((await tasks.getById('task-2'))?.isCurrent, isFalse);
    });

    test('getCurrent normalizes legacy completed current task', () async {
      await tasks.insert(
        _task(id: 'task-1', isCurrent: false, status: 'doing'),
      );
      await database.update(
        '''
UPDATE tasks
SET status = 'done', progress = 100, is_current = 1
WHERE id = ?
''',
        ['task-1'],
      );

      expect(await tasks.getCurrent('workspace-1'), isNull);
      expect((await tasks.getById('task-1'))?.isCurrent, isFalse);
    });
  });
}

WorkspaceModel _workspace({
  String id = 'workspace-1',
  String slug = 'workspace-1',
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return WorkspaceModel(
    id: id,
    name: id,
    slug: slug,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

TaskModel _task({
  required String id,
  String workspaceId = 'workspace-1',
  bool isCurrent = false,
  String status = 'todo',
  int progress = 0,
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return TaskModel(
    id: id,
    workspaceId: workspaceId,
    title: id,
    description: '',
    status: status,
    progress: progress,
    nextStep: '',
    priority: 0,
    isCurrent: isCurrent,
    createdAt: now,
    updatedAt: now,
  );
}
