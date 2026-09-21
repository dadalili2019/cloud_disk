import 'dart:io';

import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:cloud_disk/workbench/data/sqlite_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('SqliteTaskRepository current task constraint', () {
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

      final now = DateTime.utc(2026, 9, 21, 9);
      await workspaces.insert(
        WorkspaceModel(
          id: 'workspace-1',
          name: 'Workspace',
          slug: 'workspace',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await database.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('database unique index rejects two current tasks in one workspace', () async {
      await tasks.insert(_task(id: 'task-1', isCurrent: true));

      await expectLater(
        tasks.insert(_task(id: 'task-2', isCurrent: true)),
        throwsA(anything),
      );

      final current = await tasks.getCurrent('workspace-1');
      expect(current?.id, 'task-1');
    });

    test('setCurrent switches current task and promotes todo to doing', () async {
      await tasks.insert(_task(id: 'task-1', isCurrent: true));
      await tasks.insert(_task(id: 'task-2', status: 'todo'));

      await tasks.setCurrent('workspace-1', 'task-2');

      final current = await tasks.getCurrent('workspace-1');
      expect(current?.id, 'task-2');
      expect(current?.status, 'doing');

      final first = await tasks.getById('task-1');
      expect(first?.isCurrent, isFalse);
    });

    test('failed setCurrent rolls transaction back to previous current task', () async {
      await tasks.insert(_task(id: 'task-1', isCurrent: true));

      await expectLater(
        tasks.setCurrent('workspace-1', 'missing'),
        throwsA(isA<StateError>()),
      );

      final current = await tasks.getCurrent('workspace-1');
      expect(current?.id, 'task-1');
      expect(current?.isCurrent, isTrue);
    });

    test('completed task cannot become current', () async {
      await tasks.insert(_task(id: 'task-1', isCurrent: true));
      await tasks.insert(_task(id: 'task-2', status: 'done', progress: 100));

      await expectLater(
        tasks.setCurrent('workspace-1', 'task-2'),
        throwsA(isA<StateError>()),
      );

      final current = await tasks.getCurrent('workspace-1');
      expect(current?.id, 'task-1');
    });

    test('getCurrent normalizes completed current rows', () async {
      await tasks.insert(_task(id: 'task-1', isCurrent: true));
      await database.update(
        "UPDATE tasks SET status = 'done', progress = 100 WHERE id = ?",
        ['task-1'],
      );

      final current = await tasks.getCurrent('workspace-1');
      final stored = await tasks.getById('task-1');

      expect(current, isNull);
      expect(stored?.isCurrent, isFalse);
      expect(stored?.status, 'done');
    });
  });
}

TaskModel _task({
  required String id,
  String status = 'doing',
  int progress = 20,
  bool isCurrent = false,
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return TaskModel(
    id: id,
    workspaceId: 'workspace-1',
    title: id,
    description: '',
    status: status,
    progress: progress,
    nextStep: '',
    priority: 1,
    isCurrent: isCurrent,
    createdAt: now,
    updatedAt: now,
  );
}
