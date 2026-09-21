import 'dart:async';

import 'package:cloud_disk/workbench/application/notes_editor_save_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotesEditorSaveCoordinator', () {
    test('reset starts from a clean state', () {
      final coordinator = NotesEditorSaveCoordinator();

      coordinator.markEdited();
      expect(coordinator.dirty, isTrue);

      coordinator.reset();

      expect(coordinator.dirty, isFalse);
      expect(coordinator.saving, isFalse);
    });

    test('manual flush keeps edits made while save is in flight dirty', () async {
      final coordinator = NotesEditorSaveCoordinator();
      final firstSave = Completer<void>();
      final revisions = <int>[];

      coordinator.markEdited();
      final flush = coordinator.flush(
        persist: (revision) async {
          revisions.add(revision);
          await firstSave.future;
        },
        repeatWhileDirty: false,
      );

      await Future<void>.delayed(Duration.zero);
      expect(coordinator.saving, isTrue);

      coordinator.markEdited();
      firstSave.complete();
      await flush;

      expect(revisions, [1]);
      expect(coordinator.saving, isFalse);
      expect(coordinator.dirty, isTrue);
    });

    test('auto-save flush serializes and persists the latest revision', () async {
      final coordinator = NotesEditorSaveCoordinator();
      final firstSave = Completer<void>();
      final revisions = <int>[];

      coordinator.markEdited();
      final flush = coordinator.flush(
        persist: (revision) async {
          revisions.add(revision);
          if (revision == 1) {
            await firstSave.future;
          }
        },
        repeatWhileDirty: true,
      );

      await Future<void>.delayed(Duration.zero);
      coordinator.markEdited();
      firstSave.complete();
      await flush;

      expect(revisions, [1, 2]);
      expect(coordinator.saving, isFalse);
      expect(coordinator.dirty, isFalse);
    });

    test('failed persistence leaves the latest revision dirty', () async {
      final coordinator = NotesEditorSaveCoordinator();
      coordinator.markEdited();

      await expectLater(
        coordinator.flush(
          persist: (_) => Future<void>.error(StateError('write failed')),
          repeatWhileDirty: true,
        ),
        throwsStateError,
      );

      expect(coordinator.saving, isFalse);
      expect(coordinator.dirty, isTrue);
    });
  });
}
