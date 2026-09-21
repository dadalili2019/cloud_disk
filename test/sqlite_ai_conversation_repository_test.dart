import 'dart:io';

import 'package:cloud_disk/workbench/core/ai_context_models.dart';
import 'package:cloud_disk/workbench/core/ai_conversation_models.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:cloud_disk/workbench/data/sqlite_ai_conversation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('SQLite AI conversation persistence', () {
    WorkbenchDatabase? database;
    Directory? tempDirectory;

    tearDown(() async {
      await database?.close();
      database = null;
      final directory = tempDirectory;
      tempDirectory = null;
      if (directory != null) {
        await _deleteDirectoryWithRetry(directory);
      }
    });

    test('thread and messages survive database reopen', () async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'personal_workbench_ai_conversation_',
      );
      final databasePath = p.join(tempDirectory!.path, 'workbench.db');

      database = await WorkbenchDatabase.openFileForTesting(
        databasePath,
        targetSchemaVersion: 5,
      );
      var threads = SqliteAIThreadRepository(database!);
      var messages = SqliteAIMessageRepository(database!);

      final now = DateTime.utc(2026, 9, 21, 9);
      final thread = AIThreadModel(
        id: 'thread-1',
        scope: AIContextScope.global,
        title: 'Persistent Thread',
        createdAt: now,
        updatedAt: now,
      );
      await threads.insert(thread);
      await messages.insert(
        AIMessageModel(
          id: 'message-1',
          threadId: thread.id,
          role: 'user',
          content: 'Question',
          contextSnapshotJson: '',
          createdAt: now,
        ),
      );
      await messages.insert(
        AIMessageModel(
          id: 'message-2',
          threadId: thread.id,
          role: 'assistant',
          content: 'Answer',
          contextSnapshotJson: '{"scope":"global","entities":[]}',
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      );

      await database!.close();
      database = null;

      database = await WorkbenchDatabase.openFileForTesting(
        databasePath,
        targetSchemaVersion: 5,
      );
      threads = SqliteAIThreadRepository(database!);
      messages = SqliteAIMessageRepository(database!);

      final restoredThread = await threads.getById('thread-1');
      final restoredMessages = await messages.listByThread('thread-1');

      expect(restoredThread, isNotNull);
      expect(restoredThread!.title, 'Persistent Thread');
      expect(restoredThread.scope, AIContextScope.global);
      expect(restoredMessages.map((message) => message.role), [
        'user',
        'assistant',
      ]);
      expect(restoredMessages.map((message) => message.content), [
        'Question',
        'Answer',
      ]);
      expect(
        restoredMessages.last.contextSnapshotJson,
        '{"scope":"global","entities":[]}',
      );
    });

    test('archived thread is excluded from active list but history remains', () async {
      database = await WorkbenchDatabase.openInMemoryForTesting(
        targetSchemaVersion: 5,
      );
      final threads = SqliteAIThreadRepository(database!);
      final messages = SqliteAIMessageRepository(database!);

      final now = DateTime.utc(2026, 9, 21, 9);
      final thread = AIThreadModel(
        id: 'thread-1',
        scope: AIContextScope.global,
        title: 'Archive Me',
        createdAt: now,
        updatedAt: now,
      );
      await threads.insert(thread);
      await messages.insert(
        AIMessageModel(
          id: 'message-1',
          threadId: thread.id,
          role: 'user',
          content: 'Keep history',
          contextSnapshotJson: '',
          createdAt: now,
        ),
      );
      await threads.update(
        AIThreadModel(
          id: thread.id,
          scope: thread.scope,
          title: thread.title,
          createdAt: thread.createdAt,
          updatedAt: now.add(const Duration(minutes: 1)),
          archivedAt: now.add(const Duration(minutes: 1)),
        ),
      );

      expect(await threads.listActive(), isEmpty);
      expect(
        (await messages.listByThread(thread.id)).single.content,
        'Keep history',
      );
    });

    test('messages are returned in chronological order', () async {
      database = await WorkbenchDatabase.openInMemoryForTesting(
        targetSchemaVersion: 5,
      );
      final threads = SqliteAIThreadRepository(database!);
      final messages = SqliteAIMessageRepository(database!);

      final now = DateTime.utc(2026, 9, 21, 9);
      final thread = AIThreadModel(
        id: 'thread-1',
        scope: AIContextScope.global,
        title: 'Ordered',
        createdAt: now,
        updatedAt: now,
      );
      await threads.insert(thread);

      await messages.insert(
        AIMessageModel(
          id: 'message-later',
          threadId: thread.id,
          role: 'assistant',
          content: 'Later',
          contextSnapshotJson: '',
          createdAt: now.add(const Duration(seconds: 2)),
        ),
      );
      await messages.insert(
        AIMessageModel(
          id: 'message-earlier',
          threadId: thread.id,
          role: 'user',
          content: 'Earlier',
          contextSnapshotJson: '',
          createdAt: now.add(const Duration(seconds: 1)),
        ),
      );

      expect(
        (await messages.listByThread(thread.id))
            .map((message) => message.content),
        ['Earlier', 'Later'],
      );
    });
  });
}

Future<void> _deleteDirectoryWithRetry(
  Directory directory, {
  int maxAttempts = 10,
  Duration retryDelay = const Duration(milliseconds: 100),
}) async {
  PathAccessException? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    if (!await directory.exists()) return;
    try {
      await directory.delete(recursive: true);
      return;
    } on PathAccessException catch (error) {
      lastError = error;
      if (attempt < maxAttempts) {
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  if (Platform.isWindows &&
      lastError != null &&
      lastError.osError?.errorCode == 32) {
    return;
  }
  if (lastError != null) throw lastError;
}
