class NotesEditorSaveCoordinator {
  int _revision = 0;
  int _savedRevision = 0;
  Future<void>? _inFlight;

  bool get dirty => _revision > _savedRevision;
  bool get saving => _inFlight != null;

  void markEdited() {
    _revision += 1;
  }

  void reset() {
    _revision = 0;
    _savedRevision = 0;
  }

  Future<void> flush({
    required Future<void> Function(int revision) persist,
    required bool repeatWhileDirty,
  }) async {
    final current = _inFlight;
    if (current != null) {
      await current;
      if (dirty) {
        await flush(
          persist: persist,
          repeatWhileDirty: repeatWhileDirty,
        );
      }
      return;
    }

    if (!dirty) return;

    late final Future<void> operation;
    operation = _run(
      persist: persist,
      repeatWhileDirty: repeatWhileDirty,
    );
    _inFlight = operation;

    try {
      await operation;
    } finally {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _run({
    required Future<void> Function(int revision) persist,
    required bool repeatWhileDirty,
  }) async {
    do {
      final revision = _revision;
      await persist(revision);
      if (revision > _savedRevision) {
        _savedRevision = revision;
      }
      if (!repeatWhileDirty) return;
    } while (dirty);
  }
}
