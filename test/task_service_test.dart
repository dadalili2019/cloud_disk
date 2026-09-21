import 'package:cloud_disk/workbench/application/workbench_services.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/domain/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskService', () {
    test('create normalizes input and records task_created activity', () async {
      final tasks = _TaskRepository();
      final activities = _ActivityRepository();
      final service = TaskService(tasks: tasks, activities: activities);

      final task = await service.create(
        workspaceId: 'workspace-1',
        title: '  Finish report  ',
        description: '  draft description  ',
        nextStep: '  review  ',
        priority: 2,
      );

      expect(task.workspaceId, 'workspace-1');
      expect(task.title, 'Finish report');
      expect(task.description, 'draft description');
      expect(task.nextStep, 'review');
      expect(task.status, 'todo');
      expect(task.progress, 0);
      expect(task.priority, 2);
      expect(task.isCurrent, isFalse);

      expect(tasks.inserted, [task]);
      expect(activities.inserted, hasLength(1));
      expect(activities.inserted.single.eventType, 'task_created');
      expect(activities.inserted.single.entityId, task.id);
      expect(activities.inserted.single.summary, 'Finish report');
    });

    test('create rejects empty title without writing data', () async {
      final tasks = _TaskRepository();
      final activities = _ActivityRepository();
      final service = TaskService(tasks: tasks, activities: activities);

      await expectLater(
        service.create(workspaceId: 'workspace-1', title: '   '),
        throwsArgumentError,
      );

      expect(tasks.inserted, isEmpty);
      expect(activities.inserted, isEmpty);
    });

    test('update done forces progress to 100 and clears current', () async {
      final tasks = _TaskRepository();
      final activities = _ActivityRepository();
      final service = TaskService(tasks: tasks, activities: activities);
      final original = _task(isCurrent: true, progress: 40, status: 'doing');

      final updated = await service.update(
        task: original,
        title: '  Finished task  ',
        status: 'done',
        progress: 60,
        nextStep: '  nothing  ',
      );

      expect(updated.title, 'Finished task');
      expect(updated.status, 'done');
      expect(updated.progress, 100);
      expect(updated.isCurrent, isFalse);
      expect(updated.nextStep, 'nothing');

      expect(tasks.updated, [updated]);
      expect(activities.inserted.single.eventType, 'task_completed');
      expect(activities.inserted.single.entityId, original.id);
    });

    test('update validates status and progress before repository write', () async {
      final tasks = _TaskRepository();
      final activities = _ActivityRepository();
      final service = TaskService(tasks: tasks, activities: activities);
      final original = _task();

      await expectLater(
        service.update(
          task: original,
          title: 'Task',
          status: 'invalid',
          progress: 50,
          nextStep: '',
        ),
        throwsArgumentError,
      );
      await expectLater(
        service.update(
          task: original,
          title: 'Task',
          status: 'doing',
          progress: 101,
          nextStep: '',
        ),
        throwsArgumentError,
      );

      expect(tasks.updated, isEmpty);
      expect(activities.inserted, isEmpty);
    });

    test('setCurrent delegates to repository and records activity', () async {
      final task = _task();
      final tasks = _TaskRepository()..byId[task.id] = task;
      final activities = _ActivityRepository();
      final service = TaskService(tasks: tasks, activities: activities);

      await service.setCurrent(task.workspaceId, task.id);

      expect(tasks.setCurrentCalls, [(task.workspaceId, task.id)]);
      expect(activities.inserted, hasLength(1));
      expect(activities.inserted.single.eventType, 'task_set_current');
      expect(activities.inserted.single.summary, task.title);
    });

    test('setCurrent does not create activity when task cannot be loaded', () async {
      final tasks = _TaskRepository();
      final activities = _ActivityRepository();
      final service = TaskService(tasks: tasks, activities: activities);

      await service.setCurrent('workspace-1', 'missing');

      expect(tasks.setCurrentCalls, [('workspace-1', 'missing')]);
      expect(activities.inserted, isEmpty);
    });
  });
}

TaskModel _task({
  bool isCurrent = false,
  int progress = 20,
  String status = 'doing',
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return TaskModel(
    id: 'task-1',
    workspaceId: 'workspace-1',
    title: 'Task',
    description: 'Description',
    status: status,
    progress: progress,
    nextStep: 'Next',
    priority: 1,
    isCurrent: isCurrent,
    createdAt: now,
    updatedAt: now,
  );
}

class _TaskRepository implements TaskRepository {
  final List<TaskModel> inserted = [];
  final List<TaskModel> updated = [];
  final Map<String, TaskModel> byId = {};
  final List<(String, String)> setCurrentCalls = [];

  @override
  Future<List<TaskModel>> listByWorkspace(String workspaceId) async => const [];

  @override
  Future<TaskModel?> getById(String id) async => byId[id];

  @override
  Future<TaskModel?> getCurrent(String workspaceId) async => null;

  @override
  Future<void> insert(TaskModel task) async {
    inserted.add(task);
    byId[task.id] = task;
  }

  @override
  Future<void> update(TaskModel task) async {
    updated.add(task);
    byId[task.id] = task;
  }

  @override
  Future<void> setCurrent(String workspaceId, String taskId) async {
    setCurrentCalls.add((workspaceId, taskId));
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
