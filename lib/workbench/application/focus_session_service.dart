import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/repositories.dart';

class TodayFocusSnapshot {
  const TodayFocusSnapshot({
    required this.active,
    required this.sessions,
    required this.totalSeconds,
  });

  final FocusSessionModel? active;
  final List<FocusSessionModel> sessions;
  final int totalSeconds;
}

class FocusSessionService {
  const FocusSessionService({
    required this.sessions,
    required this.workspaces,
    required this.tasks,
    required this.activities,
  });

  final FocusSessionRepository sessions;
  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final ActivityRepository activities;

  Future<FocusSessionModel?> getActive() => sessions.getActive();

  Future<FocusSessionModel> start({
    required String workspaceId,
    required String taskId,
  }) async {
    final existing = await sessions.getActive();
    if (existing != null) {
      throw StateError('已有进行中的专注会话，请先结束当前专注。');
    }

    final workspace = await workspaces.getById(workspaceId);
    if (workspace == null || workspace.status != 'active') {
      throw StateError('工作区不存在或已归档。');
    }

    final task = await tasks.getById(taskId);
    if (task == null || task.workspaceId != workspaceId || task.status == 'done') {
      throw StateError('任务不存在或已完成，无法开始专注。');
    }

    final now = DateTime.now().toUtc();
    final session = FocusSessionModel(
      id: newWorkbenchId(),
      workspaceId: workspaceId,
      taskId: taskId,
      startedAt: now,
      durationSeconds: 0,
      note: '',
      createdAt: now,
    );

    await sessions.insert(session);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspaceId,
        entityType: 'focus_session',
        entityId: session.id,
        eventType: 'focus_started',
        summary: task.title,
        createdAt: now,
      ),
    );
    return session;
  }

  Future<void> finish({String note = ''}) async {
    final active = await sessions.getActive();
    if (active == null) {
      throw StateError('当前没有进行中的专注会话。');
    }

    final endedAt = DateTime.now().toUtc();
    final duration = endedAt.difference(active.startedAt.toUtc()).inSeconds;
    final safeDuration = duration < 0 ? 0 : duration;
    await sessions.finish(
      id: active.id,
      endedAt: endedAt,
      durationSeconds: safeDuration,
      note: note,
    );

    final task = await tasks.getById(active.taskId);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: active.workspaceId,
        entityType: 'focus_session',
        entityId: active.id,
        eventType: 'focus_finished',
        summary: task?.title ?? '专注结束',
        createdAt: endedAt,
      ),
    );
  }

  Future<TodayFocusSnapshot> loadToday() async {
    final now = DateTime.now();
    final startLocal = DateTime(now.year, now.month, now.day);
    final endLocal = startLocal.add(const Duration(days: 1));
    final today = await sessions.listBetween(startLocal, endLocal);
    final active = await sessions.getActive();

    var total = 0;
    final nowUtc = DateTime.now().toUtc();
    for (final session in today) {
      if (session.endedAt != null) {
        total += session.durationSeconds;
      } else {
        final running = nowUtc.difference(session.startedAt.toUtc()).inSeconds;
        if (running > 0) total += running;
      }
    }

    return TodayFocusSnapshot(
      active: active,
      sessions: today,
      totalSeconds: total,
    );
  }
}
