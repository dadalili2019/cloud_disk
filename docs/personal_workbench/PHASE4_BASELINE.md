# Personal Workbench Phase 4 基线

## 1. 阶段结论

Phase 4 已完成，并经过 Windows 实际运行、搜索验证、重启恢复和 Phase 1–3 smoke regression。

本阶段目标是把 Personal Workbench 从“工作对象管理”推进到：

> 工作过程可以沉淀为可复用知识，并能够跨实体统一检索。

最终形成：

```text
Knowledge + Search
├─ Knowledge Library
├─ Manual Knowledge
├─ Workspace → Knowledge Distill
├─ Source Context
├─ Global Search
│  ├─ Task
│  ├─ Note
│  ├─ Issue
│  ├─ Resource
│  ├─ Decision
│  └─ Knowledge
└─ Search Result Routing
```

---

## 2. Knowledge Library

Phase 4 新增独立的 Knowledge Library。

Knowledge 主要字段：

```text
id
title
category
summary
use_when
file_path
is_pinned
created_at
updated_at
archived_at
```

页面支持：

```text
新建知识
编辑知识
分类筛选
置顶
Markdown 正文
```

Knowledge 元数据保存在 SQLite，正文继续遵循 Personal Workbench 的本地文件策略，以 Markdown 文件保存。

目录结构：

```text
PersonalWorkbench/
├─ data/
│  └─ workbench.db
├─ workspaces/
└─ knowledge/
   └─ *.md
```

---

## 3. Workspace → Knowledge 沉淀

Knowledge 不只是一个独立笔记库。

Phase 4 正式建立：

```text
Workspace Entity
      ↓
Distill
      ↓
Knowledge
```

可作为来源的实体：

```text
Task
Note
Issue
Resource
Decision
```

入口统一放在：

```text
知识与搜索
→ 从工作区沉淀
```

没有在 Task / Note / Issue / Resource / Decision 五个页面分别增加大量按钮，避免破坏 Workspace 的操作密度。

沉淀流程：

```text
选择 Workspace
→ 选择来源实体
→ 系统根据来源生成可编辑草稿
→ 用户整理标题 / 分类 / Summary / Use When / Markdown
→ 沉淀为 Knowledge
```

当前只是确定性草稿生成，不做 AI 自动总结。

---

## 4. Source Context / derived_from

从 Workspace 沉淀出来的 Knowledge 会通过统一 Entity Link 保存来源关系：

```text
Knowledge --derived_from--> Task
Knowledge --derived_from--> Note
Knowledge --derived_from--> Issue
Knowledge --derived_from--> Resource
Knowledge --derived_from--> Decision
```

重新打开 Knowledge 时，会读取关系并展示 Source Context。

实际验证示例：

```text
Source Context
任务 · 12323213
```

手工新建、没有来源的 Knowledge 不展示 Source Context。

Source Context 不是复制出来的一段说明文字，而是根据真实 Entity Link 关系动态恢复。

---

## 5. Knowledge 与 Task Context

Phase 4 将 Knowledge 正式接入现有 `TaskContextService`。

Task Context 从：

```text
Task
├─ Notes
├─ Issues
├─ Resources
└─ Decisions
```

扩展为：

```text
Task
├─ Notes
├─ Issues
├─ Resources
├─ Decisions
└─ Knowledge
```

Knowledge 与 Task 的适用关系使用：

```text
Knowledge --applies_to--> Task
```

这使后续 AI Context Builder 可以直接复用 Task Context，不需要重新设计 Knowledge 关系层。

---

## 6. Global Search

Phase 4 新增统一搜索入口。

搜索范围：

```text
Task
Note
Issue
Resource
Decision
Knowledge
```

所有实体通过统一 Search Index 检索，而不是每个页面各写一套搜索逻辑。

搜索结果统一包含：

```text
entity_type
entity_id
workspace_id
title
snippet
score
```

---

## 7. 搜索实现基线

数据库 schema v4 新增 SQLite FTS5 虚拟表：

```text
search_index
```

主要索引字段：

```text
entity_type
entity_id
workspace_id
title
body
```

检索策略不是只使用 FTS5。

Phase 4 最终采用：

```text
FTS5 + BM25
      +
LIKE substring supplement
      ↓
merge + deduplicate
```

原因：FTS5 更适合 token 级全文检索，但对于：

```text
query: 123
value: 12323213
```

这种部分匹配，单纯 FTS5 可能漏掉结果。

因此 LIKE 始终作为部分匹配补充，而不是只在 FTS5 完全无结果时才执行。

实际验证：

```text
搜索 123
```

可以同时命中不同实体，例如：

```text
Knowledge: 123
Decision: 123
Resource: 123213
Task: 12323213
Knowledge: 12323213
```

---

## 8. Search Index 定位

`search_index` 只是派生数据，不是业务真实数据源。

真实数据仍然来自：

```text
SQLite domain tables
+
Markdown files
+
entity_links
```

因此索引可以随时重建。

页面提供：

```text
重建索引
```

启动 / 进入 Knowledge + Search 时也可以重新构建索引。

设计原则：

```text
业务数据丢失 ≠ 搜索索引丢失
搜索索引可删除、可重建
```

---

## 9. 搜索结果跳转

搜索不是只展示文本结果。

点击结果后根据实体类型执行：

```text
Knowledge
→ 打开 Knowledge 编辑器

Task
→ Workspace / Tasks

Note
→ Workspace / Notes

Issue
→ Workspace / Issues

Resource
→ Workspace / Resources

Decision
→ Workspace / Decisions
```

已实际验证搜索 Task 后可以正确进入对应 Workspace 的 Task 页面。

---

## 10. 数据库基线

Phase 4 schemaVersion：

```text
4
```

迁移：

```text
3 → 4
```

新增：

```text
knowledge
search_index (FTS5 virtual table)
```

Phase 1–3 原有数据不删除。

完整核心数据模型现在包括：

```text
workspaces
tasks
notes
issues
resources
decisions
focus_sessions
knowledge
entity_links
activity_events
search_index
```

---

## 11. Application 层基线

Phase 4 新增主要服务：

```text
KnowledgeService
KnowledgeDistillService
SearchService
```

主要职责：

### KnowledgeService

```text
Knowledge CRUD
Markdown read/write
Source relation creation
Task applicability relation
Knowledge index update
```

### KnowledgeDistillService

```text
Workspace source discovery
Source → editable draft
Source Context resolve
Distill Knowledge
```

### SearchService

```text
Search index rebuild
Cross-entity indexing
Global query
```

---

## 12. 页面基线

一级菜单正式增加：

```text
知识与搜索
```

原有旧模块保留并明确命名为：

```text
RAG 知识库
```

两者定位不同：

```text
知识与搜索
= Personal Workbench 内部工作知识与跨实体搜索

RAG 知识库
= 原应用已有 RAG 功能
```

不将两套概念混为一个功能。

---

## 13. 已实际验证的关键链路

### 手工 Knowledge

```text
新建知识
→ SQLite 保存 metadata
→ Markdown 保存正文
→ Knowledge Library 展示
→ 再次打开编辑
```

### Workspace Distill

```text
Workspace
→ Task / Note / Resource / Decision 等来源
→ 自动生成草稿
→ 用户整理
→ Knowledge
→ derived_from
→ Source Context
```

### Search

```text
Workspaces + Knowledge
→ rebuild search_index
→ FTS5 + LIKE
→ merge / deduplicate
→ search result
→ open target
```

### Restart Recovery

```text
完全退出 Windows App
→ 重新启动
→ Knowledge 恢复
→ Markdown 恢复
→ Source Context 恢复
→ Search Index 重建
→ Search 正常
```

---

## 14. Phase 1–3 回归结果

Phase 4 完成后进行了快速 smoke regression。

确认正常：

```text
Home
Continue
Quick Capture
Focus / Today Timeline
Workspace Overview
Task
Note
Issue
Resource
Decision
```

Phase 4 没有重写上述模块核心逻辑。

---

## 15. Phase 4 明确不做

本阶段不引入：

```text
Embedding
Vector Database
Semantic Search
AI 自动总结
AI 自动分类
AI 自动生成 Knowledge
自动知识去重
Knowledge Versioning
Cloud Sync
多人协作
```

当前搜索保持本地、确定性和可重建。

---

## 16. Phase 4 封版状态

```text
[✓] Schema v4 Migration
[✓] Knowledge CRUD
[✓] Markdown Knowledge Storage
[✓] Knowledge Category / Pin
[✓] Workspace → Knowledge Distill
[✓] derived_from / Source Context
[✓] Task Context Knowledge
[✓] FTS5 Search Index
[✓] BM25 Ranking
[✓] LIKE Partial Match Supplement
[✓] Cross-entity Global Search
[✓] Search Result Routing
[✓] Index Rebuild
[✓] Windows Restart Recovery
[✓] Phase 1–3 Smoke Regression
```

Phase 4 正式封版。

后续阶段不再向 Phase 4 追加功能；新的智能能力、语义检索或 AI Context 能力应作为后续 Phase 独立演进。
