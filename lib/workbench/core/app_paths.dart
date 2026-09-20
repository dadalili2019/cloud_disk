import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  AppPaths._(this.root);

  final Directory root;

  static Future<AppPaths> create() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return createAt(
      Directory(p.join(supportDirectory.path, 'PersonalWorkbench')),
    );
  }

  static Future<AppPaths> createAt(Directory root) async {
    final paths = AppPaths._(root);
    await paths.ensureBaseDirectories();
    return paths;
  }

  Directory get dataDirectory => Directory(p.join(root.path, 'data'));
  Directory get workspacesDirectory =>
      Directory(p.join(root.path, 'workspaces'));
  Directory get knowledgeDirectory => Directory(p.join(root.path, 'knowledge'));
  Directory get attachmentsDirectory =>
      Directory(p.join(root.path, 'attachments'));
  Directory get backupsDirectory => Directory(p.join(root.path, 'backups'));
  Directory get exportsDirectory => Directory(p.join(root.path, 'exports'));

  String get databasePath => p.join(dataDirectory.path, 'workbench.db');

  Directory workspaceDirectory(String workspaceSlug) =>
      Directory(p.join(workspacesDirectory.path, workspaceSlug));

  Directory workspaceNotesDirectory(String workspaceSlug) =>
      Directory(p.join(workspaceDirectory(workspaceSlug).path, 'notes'));

  Directory workspaceAttachmentsDirectory(String workspaceSlug) => Directory(
        p.join(workspaceDirectory(workspaceSlug).path, 'attachments'),
      );

  Future<void> ensureBaseDirectories() async {
    await Future.wait([
      dataDirectory.create(recursive: true),
      workspacesDirectory.create(recursive: true),
      knowledgeDirectory.create(recursive: true),
      attachmentsDirectory.create(recursive: true),
      backupsDirectory.create(recursive: true),
      exportsDirectory.create(recursive: true),
    ]);
  }

  Future<void> ensureWorkspaceDirectories(String workspaceSlug) async {
    await Future.wait([
      workspaceNotesDirectory(workspaceSlug).create(recursive: true),
      workspaceAttachmentsDirectory(workspaceSlug).create(recursive: true),
    ]);
  }

  String workspaceNoteRelativePath(String workspaceSlug, String fileName) {
    return p.posix.join('workspaces', workspaceSlug, 'notes', fileName);
  }

  String knowledgeRelativePath(String fileName) {
    return p.posix.join('knowledge', fileName);
  }

  String resolveRelative(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    return p.joinAll([root.path, ...p.posix.split(normalized)]);
  }

  String relativeToRoot(String absolutePath) {
    return p.relative(absolutePath, from: root.path).replaceAll('\\', '/');
  }
}
