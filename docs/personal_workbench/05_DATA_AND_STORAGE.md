# Personal Workbench 数据与存储

## 1. 数据根目录

运行时使用 path_provider 获取 Application Support Directory，然后创建：

~~~text
PersonalWorkbench/
├─ data/
│  └─ workbench.db
├─ workspaces/
│  └─ <workspace-slug>/
│     ├─ notes/
│     └─ attachments/
├─ knowledge/
├─ attachments/
├─ backups/
└─ exports/
~~~

## 2. 数据库

当前：

~~~text
schemaVersion = 6
~~~

核心表：

- workspaces
- tasks
- notes
- entity_links
- activity_events
- issues
- resources
- decisions
- focus_sessions
- knowledge
- ai_threads
- ai_messages
- developer_projects
- developer_commands
- developer_snippets

FTS5 Virtual Table：

- search_index

## 3. Workspace

workspace 状态：

- active
- archived

Archive 为逻辑归档，不直接删除数据。

## 4. Task

一个 Workspace 只允许一个 Current Task。

数据库通过部分唯一索引约束：

~~~text
workspace_id + is_current
where is_current = 1 and archived_at is null
~~~

## 5. Markdown

### Note

SQLite 保存：

- id
- workspace_id
- title
- file_path
- pinned
- timestamps

正文保存在：

~~~text
workspaces/<slug>/notes/*.md
~~~

### Knowledge

正文保存在：

~~~text
knowledge/*.md
~~~

## 6. Entity Links

统一关系表用于保存：

- Note → Task
- Knowledge → Source
- Knowledge → Task
- 其他跨实体关系

常用 relation_type：

- linked_to
- derived_from
- applies_to

## 7. Activity Events

记录重要动作，用于：

- Home Recent Activity
- Workspace Overview
- Continue Context

## 8. Search Index

search_index 是派生数据。

字段包含：

- entity_type
- entity_id
- workspace_id
- title
- body

原则：

> Search Index 可以清空并从业务数据重建，因此不属于唯一数据源。

完整重建现在采用：

~~~text
业务数据并发读取
→ 组装 SearchIndexEntry
→ SearchIndexRepository.rebuild(entries)
→ transaction
→ clear once
→ 每 100 条批量 INSERT
~~~

增量更新仍然使用单条 replace / remove；完整 rebuild 不再对每条记录执行 delete + insert。

## 9. Settings

Workbench 非敏感设置使用 SharedPreferences：

- General
- Notes
- AI non-secret settings
- Backup

Appearance 由 ThemeController 独立持久化。

Session API Key 不写入：

- SQLite
- SharedPreferences
- Backup
- Export

## 10. Backup

Backup 应覆盖：

- SQLite 一致性快照
- Notes Markdown
- Knowledge Markdown
- Attachments
- 非敏感 Settings
- Manifest

类型：

- manual
- auto
- safety

## 11. Export

Export 是 Portable Data，不等价于 Backup。

它面向用户读取或迁移，不承诺可以 Restore。

## 12. Restore

Restore 现在把“备份包校验”和“真正恢复”分开：

~~~text
BackupArchiveValidator
  ├─ ZIP decode
  ├─ archive path safety
  ├─ manifest
  ├─ format_version
  └─ schema compatibility

RestoreService
  ├─ validate
  ├─ safety backup
  ├─ stage .pending_restore
  ├─ settings preflight / sanitize
  └─ next-start apply
~~~

这样路径穿越、损坏 ZIP、未来 Schema 等安全边界可以单独自动化测试，不需要真正覆盖用户数据。

Pending Restore 存放在：

~~~text
PersonalWorkbench/.pending_restore/
~~~

只有在下一次 Runtime 初始化、数据库打开之前应用。

Apply 前会先做 preflight：

- pending database 必须存在；
- settings.json 如果存在，必须先完成 JSON / portable value 校验；
- 敏感 key 会在 staging 时过滤，不保留到 pending settings；
- preflight 失败时不覆盖当前数据库和业务目录，并清理无效 pending；
- 真正 Apply 全部完成以后才删除 pending 标记。

## 13. Schema / Migration 测试

数据库当前 Schema Version：

~~~text
v6
~~~

自动化测试现在覆盖：

~~~text
Fresh DB → v6

v1 → v6
v2 → v6
v3 → v6
v4 → v6
v5 → v6
~~~

Migration 不只检查版本号，还检查：

- 旧 Workspace / Task 数据保留。
- 对应旧版本已经存在的 Issue / Focus / Knowledge / AI Thread 数据保留。
- 当前最新表全部存在。
- Current Task 唯一索引仍然生效。
- Developer Primary 唯一索引仍然生效。
- FTS search_index 可以正常写入和查询。

测试使用文件型同进程 SQLite：先创建旧版本文件，关闭后再按最新 Schema 重新打开，让真实 Migration 路径执行。

正式应用继续使用 background database + WAL，测试入口不会替换正式运行方式。

以后只要 Schema Version 增加：

1. 新增对应 Schema 版本。
2. 补旧版本到最新版本的 Migration Test。
3. 补数据保留断言。
4. 补新增表 / 索引 / 约束断言。
5. 再允许合并。

## 14. 数据一致性原则

- Markdown 写入使用 atomic strategy。
- SQLite 使用 WAL。
- foreign_keys = ON。
- busy_timeout = 5000。
- Restore 不在 DB 已打开时直接覆盖。
- Search Index 允许重建。
