import 'focus_session_service.dart';

class TodaySnapshot {
  const TodaySnapshot({
    required this.focus,
    required this.workspaceCount,
    required this.completedSessionCount,
  });

  final TodayFocusSnapshot focus;
  final int workspaceCount;
  final int completedSessionCount;
}

class TodayService {
  const TodayService({required this.focusSessions});

  final FocusSessionService focusSessions;

  Future<TodaySnapshot> load() async {
    final focus = await focusSessions.loadToday();
    final workspaceIds = <String>{};
    var completed = 0;

    for (final entry in focus.sessions) {
      workspaceIds.add(entry.session.workspaceId);
      if (entry.session.endedAt != null) completed++;
    }

    return TodaySnapshot(
      focus: focus,
      workspaceCount: workspaceIds.length,
      completedSessionCount: completed,
    );
  }
}
