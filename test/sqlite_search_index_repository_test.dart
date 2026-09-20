import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:cloud_disk/workbench/data/sqlite_search_index_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SqliteSearchIndexRepository', () {
    test('empty query returns without touching database', () async {
      final db = _FakeSqlExecutor();
      final repository = SqliteSearchIndexRepository(db);

      final result = await repository.search('   ');

      expect(result, isEmpty);
      expect(db.selectCalls, isEmpty);
    });

    test('merges FTS and LIKE results without duplicating entities', () async {
      final db = _FakeSqlExecutor(
        onSelect: (statement, args, callIndex) async {
          if (callIndex == 0) {
            return [
              _row(
                entityType: 'task',
                entityId: 'task-1',
                title: 'Alpha',
                snippet: '[Alpha] from FTS',
                score: 3,
              ),
            ];
          }
          return [
            _row(
              entityType: 'task',
              entityId: 'task-1',
              title: 'Alpha',
              snippet: 'Alpha from LIKE',
              score: 2,
            ),
            _row(
              entityType: 'note',
              entityId: 'note-1',
              title: 'Alpha note',
              snippet: 'substring result',
              score: 1,
            ),
          ];
        },
      );
      final repository = SqliteSearchIndexRepository(db);

      final result = await repository.search('Alpha');

      expect(result, hasLength(2));
      expect(result[0].entityId, 'task-1');
      expect(result[0].snippet, '[Alpha] from FTS');
      expect(result[1].entityId, 'note-1');
      expect(db.selectCalls, hasLength(2));
    });

    test('falls back to LIKE when FTS query fails', () async {
      final db = _FakeSqlExecutor(
        onSelect: (statement, args, callIndex) async {
          if (callIndex == 0) {
            throw StateError('fts parser rejected query');
          }
          return [
            _row(
              entityType: 'knowledge',
              entityId: 'knowledge-1',
              title: '故障排查',
              snippet: 'LIKE fallback',
              score: 2,
            ),
          ];
        },
      );
      final repository = SqliteSearchIndexRepository(db);

      final result = await repository.search('故障+排查');

      expect(result, hasLength(1));
      expect(result.single.entityType, 'knowledge');
      expect(result.single.entityId, 'knowledge-1');
      expect(db.selectCalls, hasLength(2));
    });

    test('applies filters, escapes LIKE query and clamps limit', () async {
      final db = _FakeSqlExecutor();
      final repository = SqliteSearchIndexRepository(db);

      await repository.search(
        '100%_\\',
        entityTypes: {'task', 'note'},
        workspaceId: ' workspace-1 ',
        limit: 500,
      );

      expect(db.selectCalls, hasLength(2));

      final fts = db.selectCalls.first;
      expect(fts.statement, contains('entity_type IN (?, ?)'));
      expect(fts.statement, contains('workspace_id = ?'));
      expect(fts.args.last, 100);
      expect(fts.args, contains('workspace-1'));

      final like = db.selectCalls.last;
      expect(like.args.take(3), everyElement(r'%100\%\_\\%'));
      expect(like.args.last, 100);
      expect(like.args, contains('workspace-1'));
    });

    test('replace removes old row before inserting replacement', () async {
      final db = _FakeSqlExecutor();
      final repository = SqliteSearchIndexRepository(db);

      await repository.replace(
        entityType: 'task',
        entityId: 'task-1',
        workspaceId: 'workspace-1',
        title: 'Title',
        body: 'Body',
      );

      expect(db.operations, ['delete', 'insert']);
      expect(db.deleteCalls.single.args, ['task', 'task-1']);
      expect(
        db.insertCalls.single.args,
        ['task', 'task-1', 'workspace-1', 'Title', 'Body'],
      );
    });
  });
}

Map<String, Object?> _row({
  required String entityType,
  required String entityId,
  required String title,
  required String snippet,
  required num score,
  String workspaceId = '',
}) {
  return {
    'entity_type': entityType,
    'entity_id': entityId,
    'workspace_id': workspaceId,
    'title': title,
    'snippet': snippet,
    'score': score,
  };
}

typedef _SelectHandler = Future<List<Map<String, Object?>>> Function(
  String statement,
  List<Object?> args,
  int callIndex,
);

class _SqlCall {
  const _SqlCall(this.statement, this.args);

  final String statement;
  final List<Object?> args;
}

class _FakeSqlExecutor implements WorkbenchSqlExecutor {
  _FakeSqlExecutor({this.onSelect});

  final _SelectHandler? onSelect;

  final List<_SqlCall> selectCalls = [];
  final List<_SqlCall> insertCalls = [];
  final List<_SqlCall> updateCalls = [];
  final List<_SqlCall> deleteCalls = [];
  final List<_SqlCall> customCalls = [];
  final List<String> operations = [];

  @override
  Future<List<Map<String, Object?>>> select(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    final callIndex = selectCalls.length;
    selectCalls.add(_SqlCall(statement, List<Object?>.from(args)));
    if (onSelect != null) {
      return onSelect!(statement, args, callIndex);
    }
    return const <Map<String, Object?>>[];
  }

  @override
  Future<int> insert(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    operations.add('insert');
    insertCalls.add(_SqlCall(statement, List<Object?>.from(args)));
    return 1;
  }

  @override
  Future<int> update(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    operations.add('update');
    updateCalls.add(_SqlCall(statement, List<Object?>.from(args)));
    return 1;
  }

  @override
  Future<int> delete(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    operations.add('delete');
    deleteCalls.add(_SqlCall(statement, List<Object?>.from(args)));
    return 1;
  }

  @override
  Future<void> custom(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    operations.add('custom');
    customCalls.add(_SqlCall(statement, List<Object?>.from(args)));
  }
}
